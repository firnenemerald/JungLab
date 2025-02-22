import time
import board
import digitalio
import os
import csv
from datetime import datetime

# Create the log directory if it does not exist
log_dir = "./Log"
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

# Initialize the LED
led = digitalio.DigitalInOut(board.C0)
led.direction = digitalio.Direction.OUTPUT

# Function to perform a blinking session
def blink_session(on_time, off_time, pulses):
    log_data = []
    for _ in range(pulses):
        led.value = True
        log_data.append((datetime.now().strftime('%y-%m-%d_%H-%M-%S-%f'), 'ON'))
        time.sleep(on_time)
        led.value = False
        log_data.append((datetime.now().strftime('%y-%m-%d_%H-%M-%S-%f'), 'OFF'))
        time.sleep(off_time)
    return log_data

# Manually set the parameters for the session
on_time = 1.0  # Set the ON time (in seconds)
off_time = 1.0  # Set the OFF time (in seconds)
pulses = 30  # Set the number of pulses

# Perform the session
log_data = blink_session(on_time, off_time, pulses)

# Generate the log file name with the current date and on_time
timestamp = datetime.now().strftime('%y%m%d')
log_file = os.path.join(log_dir, f"blink_log_{timestamp}_{on_time}.csv")

# Save the log data to a CSV file
with open(log_file, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(["Timestamp", "State"])
    writer.writerows(log_data)