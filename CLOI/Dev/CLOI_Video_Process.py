import os
import cv2
import numpy as np
import csv

# Set the base directory
base_dir = r'C:/Users/chanh/Downloads/CLOI_Video'

# List all .mp4 files starting with "ChAT_947-1"
video_files = [f for f in os.listdir(base_dir) if f.startswith('ChAT_947-1') and f.endswith('.mp4')]

video_path = os.path.join(base_dir, video_files[0])

cap = cv2.VideoCapture(video_path)
frame_num = 0
results = []

selected_circle = None  # Initialize the selected circle variable
points = []

def calculate_circle(pts):
    """Return (center, radius) for a circle through 3 points, or None if collinear."""
    x1, y1 = pts[0]; x2, y2 = pts[1]; x3, y3 = pts[2]
    det = (x1 - x2) * (y2 - y3) - (x2 - x3) * (y1 - y2)
    if abs(det) < 1e-10:
        print("Error: The 3 points are collinear; cannot define a circle.")
        return None
    A = (x1**2 + y1**2); B = (x2**2 + y2**2); C = (x3**2 + y3**2)
    xc = ((A * (y2 - y3)) + (B * (y3 - y1)) + (C * (y1 - y2))) / (2 * det)
    yc = ((A * (x3 - x2)) + (B * (x1 - x3)) + (C * (x2 - x1))) / (2 * det)
    r = np.sqrt((xc - x1)**2 + (yc - y1)**2)
    return (int(xc), int(yc)), int(r)

def apply_circle_mask(frame, center, radius):
    """Return a masked copy of frame within circle (center,radius)."""
    mask = np.zeros(frame.shape[:2], dtype=np.uint8)
    cv2.circle(mask, center, radius, 255, -1)
    return cv2.bitwise_and(frame, frame, mask=mask)

def mouse_callback(event, x, y, flags, param):
    global points, selected_circle
    if event == cv2.EVENT_LBUTTONDOWN:
        points.append((x, y))
        if len(points) <= 3:
            # Draw the clicked points as small red circles
            cv2.circle(param, (x, y), 5, (0, 0, 255), -1)
            cv2.imshow('Frame', param)
        if len(points) == 3:
            circle_data = calculate_circle(points)
            if circle_data:
                selected_circle = circle_data
                center, rad = selected_circle
                print(f"Circle Center: {center}, Radius: {rad}")
                # Draw the defined circle in red
                cv2.circle(param, center, rad, (0, 0, 255), 2)
                cv2.imshow('Frame', param)
            points = []

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    frame_num += 1
    if frame_num == 1:
        cv2.imshow('Frame', frame)
        cv2.setMouseCallback('Frame', mouse_callback, param=frame.copy())
        cv2.waitKey(0)  # Wait until the user clicks 3 points
        if selected_circle is None:
            print("No circle selected. Exiting.")
            break

    if selected_circle:
        center, radius = selected_circle
        frame = apply_circle_mask(frame, center, radius)

    # Convert frame to HSV
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)

    # Define range for green color and create mask
    lower_green = np.array([40, 40, 40])
    upper_green = np.array([80, 255, 255])
    mask = cv2.inRange(hsv, lower_green, upper_green)

    # Initialize default coordinates and max green value
    head_coor_x, head_coor_y = -1, -1
    max_green_value = 0

    # Check if there is any green in the frame
    if np.any(mask):
        # Get the coordinates of the maximum intensity of green
        green_channel = frame[:, :, 1]  # Extract the green channel
        min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(green_channel, mask=mask)
        if max_val > 250:  # Only process if maximum green value is above 250
            max_green_value = max_val  # Store the maximum green value
            head_coor_x, head_coor_y = max_loc

    # Store the result if max_green_value > 250
    if max_green_value > 250:
        results.append((frame_num, head_coor_x, head_coor_y, max_green_value))

        # Draw a circle at the point of maximum intensity of green
        if head_coor_x != -1 and head_coor_y != -1:
            cv2.circle(frame, (head_coor_x, head_coor_y), 5, (255, 0, 0), -1)  # Blue circle

        # Display the maximum green value on the frame
        cv2.putText(frame, f"Max Green: {max_green_value:.0f}", (10, 30), 
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

    # Display the frame
    cv2.imshow('Frame', frame)

    # Break the loop if 'q' is pressed
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Define the CSV file path
csv_file_path = os.path.join(base_dir, 'results.csv')

# Write results to the CSV file
with open(csv_file_path, mode='w', newline='') as csv_file:
    csv_writer = csv.writer(csv_file)
    # Write the header
    csv_writer.writerow(['Frame', 'Head_Coordinate_X', 'Head_Coordinate_Y', 'Max_Green_Value'])
    # Write the results
    csv_writer.writerows(results)

print(f"Results saved to {csv_file_path}")

# Release the video capture object and close all OpenCV windows
cap.release()
cv2.destroyAllWindows()
