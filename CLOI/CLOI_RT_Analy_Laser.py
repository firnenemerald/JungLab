import pandas as pd
import matplotlib.pyplot as plt

session_dir = "E:/ChAT_947-1_Baseline_Random_250110_124243"
log_laser_dir = session_dir + "/Log/log_laser_" + session_dir[-13:] + ".csv"
log_ledsync_dir = session_dir + "/Log/log_ledsync_" + session_dir[-13:] + ".csv"
log_movement_dir = session_dir + "/Log/log_movement_" + session_dir[-13:] + ".csv"

log_laser = pd.read_csv(log_laser_dir, sep = ",", header = None, names = ["Time", "ExpTime", "LaserState"])
log_ledsync = pd.read_csv(log_ledsync_dir, sep = ",", header = None, names = ["Time", "ExpTime", "LedSyncState"])
log_movement = pd.read_csv(log_movement_dir, sep = ",", header = None, names = ["Time", "ExpTime", "MovementState"])

expTime_laser = log_laser["ExpTime"]
laserState = log_laser["LaserState"]
expTime_movement = log_movement["ExpTime"]
movementState = log_movement["MovementState"]

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))

# Subgraph 1: expTime_laser vs laserState
ax1.plot(expTime_laser, laserState, label='Laser State')
ax1.set_xlim(0, 720)
ax1.set_xlabel('Time (s)')
ax1.set_ylabel('Laser State')
ax1.set_title('Laser State over Time')
ax1.legend()

# Subgraph 2: expTime_movement vs movementState
ax2.plot(expTime_movement, movementState, label='Movement State', color='orange')
ax2.set_xlim(0, 720)
ax2.set_xlabel('Time (s)')
ax2.set_ylabel('Movement State')
ax2.set_title('Movement State over Time')
ax2.legend()

plt.tight_layout()
plt.show()