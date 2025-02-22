import os
import cv2
import numpy as np
from collections import deque
import time

# Global thresholds
threshold_ratiotoradius = 0.05
threshold_black = 50
threshold_boxblack = 6
threshold_time = 0.1

# Paths
video_path = "C:\\Users\\chanh\\Downloads\\Video_ChAT\\ChAT_925-2_24-07-18-13-56-02_OF.mp4"
output_path = "C:\\Users\\chanh\\Downloads\\Video_ChAT\\output_video.mp4"

# Video capture and properties
cap = cv2.VideoCapture(video_path)
if not cap.isOpened():
    print("Error: Could not open video.")
    exit()

fps = cap.get(cv2.CAP_PROP_FPS) or 30
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

# Video writer
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

# Variables
points = []
selected_circle = None
previous_bbox = None
movement_data = deque(maxlen=100)
movement_threshold = None

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

# Define ROI
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

# Frame processing
while True:
    ret, frame = cap.read()
    if not ret:
        break

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    if selected_circle:
        center, radius = selected_circle
        gray = apply_circle_mask(gray, center, radius)

    _, black_mask = cv2.threshold(gray, threshold_black, 255, cv2.THRESH_BINARY_INV)
    if selected_circle:
        black_mask = apply_circle_mask(black_mask, center, radius)

    contours, _ = cv2.findContours(black_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    largest_contour = max(contours, key=cv2.contourArea, default=None)

    if largest_contour is not None and cv2.contourArea(largest_contour) > 500:
        x, y, w, h = cv2.boundingRect(largest_contour)
        previous_bbox = (x, y, w, h)
    elif previous_bbox is not None:
        x, y, w, h = previous_bbox
    else:
        continue

    # Crop the bounding box region
    bbox_region = gray[y:y+h, x:x+w]

    # Apply the circle mask to the bounding box
    if selected_circle:
        bbox_region = apply_circle_mask_to_bbox(bbox_region, center, radius, (x, y))

    # Threshold the pixels inside the bounding box for darker values
    _, darker_pixels_mask = cv2.threshold(bbox_region, threshold_boxblack, 255, cv2.THRESH_BINARY_INV)

    # Apply the circle mask again to the darker pixel mask
    if selected_circle:
        darker_pixels_mask = apply_circle_mask_to_bbox(darker_pixels_mask, center, radius, (x, y))

    # Find contours of the darker pixel group
    darker_contours, _ = cv2.findContours(darker_pixels_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Ensure the darker contours are fully within the ROI
    valid_contours = []
    for contour in darker_contours:
        mask = np.zeros_like(darker_pixels_mask)
        cv2.drawContours(mask, [contour], -1, 255, -1)
        roi_mask = apply_circle_mask_to_bbox(mask, center, radius, (x, y))
        if np.array_equal(mask, roi_mask):  # Include only contours fully inside the ROI
            valid_contours.append(contour)

    # Find the largest valid darker contour
    largest_darker_contour = max(valid_contours, key=cv2.contourArea, default=None)

    if largest_darker_contour is not None:
        moments = cv2.moments(largest_darker_contour)
        if moments['m00'] > 0:  # Avoid division by zero
            darker_cx = int(moments['m10'] / moments['m00']) + x
            darker_cy = int(moments['m01'] / moments['m00']) + y

            # Verify centroid is within ROI
            if (darker_cx - center[0])**2 + (darker_cy - center[1])**2 <= radius**2:
                cv2.drawContours(frame, [largest_darker_contour + (x, y)], -1, (0, 255, 255), thickness=cv2.FILLED)
                cv2.circle(frame, (darker_cx, darker_cy), 5, (0, 0, 255), -1)
                cv2.putText(frame, f"Centroid: ({darker_cx}, {darker_cy})", (10, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 255), 1)

    current_time = time.time()
    movement_data.append((current_time, (darker_cx, darker_cy)))

    while movement_data and (current_time - movement_data[0][0]) > threshold_time:
        movement_data.popleft()

    total_movement = 0
    for i in range(1, len(movement_data)):
        p1 = movement_data[i - 1][1]
        p2 = movement_data[i][1]
        total_movement += np.sqrt((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2)

    state = "Move" if total_movement > movement_threshold else "Stop"
    text_color = (0, 255, 0) if state == "Move" else (0, 0, 255)

    cv2.putText(frame, f"State: {state}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, text_color, 2)
    if selected_circle:
        cv2.circle(frame, center, radius, (255, 0, 0), 2)
    cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
    out.write(frame)
    cv2.imshow("Mouse Movement Detection", frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
out.release()
cv2.destroyAllWindows()
