import pandas as pd
import matplotlib.pyplot as plt

session_dir = r"D:\CLOI_data\ChAT_967-2\ChAT_967-2_Baseline_Random_250312_124357"
log_laser_dir = session_dir + "/Log/log_laser_" + session_dir[-13:] + ".csv"

log_laser = pd.read_csv(log_laser_dir, sep=",", header=None, names=["Time", "ExpTime", "LaserState"])
expTime = log_laser["ExpTime"]
laserState = log_laser["LaserState"]

# Function to count clustered ONs
def count_clustered_ons(laser_state):
    count = 0
    previous_state = "OFF"
    for state in laser_state:
        if state == "ON" and previous_state == "OFF":
            count += 1
        previous_state = state
    return count

num_on = count_clustered_ons(laserState)
print(f"Number of 'ON's: {num_on}")

session_2_on = count_clustered_ons(laserState[(expTime >= 110) & (expTime <= 250)])
session_4_on = count_clustered_ons(laserState[(expTime >= 350) & (expTime <= 490)])
session_6_on = count_clustered_ons(laserState[(expTime >= 590) & (expTime <= 730)])

print(f"Number of 'ON's in session 2: {session_2_on}")
print(f"Number of 'ON's in session 4: {session_4_on}")
print(f"Number of 'ON's in session 6: {session_6_on}")

print(laserState)

plt.figure(figsize=(10, 6))
plt.plot(log_laser["ExpTime"], log_laser["LaserState"], marker='o')
plt.xlabel("ExpTime")
plt.ylabel("LaserState")
plt.title("ExpTime vs LaserState")
plt.grid(True)
plt.show()