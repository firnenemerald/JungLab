import time
import board
import digitalio
from datetime import datetime

# Laser control and initialization
laser = digitalio.DigitalInOut(board.C0)
laser.direction = digitalio.Direction.OUTPUT
laser_status = "OFF"  # Initialize laser status
laser_data = [[datetime.now(), "OFF"]] # Initialize laser data
laser_ON_last = None # Initialize last laser ON time
laser_OFF_last = datetime.now() # Initialize last laser OFF time

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
    elif status == "Stop" and laser_ON_last is None: # Before first time turning the laser ON
        return
    elif ((current_time - laser_ON_last).total_seconds() * 1000) < (X * 1000): # Keep the laser ON for X seconds
        if laser_status == "OFF":
            laser.value = True
            laser_status = "ON"
            return
        else:
            laser_status = "ON"
            return
    elif (((current_time - laser_ON_last).total_seconds() * 1000) > (X * 1000)) and (((current_time - laser_ON_last).total_seconds() * 1000) < ((X+Y) * 1000)): # Turn laser OFF after X seconds for Y seconds
        if laser_status == "ON":
            laser.value = False
            laser_status = "OFF"
            laser_OFF_last = current_time
            laser_data.append([current_time, laser_status])
            return
        else:
            laser_status = "OFF"
            return
    elif status == "Move" and ((current_time - laser_ON_last).total_seconds() * 1000) > ((X+Y) * 1000):
        laser.value = True
        laser_status = "ON"
        laser_ON_last = current_time
        laser_data.append([current_time, laser_status])
        return

start_time = datetime.now()
while True:
    # Hypothetical 3 seconds movement and 3 seconds stop
    current_time = datetime.now()
    time_difference = (current_time - start_time).total_seconds() * 1000
    if time_difference % 6000 < 3000:
        control_laser("Move")
        print("Time (s): ", round(time_difference)/1000, "Movement: Move, Laser Status: ", laser_status)
    else:
        control_laser("Stop")
        print("Time (s): ", round(time_difference)/1000, "Movement: Stop, Laser Status: ", laser_status)

    # Terminate the loop after 30 seconds
    if (current_time - start_time).total_seconds() > 30:
        break