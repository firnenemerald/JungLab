import os
import cv2
import numpy as np
from collections import deque
import time

# Global threshold ratio for movement detection
threshold_ratiotoradius = 0.01  # Adjust this value to change the sensitivity of "Move" detection
threshold_black = 30  # Adjust this value to change the sensitivity of black pixel detection (lower value means more sensitive)
threshold_boxblack = 10  # Sensitivity for darker pixel detection within the bounding box
threshold_time = 0.1  # Adjust this value to change the time threshold for "Move" detection (seconds)

# Path to your video file
video_path = "C:\\Users\\chanh\\Downloads\\Video_ChAT\\ChAT_925-2_24-09-10-11-39-48_OF.mp4"
output_path = "C:\\Users\\chanh\\Downloads\\Video_ChAT\\output_video.mp4"

# Initialize video capture
cap = cv2.VideoCapture(video_path)
if not cap.isOpened():
    print("Error: Could not open video.")
    exit()

# Get video properties
fps = cap.get(cv2.CAP_PROP_FPS) or 30  # Use default FPS if not available
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

# Initialize VideoWriter for saving output
fourcc = cv2.VideoWriter_fourcc(*'mp4v')  # Codec for MP4
out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

# Variables for ROI selection
points = []
selected_circle = None
previous_bbox = None  # Track previous bounding box for continuity

# Variables for Move/Stop detection
movement_data = deque(maxlen=100)  # Store (timestamp, centroid) pairs
movement_threshold = None  # Movement threshold based on circle radius

# Function to calculate a circle passing through three points
def calculate_circle(pts):
    x1, y1 = pts[0]
    x2, y2 = pts[1]
    x3, y3 = pts[2]
    
    det = (x1 - x2) * (y2 - y3) - (x2 - x3) * (y1 - y2)
    if abs(det) < 1e-10:  # Check for collinear points
        print("Error: Points are collinear.")
        return None
    
    A = (x1 ** 2 + y1 ** 2)
    B = (x2 ** 2 + y2 ** 2)
    C = (x3 ** 2 + y3 ** 2)
    xc = ((A * (y2 - y3)) + (B * (y3 - y1)) + (C * (y1 - y2))) / (2 * det)
    yc = ((A * (x3 - x2)) + (B * (x1 - x3)) + (C * (x2 - x1))) / (2 * det)
    radius = np.sqrt((xc - x1) ** 2 + (yc - y1) ** 2)
    return (int(xc), int(yc)), int(radius)

# Function to mask the outside of the ROI
def apply_circle_mask(frame, center, radius):
    mask = np.zeros(frame.shape[:2], dtype=np.uint8)
    cv2.circle(mask, center, radius, 255, -1)
    return cv2.bitwise_and(frame, frame, mask=mask)

# Mouse callback to capture points for ROI
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

# Display the first frame for ROI selection
ret, first_frame = cap.read()
if not ret:
    print("Error: Could not read from webcam.")
    exit()

cv2.namedWindow("Define ROI")
cv2.setMouseCallback("Define ROI", mouse_callback)

while True:
    frame_copy = first_frame.copy()
    
    # Draw points and ROI circle dynamically
    for point in points:
        cv2.circle(frame_copy, point, 5, (0, 255, 0), -1)  # Green points
    if selected_circle:
        center, radius = selected_circle
        cv2.circle(frame_copy, center, radius, (255, 0, 0), 2)  # Blue circle
    
    cv2.imshow("Define ROI", frame_copy)
    if cv2.waitKey(1) & 0xFF == ord('q') or selected_circle:
        break

cv2.destroyWindow("Define ROI")

# Real-time processing of frames from the webcam
while True:
    ret, frame = cap.read()
    if not ret:
        break

    # Convert frame to grayscale
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Apply circular mask if ROI is selected
    if selected_circle:
        center, radius = selected_circle
        gray = apply_circle_mask(gray, center, radius)

    # Threshold to isolate black pixels
    _, black_mask = cv2.threshold(gray, threshold_black, 255, cv2.THRESH_BINARY_INV)

    # Apply the circular mask to the black mask
    if selected_circle:
        black_mask = apply_circle_mask(black_mask, center, radius)

    # Find contours of black regions
    contours, _ = cv2.findContours(black_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Find the largest contour
    largest_contour = max(contours, key=cv2.contourArea, default=None)

    if largest_contour is not None and cv2.contourArea(largest_contour) > 500:  # Minimum size threshold
        x, y, w, h = cv2.boundingRect(largest_contour)
        previous_bbox = (x, y, w, h)  # Update previous bounding box
    elif previous_bbox is not None:
        x, y, w, h = previous_bbox
    else:
        continue

    # Crop the bounding box region
    bbox_region = gray[y:y+h, x:x+w]

    # Threshold the pixels inside the bounding box for darker values
    _, darker_pixels_mask = cv2.threshold(bbox_region, threshold_boxblack, 255, cv2.THRESH_BINARY_INV)

    # Find contours of the darker pixel group
    darker_contours, _ = cv2.findContours(darker_pixels_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Find the largest darker pixel group contour
    largest_darker_contour = max(darker_contours, key=cv2.contourArea, default=None)

    if largest_darker_contour is not None:
        # Calculate the centroid of the darker pixel group
        moments = cv2.moments(largest_darker_contour)
        if moments['m00'] > 0:  # Avoid division by zero
            darker_cx = int(moments['m10'] / moments['m00']) + x
            darker_cy = int(moments['m01'] / moments['m00']) + y

            # Draw the centroid
            cv2.circle(frame, (darker_cx, darker_cy), 5, (0, 0, 255), -1)  # Red dot for darker centroid

            # Highlight the darker pixel group in yellow
            cv2.drawContours(frame, [largest_darker_contour + (x, y)], -1, (0, 255, 255), thickness=cv2.FILLED)


    # Track centroid movement
    current_time = time.time()
    movement_data.append((current_time, (darker_cx, darker_cy)))

    # Remove old data beyond the threshold time
    while movement_data and (current_time - movement_data[0][0]) > threshold_time:
        movement_data.popleft()

    # Calculate total movement in the last threshold time
    total_movement = 0
    for i in range(1, len(movement_data)):
        p1 = movement_data[i - 1][1]
        p2 = movement_data[i][1]
        total_movement += np.sqrt((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2)

    # Determine state (Move/Stop)
    if total_movement > movement_threshold:
        state = "Move"
        text_color = (0, 255, 0)  # Green for Move
    else:
        state = "Stop"
        text_color = (0, 0, 255)  # Red for Stop

    # Display state
    cv2.putText(frame, f"State: {state}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, text_color, 2)

    # Draw the ROI and bounding box
    if selected_circle:
        cv2.circle(frame, center, radius, (255, 0, 0), 2)  # Blue circle
    cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)  # Green bounding box

    # Save the processed frame
    out.write(frame)

    # Display the frame
    cv2.imshow("Mouse Movement Detection", frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
out.release()
cv2.destroyAllWindows()