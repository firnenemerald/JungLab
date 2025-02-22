import os
import numpy as np
import digitalio
import board
from datetime import datetime

################################################################################
# Mini-Session Setup
################################################################################
# 5 mini-sessions, each 2 minutes (120s) => total 10 minutes
mini_sessions = [
    ("Laser OFF", 120),
    ("Laser ON",  120),
    ("Laser OFF", 120),
    ("Laser ON",  120),
    ("Laser OFF", 120),
]
total_mini_sessions = len(mini_sessions)  # = 5
current_mini_idx = 0  # Tracks which mini-session we're in
current_session_label = "Laser OFF"

################################################################################
# Laser Control Setup (hardware-based)
################################################################################
laser = digitalio.DigitalInOut(board.C0)
laser.direction = digitalio.Direction.OUTPUT
laser.status = False
laser_status = "OFF"

def control_laser(status):
    """
    If mini_session == "Laser OFF", we toggle laser OFF.
    If mini_session == "Laser ON", we toggle laser ON.
    """
    global laser, laser_status, current_session_label
    current_time = datetime.now()

    if current_session_label == "Laser ON":
        # If current time is inside random_intervals
        if any(lower <= (current_time - initial_time).total_seconds() <= lower + 0.500 for lower, _ in random_intervals):
            laser.value = True
            laser_status = "ON"
            laser_data.append([current_time, (current_time - initial_time).total_seconds(), laser_status])
            laser_ON_last = current_time
        else:
            laser.value = False
            laser_status = "OFF"
            laser_data.append([current_time, (current_time - initial_time).total_seconds(), laser_status])
            laser_OFF_last = current_time
    else:
        laser.value = False
        laser_status = "OFF"
        if laser_status == "ON":
            laser.value = False
            laser_status == "OFF"
            laser_OFF_last = current_time
            return

################################################################################
# Initialize Data Before Main Loop
################################################################################

initial_time = datetime.now()
laser.value = False

# Movement log
movement_data = [[initial_time, 0, "Stop"]]
laser_data = [[initial_time, 0, "OFF"]]
ledsync_data = [[initial_time, 0, "OFF"]]

# Centroid history (up to last 20)
centroid_history = []

# Movement memory
MOVE_MEMORY_SEC = 0.1
last_move_time = None

interval_time = 120.0 # seconds
# ChAT_947-1
# N1 = 59; N2 = 64; N3 = 56
# ChAT_947-2
#N1 = 61; N2 = 66; N3 = 56
# ChAT_947-3
N1 = 60; N2 = 57; N3 = 61
N_avg = round((N1+N2+N3)/3)
random_interval_1 = generate_intervals(interval_time, N_avg)
random_interval_2 = generate_intervals(interval_time, N_avg)
random_interval_3 = generate_intervals(interval_time, N_avg)

# Concatenate random intervals with adjusted times
adjusted_intervals_1 = [(start + interval_time * 1, end + interval_time * 1) for start, end in random_interval_1]
adjusted_intervals_2 = [(start + interval_time * 3, end + interval_time * 3) for start, end in random_interval_2]
adjusted_intervals_3 = [(start + interval_time * 5, end + interval_time * 5) for start, end in random_interval_3]

random_intervals = adjusted_intervals_1 + adjusted_intervals_2 + adjusted_intervals_3

################################################################################
# Blink 5 times before main loop
################################################################################

while (datetime.now() - initial_time).total_seconds() < 10:
    if ((datetime.now() - initial_time).total_seconds() * 1000) % 2000 < 1000:
        led.value = True
        ledsync_data.append([datetime.now(), (datetime.now() - initial_time).total_seconds(), "ON"])
    else:
        led.value = False
        ledsync_data.append([datetime.now(), (datetime.now() - initial_time).total_seconds(), "OFF"])

################################################################################
# Main Loop
################################################################################

window_name = "Closed Loop Optogenetic Inhibition (real-time) by CHJ - RANDOM Inhibition"
cv2.namedWindow(window_name, flags=cv2.WINDOW_NORMAL)
cv2.resizeWindow(window_name, round(width/2), round(height/2))

frame_count = 0
previous_dark_contour = None
state = "Stop"

while True:
    ret, frame = cap.read()
    frame_raw = frame.copy()
    if not ret:
        print("End of stream or cannot read frame.")
        break
    frame_count += 1

    current_time = datetime.now()
    elapsed_seconds = (current_time - initial_time).total_seconds()

    # Check if we've completed all mini-sessions
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
    movement_data.append([current_time, (current_time - initial_time).total_seconds(), state])

    # Laser control
    control_laser(state)

    # Overlay text
    # 1) Mini-session info
    cv2.putText(frame,
                f"Mini-session {current_mini_idx+1}/{total_mini_sessions}: {current_session_label}",
                (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2) # Cyan
    # 2) Elapsed time, frame count
    cv2.putText(frame,
                f"Time: {current_time.strftime('%H:%M:%S.%f')[:-3]} ({elapsed_seconds:.2f}s), Frame: {frame_count}",
                (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2) # White
    # 3) Movement info
    if state == "Move":
        text_color = (0, 0, 0)  # black
    else:
        text_color = (0, 0, 0)  # black
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

with open(log_ledsync, mode='w', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(ledsync_data)

print("Done. Logs saved and video output saved.")
