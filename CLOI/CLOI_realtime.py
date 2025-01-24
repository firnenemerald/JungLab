## Real-time Open Field Motion Detection (OFMD) for Closed Loop Optogenetic Inhibition (CLOI)

## Import necessary libraries
import os
import cv2
import numpy as np
import digitalio
import board
import csv
from datetime import datetime

## File I/O
# Input video path
video_path = "C:\\Users\\chanh\\Downloads\\Video_ChAT\\ChAT_925-2_24-07-18-13-56-02_OF.mp4"  # Video file path
# Make a session directory ./YYMMDD_HHMMSS
session_dir = datetime.now().strftime("./%y%m%d_%H%M%S")
if not os.path.exists(session_dir):
    os.makedirs(session_dir)
# Output video path
output_path = session_dir + "/output_video.mp4"  # Output video path
# Make a log directory ./YYMMDD_HHMMSS/Log
log_dir = session_dir + "/Log"
if not os.path.exists(log_dir):
    os.makedirs(log_dir)
# Movement log file path
log_movement = log_dir + "/log_movement_" + datetime.now().strftime("./%y%m%d_%H%M%S") + ".csv"  # Log file path
# Laser log file path
log_laser = log_dir + "/log_laser_" + datetime.now().strftime("./%y%m%d_%H%M%S") + ".csv"  # Log file path

# Initialize video capture
cap = cv2.VideoCapture(video_path)
if not cap.isOpened():
    print("Error: Could not open video file.")
    exit()
fps = cap.get(cv2.CAP_PROP_FPS) or 30  # Use default FPS if not available
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

# Read the first frame
ret, first_frame = cap.read()
if not ret:
    print("Error: Could not read the video.")
    exit()

# Initialize video writer
fourcc = cv2.VideoWriter_fourcc(*'mp4v')  # Codec for MP4
out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

## Dynamic thresholding
# Initialize thresholds
thres_time = 0.1  # Time interval for movement evaluation (seconds)
thres_movement = 0.1  # Movement threshold (ratio relative to maze radius)
thres_dark_px = 50  # Black pixel threshold (0-100)
thres_darker_px = 10  # Darker pixel threshold (0-50)
thres_dark_area = 500  # Minimum dark contour area for mouse detection
thres_darker_area = 800  # Minimum darker area for mouse detection

# Initialize global variables
movement_threshold = 0.1  # Movement threshold (pixels)
selected_circle = ((0, 0), 100)  # Default circle

# Function to update thresholds
def update_thresholds(x):
    global thres_time, thres_movement, movement_threshold, thres_dark_px, thres_darker_px, thres_dark_area, thres_darker_area
    thres_time = cv2.getTrackbarPos("Time (ms)", "Thresholds") / 1000
    thres_movement = cv2.getTrackbarPos("Movement", "Thresholds") / 100
    movement_threshold = thres_movement * selected_circle[1]
    thres_dark_px = cv2.getTrackbarPos("Dark Px", "Thresholds")
    thres_darker_px = cv2.getTrackbarPos("Darkr Px", "Thresholds")
    thres_dark_area = cv2.getTrackbarPos("Dark Area", "Thresholds")
    thres_darker_area = cv2.getTrackbarPos("Darkr Area", "Thresholds")

# Trackbar window to update thresholds
cv2.namedWindow("Thresholds", flags=cv2.WINDOW_NORMAL)
cv2.resizeWindow("Thresholds", 640, 240)
cv2.createTrackbar("Time (ms)", "Thresholds", int(thres_time * 1000), 1000, update_thresholds)
cv2.createTrackbar("Movement", "Thresholds", int(thres_movement * 100), 100, update_thresholds)
cv2.createTrackbar("Dark Px", "Thresholds", thres_dark_px, 100, update_thresholds)
cv2.createTrackbar("Darkr Px", "Thresholds", thres_darker_px, 50, update_thresholds)
cv2.createTrackbar("Dark Area", "Thresholds", thres_dark_area, 1000, update_thresholds)
cv2.createTrackbar("Darkr Area", "Thresholds", thres_darker_area, 1000, update_thresholds)

## Draw ROI circle
# Function to calculate a circle passing through three points
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

# Mouse callback after ROI selection
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

# Display the first frame for ROI selection
cv2.namedWindow("Define ROI")
cv2.resizeWindow("Define ROI", width, height)
cv2.setMouseCallback("Define ROI", mouse_callback)

# Loop to select ROI circle
points = []  # Initialize points for ROI selection
while True:
    frame_copy = first_frame.copy()
    for point in points:
        cv2.circle(frame_copy, point, 5, (0, 255, 0), -1)
    if selected_circle:
        center, radius = selected_circle
        cv2.circle(frame_copy, center, radius, (255, 0, 0), 2)
    cv2.imshow("Define ROI", frame_copy)
    if cv2.waitKey(1) & 0xFF == ord('q') or selected_circle[0] != (0, 0):
        break
cv2.destroyWindow("Define ROI")

# Function to apply circular mask to box region
def apply_circle_mask_to_box(box_region, center, radius, box_offset):
    mask = np.zeros(box_region.shape[:2], dtype=np.uint8)
    offset_center = (center[0] - box_offset[0], center[1] - box_offset[1])
    cv2.circle(mask, offset_center, radius, 255, -1)
    return cv2.bitwise_and(box_region, box_region, mask=mask)

## Adafruit breakout board setup
# Laser control and initialization
laser = digitalio.DigitalInOut(board.C0)
laser.direction = digitalio.Direction.OUTPUT
laser_status = "OFF"  # Initialize laser status
laser_data = [[datetime.now(), "OFF"]] # Initialize laser data
laser_ON_last = None # Initialize last laser ON time
laset_OFF_last = datetime.now() # Initialize last laser OFF time

# Function to turn the laser ON for X seconds and OFF for Y seconds
X = 0.5  # Laser ON time (seconds)
Y = 1.0  # Laser OFF time (seconds)
def control_laser(status):
    global laser, laser_status, laser_data, laser_ON_last, laser_OFF_last
    current_time = datetime.now()
    if status == "Move" and laser_ON_last is None: # First time turning the laser ON
        laser.value = True
        laser_status = "ON"
        laser_ON_last = current_time
        laser_data.append([current_time, laser_status])
        return
    elif (current_time - laser_ON_last).total_seconds() < X: # Keep the laser ON for X seconds
        if laser_status == "OFF":
            laser.value = True
            laser_status = "ON"
            return
        else:
            laser_status = "ON for "+ X +" seconds"
            return
    elif (current_time - laser_ON_last).total_seconds() > X & (current_time - laser_ON_last).total_seconds() < X+Y: # Turn laser OFF after X seconds for Y seconds
        if laser_status == "ON":
            laser.value = False
            laser_status = "OFF"
            laser_OFF_last = current_time
            laser_data.append([current_time, laser_status])
            return
        else:
            laser_status = "OFF for "+ Y +" seconds"
            return
    elif status == "Move" and (current_time - laser_ON_last).total_seconds() > X+Y:
        laser.value = True
        laser_status = "ON"
        laser_ON_last = current_time
        laser_data.append([current_time, laser_status])
        return

## Main loop for real-time processing

cv2.namedWindow("GrayDarkDarker", flags=cv2.WINDOW_NORMAL)
cv2.resizeWindow("GrayDarkDarker", round(width/2), round(height/2))

previous_darker_contour = None  # Initialize previous darker contour
state = "Stop"  # Initialize state
movement_data = [datetime.now(), "Stop"]  # Initialize movement data

frame_count = 0  # Initialize frame count
while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        print("Error: Could not read frame.")
        break
    frame_count += 1

    current_time = datetime.now()

    # Convert frame to grayscale
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Apply circular mask if ROI is selected
    if selected_circle:
        center, radius = selected_circle
        gray = apply_circle_mask(gray, center, radius)
    
    # Visualize the circular mask
    cv2.circle(frame, center, radius, (255, 0, 0), 2)
    
    # Threshold the grayscale frame
    _, dark_mask = cv2.threshold(gray, thres_dark_px, 255, cv2.THRESH_BINARY)

    # Apply the circular mask to the dark mask
    if selected_circle:
        dark_mask = apply_circle_mask(dark_mask, center, radius)
    
    # Find contours of dark areas
    dark_contours, _ = cv2.findContours(dark_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    # Find the largest dark contour
    largest_dark_contour = max(dark_contours, key=cv2.contourArea, default=None)
    largest_dark_area = cv2.contourArea(largest_dark_contour) if largest_dark_contour is not None else 0
    if largest_dark_area < thres_dark_area:
        largest_dark_contour = None
        largest_dark_area = 0
    
    if largest_dark_contour is not None:
        # Visualize the largest dark contour
        dark_contour_frame = cv2.cvtColor(dark_mask, cv2.COLOR_GRAY2BGR)
        cv2.drawContours(dark_contour_frame, [largest_dark_contour], -1, (0, 255, 0), 2) # Green contour

        # Find bounding box of the largest dark contour
        x, y, w, h = cv2.boundingRect(largest_dark_contour)
        dark_bbox = gray[y:y+h, x:x+w]

        # Apply circular mask to the dark bounding box
        dark_bbox = apply_circle_mask_to_box(dark_bbox, center, radius, (x, y))

        # Visualize the dark bounding box
        cv2.rectangle(dark_contour_frame, (x, y), (x+w, y+h), (0, 0, 255), 2)  # Red bounding box

        # Threshold the dark bounding box
        _, darker_mask = cv2.threshold(dark_bbox, thres_darker_px, 255, cv2.THRESH_BINARY)

        # Apply the circular mask to the darker mask
        darker_mask = apply_circle_mask_to_box(darker_mask, center, radius, (x, y))

        # Find contours of darker areas
        darker_contours, _ = cv2.findContours(darker_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        largest_darker_contour = max(darker_contours, key=cv2.contourArea, default=None)
        largest_darker_area = cv2.contourArea(largest_darker_contour) if largest_darker_contour is not None else 0
        if largest_darker_area < thres_darker_area:
            largest_darker_contour = None
            largest_darker_area = 0
        
        if largest_darker_contour is not None:
            # Visualize the largest darker contour
            cv2.drawContours(dark_contour_frame, [largest_darker_contour], -1, (255, 0, 0), 2) # Blue contour

    # Determine state (Move/Stop)
    if previous_darker_contour is None:
        state = "Stop"
        text_color = (0, 0, 255)  # Red for Stop
    elif largest_darker_contour is not None:
        M = cv2.moments(largest_darker_contour)
        cX = int(M["m10"] / M["m00"])
        cY = int(M["m01"] / M["m00"])
        N = cv2.moments(previous_darker_contour[0])
        pX = int(N["m10"] / N["m00"])
        pY = int(N["m01"] / N["m00"])
        distance = np.sqrt((cX - pX) ** 2 + (cY - pY) ** 2)
        timegap = current_time - previous_darker_contour[1]
        speed = distance / timegap.total_seconds()
        if speed > movement_threshold:
            state = "Move"
            text_color = (0, 255, 0)  # Green for Move
        else:
            state = "Stop"
            text_color = (0, 0, 255)  # Red for Stop

    # Store movement data
    movement_data.append([current_time, state])

    # Control the laser based on the state
    control_laser(state)

    # Display current time
    cv2.putText(frame, current_time.strftime("%H:%M:%S"), (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
    # Display state text
    cv2.putText(frame, state, (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 1, text_color, 2)
    # Display movement speed
    cv2.putText(frame, f"Speed: {speed:.2f} px/s", (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 1, text_color, 2)
    # Display movement threshold
    cv2.putText(frame, f"Threshold: {movement_threshold:.2f} px", (10, 120), cv2.FONT_HERSHEY_SIMPLEX, 1, text_color, 2)
    # Display laser status
    cv2.putText(frame, f"Laser: {laser_status}", (10, 150), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)

    # Update previous darker contour
    previous_darker_contour = largest_darker_contour, current_time

    # Display dark frames
    cv2.imshow("GrayDarkDarker", dark_contour_frame)
    # Display the frame
    cv2.imshow("Closed Loop Optogenetic Inhibition (real-time) by CHJ", frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Release the video capture and video writer
cap.release()
out.release()
cv2.destroyAllWindows()

## Save the logs
# Save the movement log
with open(log_movement, mode='w', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(movement_data)

# Save the laser log
with open(log_laser, mode='w', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(laser_data)