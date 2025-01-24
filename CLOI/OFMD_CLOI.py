import os
import cv2
import numpy as np
import matplotlib.pyplot as plt
from collections import deque
import time
import csv
import board
import digitalio
from datetime import datetime

# Global thresholds
thres_movement = 0.1 # 0-0.2
thres_black = 50 # 0-100
thres_blacker = 6 # 0-50, smaller than thres_black
thres_time = 0.1 # seconds
thres_contour = 1000 # px x px
thres_darker = 800 # px x px

# Full file paths
video_path = "C:\\Users\\chanh\\Downloads\\Video_ChAT\\ChAT_925-2_24-07-18-13-56-02_OF.mp4"
output_path = "C:\\Users\\chanh\\Downloads\\Video_ChAT\\output_video.mp4"

# Create the log directory if it does not exist
log_dir = "./Log"
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

# Video capture object and get properties
cap = cv2.VideoCapture(video_path)
if not cap.isOpened():
    print("Error: Could not open video.")
    exit()
fps = cap.get(cv2.CAP_PROP_FPS) or 30
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

# Video writer object
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

# Initialize variables
points = []
movement_records = []
selected_circle = None
movement_data = deque(maxlen=100)  # store last 100 movement states
movement_threshold = None
previous_darker_areas = deque(maxlen=10)  # store last 10 darker areas
centroid_trace = deque(maxlen=200)  # store last 200 centroid points

## Dynamic Thresholding ##

# Function to update thresholds
def update_thresholds(x):
    global thres_movement, thres_black, thres_blacker, thres_time, thres_contour, thres_darker
    thres_movement = cv2.getTrackbarPos('Movement', 'Thresholds') / 100.0
    thres_black = cv2.getTrackbarPos('Black', 'Thresholds')
    thres_blacker = cv2.getTrackbarPos('Blacker', 'Thresholds')
    thres_time = cv2.getTrackbarPos('TimeThres', 'Thresholds') / 100.0
    thres_contour = cv2.getTrackbarPos('MinCont', 'Thresholds')
    thres_darker = cv2.getTrackbarPos('MinDark', 'Thresholds')

# Create dynamic threshold trackbars
cv2.namedWindow('Thresholds', flags=cv2.WINDOW_NORMAL)
cv2.resizeWindow('Thresholds', 600, 250)
cv2.createTrackbar('Movement', 'Thresholds', int(thres_movement * 100), 20, update_thresholds)
cv2.createTrackbar('Black', 'Thresholds', thres_black, 100, update_thresholds)
cv2.createTrackbar('Blacker', 'Thresholds', thres_blacker, 50, update_thresholds)
cv2.createTrackbar('TimeThres', 'Thresholds', int(thres_time * 100), 100, update_thresholds)
cv2.createTrackbar('MinCont', 'Thresholds', thres_contour, 5000, update_thresholds)
cv2.createTrackbar('MinDark', 'Thresholds', thres_darker, 5000, update_thresholds)

## Read first frame ##

ret, first_frame = cap.read()
if not ret:
    print("Error: Could not read the video.")
    exit()

## Specify and draw circle ##

# Function to calculate circle from 3 points
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

# Function to apply circular mask
def apply_circle_mask(frame, center, radius):
    mask = np.zeros(frame.shape[:2], dtype=np.uint8)
    cv2.circle(mask, center, radius, 255, -1)
    return cv2.bitwise_and(frame, frame, mask=mask)

# Function to mouse callback in clicking 3 points
def mouse_callback(event, x, y, flags, param):
    global points, selected_circle, movement_threshold
    if event == cv2.EVENT_LBUTTONDOWN:
        points.append((x, y))
        if len(points) == 3:
            selected_circle = calculate_circle(points)
            if selected_circle:
                center, radius = selected_circle
                movement_threshold = thres_movement * radius
                print(f"Circle Center: {center}, Radius: {radius}, Threshold: {movement_threshold}")
            points = []

# Function to apply circular mask to bounding box region
def apply_circle_mask_to_bbox(bbox_region, center, radius, bbox_offset):
    mask = np.zeros(bbox_region.shape[:2], dtype=np.uint8)
    offset_center = (center[0] - bbox_offset[0], center[1] - bbox_offset[1])
    cv2.circle(mask, offset_center, radius, 255, -1)
    return cv2.bitwise_and(bbox_region, bbox_region, mask=mask)

## Define ROI - circular ROI selection ##

cv2.namedWindow("Define ROI")
cv2.resizeWindow("Define ROI", width, height)
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

## Kalman Filter Initialization ##

kalman = cv2.KalmanFilter(4, 2)  # state: x, y, vx, vy; measurement: x, y
kalman.transitionMatrix = np.array([[1,0,1,0],
                                    [0,1,0,1],
                                    [0,0,1,0],
                                    [0,0,0,1]], np.float32)
kalman.measurementMatrix = np.array([[1,0,0,0],
                                     [0,1,0,0]], dtype=np.float32)
# Tune these to make predictions less exaggerated
kalman.processNoiseCov = np.eye(4, dtype=np.float32) * 0.0001
kalman.measurementNoiseCov = np.eye(2, dtype=np.float32) * 0.0005
kalman.errorCovPost = np.eye(4, dtype=np.float32)

initialized_kalman = False
pred_x, pred_y = None, None

# Initialize movement state tracking
# movement_states = deque(maxlen=3000)  # Track the last 3000 frames
# fig, ax = plt.subplots()
# plt.ion()  # Enable interactive mode

laser = digitalio.DigitalInOut(board.C0)
laser.direction = digitalio.Direction.OUTPUT
laser_log_data = [[0, 'OFF']]
laser_ON_last = None
laser_OFF_last = None

# Function to perform a blinking session
def blink_session(on_time, off_time):
    global laser, laser_log_data, laser_ON_last, laser_OFF_last
    current_time = time.time()
    # Check if the laser was not turned OFF within the last 1.0 seconds -> Turn ON
    if (laser_OFF_last is None and laser_ON_last is None) or (laser_OFF_last is not None and (current_time - laser_OFF_last) > 1.0):
        laser.value = True
        print("Laser ON")
        laser_ON_last = current_time
        laser_log_data.append([datetime.now().strftime('%y-%m-%d_%H-%M-%S-%f'), 'ON'])
        return
    # Check if the laser was turned ON within the last 0.5 seconds -> Keep it ON
    elif (current_time - laser_ON_last) <= 0.5:
        return
    # Check if the laser was turned ON during the last 0.5-1.5 seconds -> Turn OFF
    elif (current_time - laser_ON_last) > 0.5 and (current_time - laser_ON_last) <= 1.5:
        laser.value = False
        print("Laser OFF")
        laser_OFF_last = current_time
        laser_log_data.append([datetime.now().strftime('%y-%m-%d_%H-%M-%S-%f'), 'OFF'])
    return laser_log_data

# Manually set the parameters for the session
on_time = 0.5  # Set the ON time (in seconds)
off_time = 1.0  # Set the OFF time (in seconds)
pulses = 1  # Set the number of pulses

# Generate the log file name with the current date and on_time
timestamp = datetime.now().strftime('%y%m%d')
log_movement = os.path.join(log_dir, f"log_movement_{timestamp}_{on_time}.csv")
log_laser = os.path.join(log_dir, f"log_laser_{timestamp}_{on_time}.csv")

## Main Loop ##

cv2.namedWindow("Black Mask", cv2.WINDOW_NORMAL)
cv2.resizeWindow("Black Mask", round(width/2), round(height/2))
cv2.namedWindow("BBox Region", cv2.WINDOW_NORMAL)
cv2.resizeWindow("BBox Region", round(width/2), round(height/2))

frame_count = 0

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    frame_count += 1

    # Convert to grayscale image
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Apply circular mask for every frame
    if selected_circle:
        center, radius = selected_circle
        gray = apply_circle_mask(gray, center, radius)

    # Apply Kalman Filter to predict centroid
    if initialized_kalman:
        prediction = kalman.predict()
        pred_x, pred_y = int(prediction[0, 0]), int(prediction[1, 0])
    else:
        pred_x, pred_y = None, None

    # Thresholding grayscale image by 'thres_black'
    _, black_mask = cv2.threshold(gray, thres_black, 255, cv2.THRESH_BINARY_INV)
    # Apply circular mask to black_mask
    if selected_circle:
        black_mask = apply_circle_mask(black_mask, center, radius)

    # Find largest contour and its area
    contours, _ = cv2.findContours(black_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    largest_contour = None
    largest_area = 0
    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area > thres_contour and area > largest_area:
            largest_area = area
            largest_contour = cnt

    # Find darker area within the bounding box of the largest contour
    darker_cx, darker_cy = None, None
    chosen_darker_area = None
    bbox_region_display = None

    if largest_contour is not None:
        x, y, w, h = cv2.boundingRect(largest_contour)
        
        # Draw largest contour on black_mask for visualization (green)
        black_mask_contour_vis = cv2.cvtColor(black_mask, cv2.COLOR_GRAY2BGR)
        cv2.drawContours(black_mask_contour_vis, [largest_contour], -1, (0, 255, 0), 2)

        # Apply circular mask to bounding box region
        bbox_region = gray[y:y+h, x:x+w]
        if selected_circle:
            bbox_region = apply_circle_mask_to_bbox(bbox_region, center, radius, (x, y))

        # Thresholding bbox_region by 'thres
        #_blacker'
        _, darker_pixels_mask = cv2.threshold(bbox_region, thres_blacker, 255, cv2.THRESH_BINARY_INV)
        # Apply circular mask to darker_pixels_mask
        if selected_circle:
            darker_pixels_mask = apply_circle_mask_to_bbox(darker_pixels_mask, center, radius, (x, y))
        # Find contours in darker_pixels_mask
        darker_contours, _ = cv2.findContours(darker_pixels_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        # Calculate similarity threshold based on previous darker areas
        if previous_darker_areas:
            target_darker_area = np.mean(previous_darker_areas)
            similarity_threshold = 0.5 * target_darker_area if target_darker_area > 0 else float('inf')
        else:
            target_darker_area = None
            similarity_threshold = float('inf')

        # Choose the darker contour with the closest area to the target darker area
        chosen_darker_contour = None
        min_area_diff = float('inf')
        for cnt in darker_contours:
            area = cv2.contourArea(cnt)
            if area < thres_darker:
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

        # Update previous darker areas and Kalman Filter
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

        # Prepare bbox_region display
        bbox_region_display = cv2.cvtColor(black_mask, cv2.COLOR_GRAY2BGR)
        if chosen_darker_contour is not None:
            # Draw chosen darker contour in the bbox region space
            cv2.drawContours(bbox_region_display, [(x, y) + chosen_darker_contour], -1, (0, 0, 255), cv2.FILLED)
        if bbox_region is not None:
            # Draw bounding box in the original frame space
            cv2.rectangle(bbox_region_display, (x, y), (x+w, y+h), (0, 255, 0), 2)

    ## Update movement data ##

    if initialized_kalman and pred_x is not None and pred_y is not None:
        current_time = time.time()
        movement_data.append((current_time, (pred_x, pred_y)))
        while movement_data and (current_time - movement_data[0][0]) > thres_time:
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
        # movement_states.append(move_val)
        # If movement detected, perform the session
        if move_val:
            blink_session(on_time, off_time)

        text_color = (0, 255, 0) if state == "Move" else (0, 0, 255)
        cv2.putText(frame, f"State: {state}", (10, 50), cv2.FONT_HERSHEY_SIMPLEX, 2, text_color, 2)

        # Update plot - becomes too laggy
        # ax.clear()
        # ax.plot(movement_states)
        # ax.set_ylim(-0.1, 1.1)
        # plt.draw()
        # plt.pause(0.001)

        if largest_area > 0:
            cv2.putText(frame, f"Outer Contour Area: {largest_area}", (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255,255,0), 2)
        else:
            cv2.putText(frame, "No Valid Contour", (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,0,255), 2)

        if chosen_darker_area is not None:
            cv2.putText(frame, f"Darker Area: {chosen_darker_area}", (10, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255,255,0), 2)
        else:
            cv2.putText(frame, "Darker Area: N/A", (10, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,0,255), 2)

        if selected_circle:
            cv2.circle(frame, center, radius, (255, 0, 0), 2)

        # Draw the predicted centroid
        if pred_x is not None and pred_y is not None:
            cv2.circle(frame, (pred_x, pred_y), 2, (0, 0, 255), -1)
            centroid_trace.append((pred_x, pred_y))
            # Draw centroid trace
            for i in range(1, len(centroid_trace)):
                cv2.line(frame, centroid_trace[i-1], centroid_trace[i], (255, 255, 0), 1)

    else:
        cv2.putText(frame, "No Valid Contour", (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,0,255), 2)

    out.write(frame)

    ## Show intermediate images ##
    if largest_contour is not None:
        # If we drew it above
        cv2.imshow("Black Mask", black_mask_contour_vis)
    else:
        cv2.imshow("Black Mask", cv2.cvtColor(black_mask, cv2.COLOR_GRAY2BGR))

    if bbox_region_display is not None:
        cv2.imshow("BBox Region", bbox_region_display)
    else:
        blank = np.zeros((100,100,3), dtype=np.uint8)
        cv2.putText(blank, "N/A", (10,50), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,0,255),2)
        cv2.imshow("BBox Region", blank)

    cv2.namedWindow("Mouse Movement Detection", cv2.WINDOW_NORMAL)
    cv2.resizeWindow("Mouse Movement Detection", width, height)
    cv2.imshow("Mouse Movement Detection", frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
out.release()
cv2.destroyAllWindows()

## Save to CSV ##

# Save the movement log data to a CSV file
with open(log_movement, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(["Frame", "MOVE"])
    writer.writerows(movement_records)

# Save the laser log data to a CSV file
with open(log_laser, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(["Timestamp", "State"])
    writer.writerows(laser_log_data)