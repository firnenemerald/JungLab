import os
os.environ["OPENCV_VIDEOIO_MSMF_ENABLE_HW_TRANSFORMS"] = "0"

import cv2
import numpy as np
import digitalio
import board
import csv
from datetime import datetime

################################################################################
# Helper Functions
################################################################################
def create_file_if_not_exists(filepath):
    """Create an empty file if it doesn't exist."""
    if not os.path.exists(filepath):
        open(filepath, "x").close()

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

def apply_circle_mask_to_box(box_region, center, radius, box_offset):
    """
    Mask a bounding-box sub-image to the same circle, offset by (box_offset).
    """
    mask = np.zeros(box_region.shape[:2], dtype=np.uint8)
    offset_center = (center[0] - box_offset[0], center[1] - box_offset[1])
    cv2.circle(mask, offset_center, radius, 255, -1)
    return cv2.bitwise_and(box_region, box_region, mask=mask)

def contour_circularity(contour):
    """Circularity = 4π * area / perimeter^2."""
    area = cv2.contourArea(contour)
    perimeter = cv2.arcLength(contour, True)
    return 0 if perimeter == 0 else (4.0 * np.pi * area) / (perimeter * perimeter)

################################################################################
# Session Setup
################################################################################
session_dir = r"C:\Users\Jung Lab 2\Videos" + datetime.now().strftime("/%y%m%d_%H%M%S")
os.makedirs(session_dir, exist_ok=True)

# Set file paths
output_path     = os.path.join(session_dir, "output_video.mp4")
output_path_raw = os.path.join(session_dir, "output_video_raw.mp4")
log_dir         = os.path.join(session_dir, "Log")
os.makedirs(log_dir, exist_ok=True)

log_metadata = os.path.join(log_dir, "log_metadata_" + datetime.now().strftime("%y%m%d_%H%M%S") + ".csv")
log_movement = os.path.join(log_dir, "log_movement_" + datetime.now().strftime("%y%m%d_%H%M%S") + ".csv")
log_laser    = os.path.join(log_dir, "log_laser_" + datetime.now().strftime("%y%m%d_%H%M%S") + ".csv")
log_ledsync  = os.path.join(log_dir, "log_ledsync_" + datetime.now().strftime("%y%m%d_%H%M%S") + ".csv")

# Create CSV files if not existing
for filepath in [log_metadata, log_movement, log_laser, log_ledsync]:
    create_file_if_not_exists(filepath)

################################################################################
# Webcam Initialization
################################################################################
cap = cv2.VideoCapture(0)  # Change to 0 if default webcam is index 0
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)
if not cap.isOpened():
    print("Error: Could not access the webcam.")
    exit()

fps    = cap.get(cv2.CAP_PROP_FPS) or 30
width  = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

ret, first_frame = cap.read()
if not ret:
    print("Error: Could not read from webcam.")
    exit()

################################################################################
# Video Writers
################################################################################
fourcc  = cv2.VideoWriter_fourcc(*'mp4v')
out     = cv2.VideoWriter(output_path,     fourcc, fps, (width, height))
out_raw = cv2.VideoWriter(output_path_raw, fourcc, fps, (width, height))

################################################################################
# Mini-Session Plan
################################################################################
mini_sessions = [
    ("CLOI OFF", 120),
    ("CLOI ON",  120),
    ("CLOI OFF", 120),
    ("CLOI ON",  120),
    ("CLOI OFF", 120),
    ("CLOI ON",  120),
]
total_mini_sessions = len(mini_sessions)
current_mini_idx    = 0

################################################################################
# Threshold Trackbars and Defaults
################################################################################
thres_time         = 0.1
thres_movement     = 0.1
thres_dark_px      = 50
thres_darker_px    = 25
thres_dark_area    = 500
thres_darker_area  = 800

selected_circle    = ((0, 0), 100)
movement_threshold = thres_movement * selected_circle[1]

def update_thresholds(x):
    global thres_time, thres_movement, movement_threshold
    global thres_dark_px, thres_darker_px, thres_dark_area, thres_darker_area

    thres_time         = cv2.getTrackbarPos("Time (ms)",  "Thresholds") / 1000
    thres_movement     = cv2.getTrackbarPos("Movement",   "Thresholds") / 100
    movement_threshold = thres_movement * selected_circle[1]
    thres_dark_px      = cv2.getTrackbarPos("Dark Px",    "Thresholds")
    thres_darker_px    = cv2.getTrackbarPos("Darkr Px",   "Thresholds")
    thres_dark_area    = cv2.getTrackbarPos("Dark Area",  "Thresholds")
    thres_darker_area  = cv2.getTrackbarPos("Darkr Area", "Thresholds")

cv2.namedWindow("Thresholds", flags=cv2.WINDOW_NORMAL)
cv2.resizeWindow("Thresholds", 640, 240)
cv2.createTrackbar("Time (ms)",  "Thresholds", int(thres_time * 1000), 1000, update_thresholds)
cv2.createTrackbar("Movement",   "Thresholds", int(thres_movement * 100), 100, update_thresholds)
cv2.createTrackbar("Dark Px",    "Thresholds", thres_dark_px, 100, update_thresholds)
cv2.createTrackbar("Darkr Px",   "Thresholds", thres_darker_px, 50, update_thresholds)
cv2.createTrackbar("Dark Area",  "Thresholds", thres_dark_area, 1000, update_thresholds)
cv2.createTrackbar("Darkr Area", "Thresholds", thres_darker_area, 1000, update_thresholds)

################################################################################
# ROI Definition via 3 Mouse Clicks
################################################################################
points = []
def mouse_callback(event, x, y, flags, param):
    global points, selected_circle, movement_threshold
    if event == cv2.EVENT_LBUTTONDOWN:
        points.append((x, y))
        if len(points) == 3:
            circle_data = calculate_circle(points)
            if circle_data:
                selected_circle = circle_data
                movement_threshold = thres_movement * selected_circle[1]
                print(f"Circle Center: {selected_circle[0]}, Radius: {selected_circle[1]}, "
                      f"MovementThresh: {movement_threshold:.2f}")
            points = []

cv2.namedWindow("Define ROI")
cv2.resizeWindow("Define ROI", width, height)
cv2.setMouseCallback("Define ROI", mouse_callback)

while True:
    temp_frame = first_frame.copy()
    for pt in points:
        cv2.circle(temp_frame, pt, 5, (0, 255, 0), -1)
    if selected_circle[0] != (0, 0):
        cv2.circle(temp_frame, selected_circle[0], selected_circle[1], (255, 0, 0), 2)
    cv2.imshow("Define ROI", temp_frame)
    key = cv2.waitKey(1) & 0xFF
    if key == ord('q') or selected_circle[0] != (0, 0):
        break
cv2.destroyWindow("Define ROI")

################################################################################
# Laser Control Setup
################################################################################
laser = digitalio.DigitalInOut(board.C0)
led   = digitalio.DigitalInOut(board.C1)
laser.direction = digitalio.Direction.OUTPUT
led.direction   = digitalio.Direction.OUTPUT
laser_status    = "OFF"
laser.value     = False
laser_ON_last   = None
laser_OFF_last  = datetime.now()

X = 0.5  # Laser ON duration (s)
Y = 1.0  # Laser OFF duration (s)

def control_laser(status):
    """
    If current mini-session is CLOI ON:
        - If "Stop", toggle laser with X seconds ON, Y seconds OFF.
        - If "Move", do nothing (remain OFF).
    Otherwise keep laser OFF.
    """
    global laser_status, laser_ON_last, laser_OFF_last
    global laser_data, initial_time

    current_time = datetime.now()

    # If mini-session is CLOI OFF => ensure OFF
    if current_session_label == "CLOI OFF":
        if laser_status == "ON":
            laser.value = False
            laser_status = "OFF"
            laser_OFF_last = current_time
        return

    # For CLOI ON:
    if status == "Stop":
        # Laser never turned on before
        if laser_ON_last is None:
            laser.value = True
            laser_status = "ON"
            laser_ON_last = current_time
            laser_data.append([current_time, (current_time - initial_time).total_seconds(), laser_status])
            return

        elapsed_ms = (current_time - laser_ON_last).total_seconds() * 1000

        # Within ON window
        if elapsed_ms < (X * 1000):
            if laser_status == "OFF":
                laser.value = True
                laser_status = "ON"
            return

        # In OFF window
        if (X * 1000) <= elapsed_ms < ((X + Y) * 1000):
            if laser_status == "ON":
                laser.value = False
                laser_status = "OFF"
                laser_OFF_last = current_time
                laser_data.append([current_time, (current_time - initial_time).total_seconds(), laser_status])
            return

        # Past ON+OFF => restart cycle
        if elapsed_ms >= ((X + Y) * 1000):
            laser.value = True
            laser_status = "ON"
            laser_ON_last = current_time
            laser_data.append([current_time, (current_time - initial_time).total_seconds(), laser_status])
            return
    else:
        # status == "Move": keep OFF
        laser.value = False
        if laser_status == "ON":
            laser_status = "OFF"
            laser_OFF_last = current_time
            laser_data.append([current_time, (current_time - initial_time).total_seconds(), laser_status])

################################################################################
# Initialize Log Data
################################################################################
initial_time     = datetime.now()
center, rad      = selected_circle
metadata_data    = [[center, rad, 0, 0, 0, 0, 0]]
movement_data    = [[initial_time, 0, "Stop", 0, 0]]
laser_data       = [[initial_time, 0, "OFF"]]
ledsync_data     = [[initial_time, 0, "OFF"]]

centroid_history = []
previous_dark_contour = None
last_move_time   = None
MOVE_MEMORY_SEC  = 0.1
MIN_CIRCULARITY  = 0.4

################################################################################
# LED Blink (Sync) - 10s
################################################################################
while (datetime.now() - initial_time).total_seconds() < 10:
    t_elapsed_ms = (datetime.now() - initial_time).total_seconds() * 1000
    if t_elapsed_ms % 2000 < 1000:
        led.value = True
        ledsync_data.append([datetime.now(), (datetime.now() - initial_time).total_seconds(), "ON"])
    else:
        led.value = False
        ledsync_data.append([datetime.now(), (datetime.now() - initial_time).total_seconds(), "OFF"])

################################################################################
# Main Loop
################################################################################
window_name = "Closed Loop Optogenetic Inhibition (real-time) by CHJ"
cv2.namedWindow(window_name, flags=cv2.WINDOW_NORMAL)
cv2.resizeWindow(window_name, round(width/2), round(height/2))

frame_count = 0
state = "Stop"

while True:
    ret, frame = cap.read()
    if not ret:
        print("End of stream or cannot read frame.")
        break

    current_time   = datetime.now()
    elapsed        = (current_time - initial_time).total_seconds()
    frame_raw      = frame.copy()
    frame_count   += 1

    # Check mini-session progression
    if current_mini_idx >= total_mini_sessions:
        print("All mini-sessions complete. Stopping.")
        break
    current_session_label, current_session_duration = mini_sessions[current_mini_idx]
    cutoff_time = sum(s[1] for s in mini_sessions[:current_mini_idx + 1])
    if elapsed > cutoff_time:
        current_mini_idx += 1
        if current_mini_idx >= total_mini_sessions:
            print("All mini-sessions complete. Stopping.")
            break
        else:
            current_session_label, current_session_duration = mini_sessions[current_mini_idx]

    # Grayscale + circle mask
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    (cx, cy), radius = selected_circle
    if radius > 0:
        gray = apply_circle_mask(gray, (cx, cy), radius)
        cv2.circle(frame, (cx, cy), radius, (255, 0, 0), 2)

    # Threshold for dark region
    _, dark_mask = cv2.threshold(gray, thres_dark_px, 255, cv2.THRESH_BINARY_INV)
    if radius > 0:
        dark_mask = apply_circle_mask(dark_mask, (cx, cy), radius)
    dark_contours, _ = cv2.findContours(dark_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    max_circle_area        = np.pi * (radius * 0.9) ** 2
    dark_contours_filtered = [cnt for cnt in dark_contours if cv2.contourArea(cnt) <= max_circle_area]

    # Find the largest dark contour above threshold
    largest_dark_contour = None
    largest_dark_area    = 0
    for cnt in dark_contours_filtered:
        area = cv2.contourArea(cnt)
        if area > largest_dark_area:
            largest_dark_area    = area
            largest_dark_contour = cnt
    if largest_dark_area < thres_dark_area:
        largest_dark_contour = None

    dark_state   = "Not Detected"
    darker_state = "Not Detected"

    if largest_dark_contour is not None:
        dark_state = "Detected"
        cv2.drawContours(frame, [largest_dark_contour], -1, (0, 255, 0), 2)
        x, y, w, h = cv2.boundingRect(largest_dark_contour)
        cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 0, 255), 2)
        dark_bbox = gray[y:y + h, x:x + w]
        dark_bbox = apply_circle_mask_to_box(dark_bbox, (cx, cy), radius, (x, y))

        # "Darker" region inside the dark contour
        _, darker_mask = cv2.threshold(dark_bbox, thres_darker_px, 255, cv2.THRESH_BINARY_INV)
        kernel         = np.ones((3, 3), np.uint8)
        darker_mask    = cv2.morphologyEx(darker_mask, cv2.MORPH_OPEN, kernel)
        darker_mask    = cv2.morphologyEx(darker_mask, cv2.MORPH_CLOSE, kernel)
        darker_mask    = apply_circle_mask_to_box(darker_mask, (cx, cy), radius, (x, y))

        darker_contours, _ = cv2.findContours(darker_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        darker_contours_filtered = [
            dc for dc in darker_contours
            if (cv2.contourArea(dc) <= (w * h * 0.9))
        ]

        candidate_contours = []
        for dc in darker_contours_filtered:
            area_dc = cv2.contourArea(dc)
            if area_dc < thres_darker_area:
                continue
            if contour_circularity(dc) < MIN_CIRCULARITY:
                continue
            candidate_contours.append(dc)

        # Largest 'darker' contour
        largest_darker_contour = None
        largest_darker_area    = 0
        for dc in candidate_contours:
            area_dc = cv2.contourArea(dc)
            if area_dc > largest_darker_area:
                largest_darker_area    = area_dc
                largest_darker_contour = dc
        if largest_darker_contour is not None:
            darker_state = "Detected"
            offset_contour = largest_darker_contour.copy()
            offset_contour[:, 0, 0] += x
            offset_contour[:, 0, 1] += y
            cv2.drawContours(frame, [offset_contour], -1, (0, 255, 255), 3)

    # Movement logic
    if largest_dark_contour is None:
        if last_move_time is not None and (current_time - last_move_time).total_seconds() < MOVE_MEMORY_SEC:
            state = "Move"
        else:
            state = "Stop"
        previous_dark_contour = None
    else:
        M = cv2.moments(largest_dark_contour)
        cX, cY = (int(M["m10"] / M["m00"]), int(M["m01"] / M["m00"])) if M["m00"] != 0 else (0, 0)
        cv2.circle(frame, (cX, cY), 2, (0, 0, 255), -1)
        centroid_history.append((cX, cY))
        if len(centroid_history) > 20:
            centroid_history.pop(0)

        if previous_dark_contour is None:
            state = "Stop"
        else:
            prev_cnt, prev_time = previous_dark_contour
            M_prev = cv2.moments(prev_cnt)
            pX, pY = (int(M_prev["m10"] / M_prev["m00"]), int(M_prev["m01"] / M_prev["m00"])) if M_prev["m00"] != 0 else (cX, cY)
            distance = np.sqrt((cX - pX)**2 + (cY - pY)**2)
            timegap  = (current_time - prev_time).total_seconds()
            speed    = distance / timegap if timegap > 0 else 0

            if speed > movement_threshold:
                state = "Move"
                last_move_time = current_time
            else:
                # Keep 'Move' for up to MOVE_MEMORY_SEC
                if last_move_time and (current_time - last_move_time).total_seconds() < MOVE_MEMORY_SEC:
                    state = "Move"
                else:
                    state = "Stop"

        previous_dark_contour = (largest_dark_contour, current_time)

    # Draw centroid history
    for (hx, hy) in centroid_history:
        cv2.circle(frame, (hx, hy), 2, (0, 0, 255), -1)

    # Append data
    movement_data.append([current_time, elapsed, state, cX if largest_dark_contour else 0, cY if largest_dark_contour else 0])
    metadata_data.append([[thres_time, thres_movement, movement_threshold, thres_dark_px, thres_darker_px, thres_dark_area, thres_darker_area]])

    # Laser control
    control_laser(state)

    # Text overlays
    cv2.putText(frame, f"Mini-session {current_mini_idx+1}/{total_mini_sessions}: {current_session_label}",
                (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
    cv2.putText(frame, f"Time: {current_time.strftime('%H:%M:%S.%f')[:-3]} ({elapsed:.2f}s), Frame: {frame_count}",
                (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
    cv2.putText(frame, f"Movement: {state}", (10, 110), cv2.FONT_HERSHEY_SIMPLEX, 1.2,
                (0, 0, 0) if state == "Move" else (0, 0, 255), 2)
    cv2.putText(frame, f"(Threshold: {movement_threshold:.2f})",
                (10, 150), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
    cv2.putText(frame, f"Dark: {dark_state}, Darker: {darker_state}",
                (10, 190), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
    cv2.putText(frame, f"Laser: {laser_status}", (10, 230), cv2.FONT_HERSHEY_SIMPLEX, 1,
                (0, 255, 0) if laser_status == "ON" else (255, 255, 255), 2)

    cv2.imshow(window_name, frame)
    out.write(frame)
    out_raw.write(frame_raw)

    if elapsed >= 12 * 60:
        print("Reached 12 minutes total. Stopping.")
        break
    if cv2.waitKey(1) & 0xFF == ord('q'):
        print("User pressed Q. Stopping.")
        break

# Cleanup
cap.release()
out.release()
out_raw.release()
cv2.destroyAllWindows()

################################################################################
# Save Logs
################################################################################
with open(log_metadata, mode='w', newline='') as f:
    csv.writer(f).writerows(metadata_data)

with open(log_movement, mode='w', newline='') as f:
    csv.writer(f).writerows(movement_data)

with open(log_laser, mode='w', newline='') as f:
    csv.writer(f).writerows(laser_data)

with open(log_ledsync, mode='w', newline='') as f:
    csv.writer(f).writerows(ledsync_data)

print("Done. Logs saved and video output saved.")
