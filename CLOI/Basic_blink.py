import time
import board
import digitalio
from datetime import datetime

led = digitalio.DigitalInOut(board.C0)
led.direction = digitalio.Direction.OUTPUT

start_time = datetime.now()

while True:
    current_time = datetime.now()
    if ((current_time - start_time).total_seconds() * 1000) % 400 < 200:
        led.value = True
    else:
        led.value = False