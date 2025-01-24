import os
import cv2
import numpy as np
from collections import deque
import time
import csv

# Global thresholds
threshold_ratiotoradius = 0.1
threshold_black = 50
threshold_boxblack = 6
threshold_time = 0.25
min_contour_area = 1000
min_darker_area = 800

# Fast forwarding factor
skip_factor = 1  # process every n-th frame

# Paths
video_path = "C:\\Users\\chanh\\Downloads\\Video_ChAT\\ChAT_925-2_24-07-18-13-56-02_OF.mp4"
output_path = "C:\\Users\\chanh\\Downloads\\Video_ChAT\\output_video.mp4"
csv_output_path = "C:\\Users\\chanh\\Downloads\\Video_ChAT\\output_data.csv"

# Video capture and properties
cap = cv2.VideoCapture(video_path)
if not cap.isOpened():
    print("Error: Could not open video.")
    exit()

fps = 200 #cap.get(cv2.CAP_PROP_FPS) or 30
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

fourcc = cv2.VideoWriter_fourcc(*'mp4v')
out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

points = []
selected_circle = None
movement_data = deque(maxlen=100)
movement_threshold = None
previous_darker_areas = deque(maxlen=10)

def calculate_circle(pts):
    x1, y1 = pts[0]
    x2, y2 = pts[1]
    x3, y3 = pts[2]
    det = (x1 - x2) * (y2 - y3) - (x2 - x3) * (y1 - y2)
    if abs(det) < 1e-10:
        print("Error: Points are collinear.")
        return None
    A = (x1 ** 2 + y1 ** 2)
    B = (x2 ** 2 + y2 ** 2)
    C = (x3 ** 2 + y3 ** 2)
    xc = ((A * (y2 - y3)) + (B * (y3 - y1)) + (C * (y1 - y2))) / (2 * det)
    yc = ((A * (x3 - x2)) + (B * (x1 - x3)) + (C * (x2 - x1))) / (2 * det)
    radius = np.sqrt((xc - x1) ** 2 + (yc - y1) ** 2)
    return (int(xc), int(yc)), int(radius)

def apply_circle_mask(frame, center, radius):
    mask = np.zeros(frame.shape[:2], dtype=np.uint8)
    cv2.circle(mask, center, radius, 255, -1)
    return cv2.bitwise_and(frame, frame, mask=mask)

def apply_circle_mask_to_bbox(bbox_region, center, radius, bbox_offset):
    mask = np.zeros(bbox_region.shape[:2], dtype=np.uint8)
    offset_center = (center[0] - bbox_offset[0], center[1] - bbox_offset[1])
    cv2.circle(mask, offset_center, radius, 255, -1)
    return cv2.bitwise_and(bbox_region, bbox_region, mask=mask)

def mouse_callback(event, x, y, flags, param):
    global points, selected_circle, movement_threshold
    if event == cv2.EVENT_LBUTTONDOWN:
        points.append((x, y))
        if len(points) == 3:
            selected_circle = calculate_circle(points)
            if selected_circle:
                center, radius = selected_circle
                movement_threshold = threshold_ratiotoradius * radius
                print(f"Circle Center: {center}, Radius: {radius}, Threshold: {movement_threshold}")
            points = []

ret, first_frame = cap.read()
if not ret:
    print("Error: Could not read the video.")
    exit()

cv2.namedWindow("Define ROI")
cv2.setMouseCallback("Define ROI", mouse_callback)

while True:
    frame_copy = first_frame.copy()
    for point in points:
        cv2.circle(frame_copy, point, 5, (0, 255, 0), -1)
    if selected_circle:
        center, radius = selected_circle
        cv2.circle(frame_copy, center, radius, (255, 0, 0), 2)
    cv2.imshow("Define ROI", frame_copy)
    if cv2.waitKey(1) & 0xFF == ord('q') or selected_circle:
        break

cv2.destroyWindow("Define ROI")

kalman = cv2.KalmanFilter(4, 2)  # state: x, y, vx, vy; measurement: x, y
kalman.transitionMatrix = np.array([[1,0,1,0],
                                    [0,1,0,1],
                                    [0,0,1,0],
                                    [0,0,0,1]], np.float32)
kalman.measurementMatrix = np.array([[1,0,0,0],
                                     [0,1,0,0]], dtype=np.float32)
# Tune these to make predictions less exaggerated
kalman.processNoiseCov = np.eye(4, dtype=np.float32) * 0.001
kalman.measurementNoiseCov = np.eye(2, dtype=np.float32) * 0.005
kalman.errorCovPost = np.eye(4, dtype=np.float32)

initialized_kalman = False
pred_x, pred_y = None, None

frame_count = 0

# List to store (frame_number, MOVE) data
movement_records = []

while True:
    ret, frame = cap.read()
    if not ret:
        break

    frame_count += 1
    # Skip frames to fast forward
    if frame_count % skip_factor != 0:
        continue

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    if selected_circle:
        center, radius = selected_circle
        gray = apply_circle_mask(gray, center, radius)

    if initialized_kalman:
        prediction = kalman.predict()
        pred_x, pred_y = int(prediction[0, 0]), int(prediction[1, 0])
    else:
        pred_x, pred_y = None, None

    _, black_mask = cv2.threshold(gray, threshold_black, 255, cv2.THRESH_BINARY_INV)
    if selected_circle:
        black_mask = apply_circle_mask(black_mask, center, radius)

    contours, _ = cv2.findContours(black_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    largest_contour = None
    largest_area = 0

    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area > min_contour_area and area > largest_area:
            largest_area = area
            largest_contour = cnt

    darker_cx, darker_cy = None, None
    chosen_darker_area = None

    if largest_contour is not None:
        x, y, w, h = cv2.boundingRect(largest_contour)
        cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)

        bbox_region = gray[y:y+h, x:x+w]
        if selected_circle:
            bbox_region = apply_circle_mask_to_bbox(bbox_region, center, radius, (x, y))

        _, darker_pixels_mask = cv2.threshold(bbox_region, threshold_boxblack, 255, cv2.THRESH_BINARY_INV)
        if selected_circle:
            darker_pixels_mask = apply_circle_mask_to_bbox(darker_pixels_mask, center, radius, (x, y))

        darker_contours, _ = cv2.findContours(darker_pixels_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        if previous_darker_areas:
            target_darker_area = np.mean(previous_darker_areas)
            similarity_threshold = 0.5 * target_darker_area if target_darker_area > 0 else float('inf')
        else:
            target_darker_area = None
            similarity_threshold = float('inf')

        chosen_darker_contour = None
        min_area_diff = float('inf')

        for cnt in darker_contours:
            area = cv2.contourArea(cnt)
            if area < min_darker_area:
                continue
            perimeter = cv2.arcLength(cnt, True)
            if perimeter == 0:
                continue
            circularity = (4 * np.pi * area) / (perimeter * perimeter)
            if circularity < 0.4:
                continue

            if target_darker_area is not None:
                area_diff = abs(area - target_darker_area)
            else:
                area_diff = -area

            if area_diff < min_area_diff:
                min_area_diff = area_diff
                chosen_darker_contour = cnt
                chosen_darker_area = area

        if chosen_darker_contour is not None and previous_darker_areas and min_area_diff > similarity_threshold:
            chosen_darker_contour = None
            chosen_darker_area = None

        if chosen_darker_contour is not None:
            previous_darker_areas.append(chosen_darker_area)
            moments = cv2.moments(chosen_darker_contour)
            if moments['m00'] > 0:
                darker_cx = int(moments['m10'] / moments['m00']) + x
                darker_cy = int(moments['m01'] / moments['m00']) + y

                if (darker_cx - center[0])**2 + (darker_cy - center[1])**2 <= radius**2:
                    measurement = np.array([[np.float32(darker_cx)],
                                            [np.float32(darker_cy)]], dtype=np.float32)
                    if not initialized_kalman:
                        kalman.statePost = np.array([[darker_cx],
                                                     [darker_cy],
                                                     [0],
                                                     [0]], dtype=np.float32)
                        initialized_kalman = True
                        prediction = kalman.predict()
                        pred_x, pred_y = int(prediction[0, 0]), int(prediction[1, 0])

                    kalman.correct(measurement)
                    # Re-predict after correction
                    prediction = kalman.predict()
                    pred_x, pred_y = int(prediction[0, 0]), int(prediction[1, 0])

                    cv2.drawContours(frame, [chosen_darker_contour + (x, y)], -1, (0, 255, 255), thickness=cv2.FILLED)

    # Update movement data
    if initialized_kalman and pred_x is not None and pred_y is not None:
        current_time = time.time()
        movement_data.append((current_time, (pred_x, pred_y)))
        while movement_data and (current_time - movement_data[0][0]) > threshold_time:
            movement_data.popleft()

        total_movement = 0
        for i in range(1, len(movement_data)):
            p1 = movement_data[i - 1][1]
            p2 = movement_data[i][1]
            total_movement += np.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)

        state = "Move" if total_movement > movement_threshold else "Stop"
        move_val = 1 if state == "Move" else 0

        # Log frame number and move state to the list
        movement_records.append([frame_count, move_val])

        text_color = (0, 255, 0) if state == "Move" else (0, 0, 255)
        cv2.putText(frame, f"State: {state}", (10, 50), cv2.FONT_HERSHEY_SIMPLEX, 2, text_color, 2)

        if largest_area > 0:
            cv2.putText(frame, f"Outer Contour Area: {largest_area}", (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255,255,0), 2)
        else:
            cv2.putText(frame, "No Valid Contour", (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,0,255), 2)

        if chosen_darker_area is not None:
            cv2.putText(frame, f"Darker Area: {chosen_darker_area}", (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255,255,0), 2)
        else:
            cv2.putText(frame, "Darker Area: N/A", (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,0,255), 2)

        if selected_circle:
            cv2.circle(frame, center, radius, (255, 0, 0), 2)

        # Draw red centroid heavier (increase radius)
        if pred_x is not None and pred_y is not None:
            cv2.circle(frame, (pred_x, pred_y), 2, (0, 0, 255), -1)
    else:
        cv2.putText(frame, "No Valid Contour", (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,0,255), 2)

    out.write(frame)
    # Comment out imshow for faster processing
    cv2.imshow("Mouse Movement Detection", frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
out.release()
cv2.destroyAllWindows()

# Save to CSV
with open(csv_output_path, mode='w', newline='') as csvfile:
    csv_writer = csv.writer(csvfile)
    csv_writer.writerow(["Frame", "MOVE"])
    csv_writer.writerows(movement_records)
