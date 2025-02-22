import os
os.environ["OPENCV_VIDEOIO_MSMF_ENABLE_HW_TRANSFORMS"] = "0"

import cv2
import numpy as np
import digitalio
import board
import csv
from datetime import datetime

################################################################################
# File I/O and Session Setup
################################################################################
# Create session directory: ./YYMMDD_HHMMSS
session_dir = "C:/Users/LuckyFace/Videos" + datetime.now().strftime("/%y%m%d_%H%M%S")
os.makedirs(session_dir, exist_ok=True)

# Video output file
output_path = os.path.join(session_dir, "output_video.mp4")
output_path_raw = os.path.join(session_dir, "output_video_raw.mp4")

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
# Webcam Capture Initialization
################################################################################
cap = cv2.VideoCapture(1)  # Change to 0 if your default webcam is index 0
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)

if not cap.isOpened():
    print("Error: Could not access the webcam.")
    exit()

fps = cap.get(cv2.CAP_PROP_FPS) or 30
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

# Grab one frame to initialize
ret, first_frame = cap.read()
if not ret:
    print("Error: Could not read from webcam.")
    exit()

################################################################################
# Video Writer Initialization
################################################################################
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
fourcc2 = cv2.VideoWriter_fourcc(*'mp4v')
out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))
out2 = cv2.VideoWriter(output_path_raw, fourcc2, fps, (width, height))

################################################################################
# Mini-Session Setup
################################################################################
# 6 mini-sessions, each 2 minutes (120s) => total 12 minutes
mini_sessions = [
    ("CLOI OFF", 120),
    ("CLOI ON",  120),
    ("CLOI OFF", 120),
    ("CLOI ON",  120),
    ("CLOI OFF", 120),
    ("CLOI ON",  120),
]
total_mini_sessions = len(mini_sessions)  # = 6
current_mini_idx = 0  # Tracks which mini-session we're in
initial_time = datetime.now()

################################################################################
# Dynamic Thresholding Trackbars
################################################################################
thres_time = 0.1         # Time interval for movement evaluation (seconds)
thres_movement = 0.1     # Movement threshold (ratio relative to circle radius)
thres_dark_px = 50       # Threshold for 'dark' pixels (0-100)
thres_darker_px = 25     # Threshold for 'darker' region (0-50)
thres_dark_area = 500    # Min area for dark contour
thres_darker_area = 800  # Min area for 'darker' region

# Will be updated after ROI is defined
movement_threshold = 0.1  # in pixels
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

# We'll temporarily display "first_frame" so user can click 3 points
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
# Laser Control Setup (hardware-based)
################################################################################
laser = digitalio.DigitalInOut(board.C0)
led = digitalio.DigitalInOut(board.C1)
laser.direction = digitalio.Direction.OUTPUT
led.direction = digitalio.Direction.OUTPUT
laser_status = "OFF"
laser_data = [[0, "OFF"]]
laser_ON_last = None

# We'll record the last time we turned laser OFF
laser_OFF_last = datetime.now()

# X seconds ON, Y seconds OFF if the state is "Stop" (example logic)
X = 0.5  # Laser ON duration (s)
Y = 1.0  # Laser OFF duration (s)

def control_laser(status):
    """
    If status == "Stop", we toggle laser in an ON->OFF->ON cycle (X seconds ON, Y seconds OFF).
    If status == "Move", do nothing (remain OFF).
    Adjust this to your needs or integrate with 'CLOI ON/OFF' if you want to override.
    """
    global laser, laser_status, laser_data, laser_ON_last, laser_OFF_last, current_session_label
    current_time = datetime.now()

    if current_session_label == "CLOI ON":
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
    else:
        if laser_status == "ON":
            laser.value = False
            laser_status == "OFF"
            laser_OFF_last = current_time
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
# Blink 5 times before main loop
################################################################################

start_blink = datetime.now()
while (datetime.now() - start_blink).total_seconds() < 10:
    if ((datetime.now() - start_blink).total_seconds() * 1000) % 2000 < 1000:
        led.value = True
    else:
        led.value = False

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

# Movement memory
MOVE_MEMORY_SEC = 0.1
last_move_time = None

# Centroid history (up to last 20)
centroid_history = []

MIN_CIRCULARITY = 0.5  # For "darker" region

while True:
    ret, frame = cap.read()
    frame_raw = frame.copy()
    if not ret:
        print("End of stream or cannot read frame.")
        break
    frame_count += 1

    current_time = datetime.now()
    elapsed_seconds = (current_time - initial_time).total_seconds()

    # ------------------------------
    # Check if we've completed all mini-sessions
    # ------------------------------
    if current_mini_idx >= total_mini_sessions:
        print("All 6 mini-sessions (12 minutes) complete. Stopping.")
        break

    # Identify the current mini-session label/duration
    current_session_label, current_session_duration = mini_sessions[current_mini_idx]

    # Sum of durations up to current mini-session
    cutoff_time = sum(x[1] for x in mini_sessions[:current_mini_idx+1])

    # If we've passed the cutoff for the current mini-session, move to next
    if elapsed_seconds > cutoff_time:
        current_mini_idx += 1
        if current_mini_idx >= total_mini_sessions:
            print("All 6 mini-sessions complete. Stopping.")
            break
        else:
            current_session_label, current_session_duration = mini_sessions[current_mini_idx]

    # Convert frame to grayscale
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Apply circular ROI mask if defined
    (center, radius) = selected_circle
    if radius > 0:
        gray = apply_circle_mask(gray, center, radius)
        # Draw ROI on the main frame
        cv2.circle(frame, center, radius, (255, 0, 0), 2)

    # Threshold for dark region
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

    dark_state = "Not Detected"
    darker_state = "Not Detected"

    # If found dark contour, detect "darker" region inside
    if largest_dark_contour is not None:
        dark_state = "Detected"
        cv2.drawContours(frame, [largest_dark_contour], -1, (0, 255, 0), 2)

        x, y, w, h = cv2.boundingRect(largest_dark_contour)
        cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 0, 255), 2)

        dark_bbox = gray[y:y+h, x:x+w]
        dark_bbox = apply_circle_mask_to_box(dark_bbox, center, radius, (x, y))

        # "darker" threshold
        _, darker_mask = cv2.threshold(dark_bbox, thres_darker_px, 255, cv2.THRESH_BINARY_INV)
        kernel = np.ones((3, 3), np.uint8)
        darker_mask = cv2.morphologyEx(darker_mask, cv2.MORPH_OPEN, kernel)
        darker_mask = cv2.morphologyEx(darker_mask, cv2.MORPH_CLOSE, kernel)
        darker_mask = apply_circle_mask_to_box(darker_mask, center, radius, (x, y))

        darker_contours, _ = cv2.findContours(darker_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        darker_contours = [dc for dc in darker_contours if cv2.contourArea(dc) <= (w*h*0.9)]

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
            cv2.drawContours(frame, [offset_contour], -1, (0, 255, 255), 3)  # Yellow

    # Movement logic with memory
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
        # We have a contour
        M = cv2.moments(largest_dark_contour)
        if M["m00"] != 0:
            cX = int(M["m10"] / M["m00"])
            cY = int(M["m01"] / M["m00"])
        else:
            cX, cY = 0, 0

        # Draw the centroid (red dot)
        cv2.circle(frame, (cX, cY), 2, (0, 0, 255), -1)

        # Keep track of last 20 centroids
        centroid_history.append((cX, cY))
        if len(centroid_history) > 20:
            centroid_history.pop(0)

        # Compare with previous contour to check movement speed
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
                if last_move_time is not None and (current_time - last_move_time).total_seconds() < MOVE_MEMORY_SEC:
                    state = "Move"
                else:
                    state = "Stop"

        previous_dark_contour = (largest_dark_contour, current_time)

    # Draw centroid history
    for (hx, hy) in centroid_history:
        cv2.circle(frame, (hx, hy), 2, (0, 0, 255), -1)

    # Log movement
    movement_data.append([(current_time - initial_time).total_seconds(), state])

    # Laser control
    control_laser(state)

    # Overlay text
    # 1) Mini-session info
    cv2.putText(frame,
                f"Mini-session {current_mini_idx+1}/{total_mini_sessions}: {current_session_label}",
                (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
    # 2) Elapsed time, frame count
    cv2.putText(frame,
                f"Time: {current_time.strftime('%H:%M:%S.%f')[:-3]} ({elapsed_seconds:.2f}s), Frame: {frame_count}",
                (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
    # 3) Movement info
    if state == "Move":
        text_color = (0, 0, 0)  # black
    else:
        text_color = (0, 0, 255)  # red
        cv2.putText(frame, f"Movement: {state}",
                    (10, 110), cv2.FONT_HERSHEY_SIMPLEX, 1.2, text_color, 2)

    cv2.putText(frame, f"(Threshold: {movement_threshold:.2f})",
                (10, 150), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)

    # 4) Dark/darker detection info
    cv2.putText(frame, f"Dark: {dark_state}, Darker: {darker_state}",
                (10, 190), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)

    # 5) Laser status
    if laser_status == "ON":
        laser_color = (0, 255, 0)  # green
    else:
        laser_color = (255, 255, 255)  # white
    cv2.putText(frame, f"Laser: {laser_status}",
                (10, 230), cv2.FONT_HERSHEY_SIMPLEX, 1, laser_color, 2)

    # Show in main window
    cv2.imshow(window_name, frame)
    # Write output video
    out.write(frame)
    out2.write(frame_raw)

    # Stop if total time >= 12 minutes or user presses 'q'
    if elapsed_seconds >= 12 * 60:
        print("Reached 12 minutes total. Stopping.")
        break
    if cv2.waitKey(1) & 0xFF == ord('q'):
        print("User pressed Q. Stopping.")
        break

# Cleanup
cap.release()
out.release()
out2.release()
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
