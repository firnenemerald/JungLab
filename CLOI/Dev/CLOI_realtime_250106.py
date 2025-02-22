import os
import cv2
import numpy as np
import digitalio
import board
import csv
from datetime import datetime

################################################################################
# File I/O and Session Setup
################################################################################
video_path = "C:\\Users\\chanh\\Downloads\\Video_ChAT\\ChAT_925-2_24-07-18-13-56-02_OF.mp4"  # Your video file

# Create session directory: ./YYMMDD_HHMMSS
session_dir = "C:/Users/chanh/Downloads" + datetime.now().strftime("/%y%m%d_%H%M%S")
os.makedirs(session_dir, exist_ok=True)

# Video output file
output_path = os.path.join(session_dir, "output_video.mp4")

# Log directory
log_dir = os.path.join(session_dir, "Log")
os.makedirs(log_dir, exist_ok=True)

# Movement log file
log_movement = os.path.join(log_dir, "log_movement_" + datetime.now().strftime("%y%m%d_%H%M%S") + ".csv")
if not os.path.exists(log_movement):
    open(log_movement, "x")

# Laser log file
log_laser = os.path.join(log_dir, "log_laser_" + datetime.now().strftime("%y%m%d_%H%M%S") + ".csv")
if not os.path.exists(log_laser):
    open(log_laser, "x")

################################################################################
# Video Capture Initialization
################################################################################
cap = cv2.VideoCapture(video_path)
if not cap.isOpened():
    print("Error: Could not open video file.")
    exit()

fps = cap.get(cv2.CAP_PROP_FPS) or 30
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

# Read the first frame
ret, first_frame = cap.read()
if not ret:
    print("Error: Could not read the video.")
    exit()

################################################################################
# Video Writer Initialization
################################################################################
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

################################################################################
# Dynamic Thresholding Trackbars
################################################################################
thres_time = 0.1         # Time interval for movement evaluation (seconds)
thres_movement = 0.1     # Movement threshold (ratio relative to circle radius)
thres_dark_px = 50       # Threshold for 'dark' pixels (0-100)
thres_darker_px = 10     # Threshold for 'darker' region (0-50)
thres_dark_area = 500    # Min area for dark contour
thres_darker_area = 800  # Min area for 'darker' region

movement_threshold = 0.1  # in pixels; updated after ROI defined
selected_circle = ((0, 0), 100)  # (center=(0,0), radius=100) default

def update_thresholds(x):
    global thres_time, thres_movement, movement_threshold
    global thres_dark_px, thres_darker_px, thres_dark_area, thres_darker_area

    thres_time = cv2.getTrackbarPos("Time (ms)", "Thresholds") / 1000
    thres_movement = cv2.getTrackbarPos("Movement", "Thresholds") / 100
    movement_threshold = thres_movement * selected_circle[1]
    thres_dark_px = cv2.getTrackbarPos("Dark Px", "Thresholds")
    thres_darker_px = cv2.getTrackbarPos("Darkr Px", "Thresholds")
    thres_dark_area = cv2.getTrackbarPos("Dark Area", "Thresholds")
    thres_darker_area = cv2.getTrackbarPos("Darkr Area", "Thresholds")

cv2.namedWindow("Thresholds", flags=cv2.WINDOW_NORMAL)
cv2.resizeWindow("Thresholds", 640, 240)
cv2.createTrackbar("Time (ms)", "Thresholds", int(thres_time * 1000), 1000, update_thresholds)
cv2.createTrackbar("Movement", "Thresholds", int(thres_movement * 100), 100, update_thresholds)
cv2.createTrackbar("Dark Px", "Thresholds", thres_dark_px, 100, update_thresholds)
cv2.createTrackbar("Darkr Px", "Thresholds", thres_darker_px, 50, update_thresholds)
cv2.createTrackbar("Dark Area", "Thresholds", thres_dark_area, 1000, update_thresholds)
cv2.createTrackbar("Darkr Area", "Thresholds", thres_darker_area, 1000, update_thresholds)

################################################################################
# ROI Definition (3 points -> circle)
################################################################################
initial_time = datetime.now()

def calculate_circle(pts):
    """Return (center, radius) for a circle through 3 points, or None if collinear."""
    x1, y1 = pts[0]
    x2, y2 = pts[1]
    x3, y3 = pts[2]
    det = (x1 - x2) * (y2 - y3) - (x2 - x3) * (y1 - y2)
    if abs(det) < 1e-10:
        print("Error: The 3 points are collinear; cannot define a circle.")
        return None
    A = (x1**2 + y1**2)
    B = (x2**2 + y2**2)
    C = (x3**2 + y3**2)
    xc = ((A * (y2 - y3)) + (B * (y3 - y1)) + (C * (y1 - y2))) / (2 * det)
    yc = ((A * (x3 - x2)) + (B * (x1 - x3)) + (C * (x2 - x1))) / (2 * det)
    r = np.sqrt((xc - x1)**2 + (yc - y1)**2)
    return (int(xc), int(yc)), int(r)

def apply_circle_mask(frame, center, radius):
    """Return a masked copy of frame within circle (center,radius)."""
    mask = np.zeros(frame.shape[:2], dtype=np.uint8)
    cv2.circle(mask, center, radius, 255, -1)
    return cv2.bitwise_and(frame, frame, mask=mask)

points = []
def mouse_callback(event, x, y, flags, param):
    global points, selected_circle, movement_threshold
    if event == cv2.EVENT_LBUTTONDOWN:
        points.append((x, y))
        if len(points) == 3:
            circle_data = calculate_circle(points)
            if circle_data:
                selected_circle = circle_data
                center, rad = selected_circle
                movement_threshold = thres_movement * rad
                print(f"Circle Center: {center}, Radius: {rad}, MovementThresh: {movement_threshold:.2f}")
            points = []

cv2.namedWindow("Define ROI")
cv2.resizeWindow("Define ROI", width, height)
cv2.setMouseCallback("Define ROI", mouse_callback)

while True:
    temp_frame = first_frame.copy()
    for pt in points:
        cv2.circle(temp_frame, pt, 5, (0, 255, 0), -1)
    if selected_circle[0] != (0, 0):
        c, r = selected_circle
        cv2.circle(temp_frame, c, r, (255, 0, 0), 2)
    cv2.imshow("Define ROI", temp_frame)
    key = cv2.waitKey(1) & 0xFF
    if key == ord('q'):
        break
    if selected_circle[0] != (0, 0):
        break
cv2.destroyWindow("Define ROI")

def apply_circle_mask_to_box(box_region, center, radius, box_offset):
    """
    Mask a bounding-box sub-image to the same circle, offset by (box_offset).
    """
    mask = np.zeros(box_region.shape[:2], dtype=np.uint8)
    offset_center = (center[0] - box_offset[0], center[1] - box_offset[1])
    cv2.circle(mask, offset_center, radius, 255, -1)
    return cv2.bitwise_and(box_region, box_region, mask=mask)

################################################################################
# Laser Control Setup
################################################################################
laser = digitalio.DigitalInOut(board.C0)
laser.direction = digitalio.Direction.OUTPUT
laser_status = "OFF"
laser_data = [[0, "OFF"]]
laser_ON_last = None
laser_OFF_last = datetime.now()

X = 0.5  # Laser ON duration (s)
Y = 1.0  # Laser OFF duration (s)

def control_laser(status):
    """
    Example: if status == "Stop", turn laser ON for X seconds, OFF for Y seconds.
    Adjust logic as needed.
    """
    global laser, laser_status, laser_data, laser_ON_last, laser_OFF_last
    current_time = datetime.now()

    # If never turned on & status is "Stop", start ON
    if status == "Stop" and laser_ON_last is None:
        laser.value = True
        laser_status = "ON"
        laser_ON_last = current_time
        laser_data.append([(current_time - initial_time).total_seconds(), laser_status])
        return
    # If never turned on & status is "Move", do nothing
    elif status == "Move" and laser_ON_last is None:
        return

    elapsed_ms = (current_time - laser_ON_last).total_seconds() * 1000 if laser_ON_last else 0

    # Within ON window
    if elapsed_ms < (X * 1000):
        if laser_status == "OFF":
            laser.value = True
            laser_status = "ON"
        return
    # Between X and X+Y => OFF
    elif (X * 1000) <= elapsed_ms < ((X + Y) * 1000):
        if laser_status == "ON":
            laser.value = False
            laser_status = "OFF"
            laser_OFF_last = current_time
            laser_data.append([(current_time - initial_time).total_seconds(), laser_status])
        return
    # Past X+Y => repeat if still "Stop"
    elif status == "Stop" and elapsed_ms >= ((X + Y) * 1000):
        laser.value = True
        laser_status = "ON"
        laser_ON_last = current_time
        laser_data.append([(current_time - initial_time).total_seconds(), laser_status])
        return

################################################################################
# Helper Functions
################################################################################
def contour_circularity(contour):
    """Circularity = 4π * area / perimeter^2."""
    area = cv2.contourArea(contour)
    perimeter = cv2.arcLength(contour, True)
    if perimeter == 0:
        return 0
    return (4.0 * np.pi * area) / (perimeter * perimeter)

################################################################################
# Main Loop
################################################################################
window_name = "Closed Loop Optogenetic Inhibition (real-time) by CHJ"
cv2.namedWindow(window_name, flags=cv2.WINDOW_NORMAL)
cv2.resizeWindow(window_name, round(width/2), round(height/2))

frame_count = 0
previous_dark_contour = None
state = "Stop"

# Movement log
movement_data = [[datetime.now(), "Stop"]]

# 1) Set Move memory to 0.1 seconds
MOVE_MEMORY_SEC = 0.1
last_move_time = None

# 2 & 3) Track centroid history (last 20)
centroid_history = []

# Minimum circularity for "darker" region
MIN_CIRCULARITY = 0.5

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        print("End of video or cannot read frame.")
        break
    frame_count += 1

    current_time = datetime.now()
    dark_state = "Not Detected"
    darker_state = "Not Detected"

    # Convert to grayscale
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Apply circular mask if defined
    center, radius = selected_circle
    if radius > 0:
        gray = apply_circle_mask(gray, center, radius)
        # Draw ROI on main frame
        cv2.circle(frame, center, radius, (255, 0, 0), 2)

    # Threshold for dark
    _, dark_mask = cv2.threshold(gray, thres_dark_px, 255, cv2.THRESH_BINARY_INV)
    if radius > 0:
        dark_mask = apply_circle_mask(dark_mask, center, radius)

    # Find dark contours
    dark_contours, _ = cv2.findContours(dark_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    max_circle_area = np.pi * (radius * 0.9) ** 2
    dark_contours = [cnt for cnt in dark_contours if cv2.contourArea(cnt) <= max_circle_area]

    largest_dark_contour = None
    largest_dark_area = 0
    for cnt in dark_contours:
        area = cv2.contourArea(cnt)
        if area > largest_dark_area:
            largest_dark_area = area
            largest_dark_contour = cnt

    if largest_dark_area < thres_dark_area:
        largest_dark_contour = None

    # If found dark contour, detect "darker" region inside
    if largest_dark_contour is not None:
        dark_state = "Detected"
        # Draw largest dark contour in green
        cv2.drawContours(frame, [largest_dark_contour], -1, (0, 255, 0), 2)

        # bounding box
        x, y, w, h = cv2.boundingRect(largest_dark_contour)
        cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 0, 255), 2)

        dark_bbox = gray[y:y+h, x:x+w]
        dark_bbox = apply_circle_mask_to_box(dark_bbox, center, radius, (x, y))

        # "darker" threshold
        _, darker_mask = cv2.threshold(dark_bbox, thres_darker_px, 255, cv2.THRESH_BINARY_INV)
        # Morph ops
        kernel = np.ones((3, 3), np.uint8)
        darker_mask = cv2.morphologyEx(darker_mask, cv2.MORPH_OPEN, kernel)
        darker_mask = cv2.morphologyEx(darker_mask, cv2.MORPH_CLOSE, kernel)
        darker_mask = apply_circle_mask_to_box(darker_mask, center, radius, (x, y))

        # Find darker contours
        darker_contours, _ = cv2.findContours(darker_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        darker_contours = [
            dc for dc in darker_contours
            if cv2.contourArea(dc) <= (w*h*0.9)
        ]

        candidate_contours = []
        for dc in darker_contours:
            area_dc = cv2.contourArea(dc)
            if area_dc < thres_darker_area:
                continue
            circ = contour_circularity(dc)
            if circ < MIN_CIRCULARITY:
                continue
            candidate_contours.append(dc)

        largest_darker_contour = None
        largest_darker_area = 0
        for dc in candidate_contours:
            area_dc = cv2.contourArea(dc)
            if area_dc > largest_darker_area:
                largest_darker_area = area_dc
                largest_darker_contour = dc

        if largest_darker_contour is not None:
            darker_state = "Detected"
            offset_contour = largest_darker_contour.copy()
            offset_contour[:, 0, 0] += x
            offset_contour[:, 0, 1] += y
            cv2.drawContours(frame, [offset_contour], -1, (0, 255, 255), 3) # Yellow

    # Movement logic with 0.1s memory
    if largest_dark_contour is None:
        # No contour => possibly stop
        if last_move_time is not None:
            if (current_time - last_move_time).total_seconds() >= MOVE_MEMORY_SEC:
                state = "Stop"
            else:
                state = "Move"
        else:
            state = "Stop"
        previous_dark_contour = None
    else:
        M = cv2.moments(largest_dark_contour)
        if M["m00"] != 0:
            cX = int(M["m10"] / M["m00"])
            cY = int(M["m01"] / M["m00"])
        else:
            cX, cY = 0, 0

        # 2) Draw the centroid (red dot, size=2)
        cv2.circle(frame, (cX, cY), 2, (0, 0, 255), -1)

        # 3) Keep track of last 20 centroid positions
        centroid_history.append((cX, cY))
        if len(centroid_history) > 20:
            centroid_history.pop(0)

        # Compare to previous contour to check movement speed
        if previous_dark_contour is None:
            state = "Stop"
        else:
            prev_cnt, prev_time = previous_dark_contour
            M_prev = cv2.moments(prev_cnt)
            if M_prev["m00"] != 0:
                pX = int(M_prev["m10"] / M_prev["m00"])
                pY = int(M_prev["m01"] / M_prev["m00"])
            else:
                pX, pY = cX, cY

            distance = np.sqrt((cX - pX)**2 + (cY - pY)**2)
            timegap = (current_time - prev_time).total_seconds()
            speed = distance / timegap if timegap > 0 else 0

            if speed > movement_threshold:
                state = "Move"
                last_move_time = current_time
            else:
                # If speed < threshold, check memory
                if last_move_time is not None and (current_time - last_move_time).total_seconds() < MOVE_MEMORY_SEC:
                    state = "Move"
                else:
                    state = "Stop"

        previous_dark_contour = (largest_dark_contour, current_time)

    # Draw the centroid history (last 20) as red dots
    for (hx, hy) in centroid_history:
        cv2.circle(frame, (hx, hy), 2, (0, 0, 255), -1)

    # Log movement
    movement_data.append([(current_time - initial_time).total_seconds(), state])

    # Laser control
    control_laser(state)

    # Choose colors
    if state == "Move":
        text_color = (0, 0, 0)  # black
    else:
        text_color = (0, 0, 255)  # red

    if laser_status == "ON":
        laser_color = (0, 255, 0)  # green
    else:
        laser_color = (255, 255, 255)  # white

    # Overlay text
    cv2.putText(frame,
                f"Time: {current_time.strftime('%H:%M:%S.%f')[:-3]} "
                f"({(current_time - initial_time).total_seconds():.2f}s), Frame: {frame_count}",
                (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
    cv2.putText(frame, f"Movement: {state}",
                (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 2, text_color, 2)
    cv2.putText(frame, f"(Threshold: {movement_threshold:.2f})",
                (10, 140), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
    cv2.putText(frame, f"Dark: {dark_state}, Darker: {darker_state}",
                (10, 170), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
    cv2.putText(frame, f"Laser: {laser_status}",
                (10, 200), cv2.FONT_HERSHEY_SIMPLEX, 1, laser_color, 2)

    # Show in main window
    cv2.imshow(window_name, frame)

    # Write output video
    out.write(frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
out.release()
cv2.destroyAllWindows()

################################################################################
# Save Logs
################################################################################
with open(log_movement, mode='w', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(movement_data)

with open(log_laser, mode='w', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(laser_data)

print("Done. Logs saved and video output saved.")
