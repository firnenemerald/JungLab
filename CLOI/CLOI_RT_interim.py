import pandas as pd

# Count clustered "ON" states
def count_clustered_ons(laser_states):
    clustered_on_count = 0
    previous_state = "OFF"
    for state in laser_states:
        if state == "ON" and previous_state == "OFF":
            clustered_on_count += 1
        previous_state = state
    return clustered_on_count

def MS_clustered_ons(session_dir):
    log_laser_dir = session_dir + "/Log/log_laser_" + session_dir[-13:] + ".csv"
    log_laser = pd.read_csv(log_laser_dir, sep = ",", header = None, names = ["Time", "ExpTime", "LaserState"])
    expTime = log_laser["ExpTime"]
    laserState = log_laser["LaserState"]

    sessions = {
        "session_2": (110, 250),
        "session_4": (350, 490),
        "session_6": (590, 730)
    }

    counts = []
    for session, (start, end) in sessions.items():
        session_laser_states = log_laser[(expTime >= start) & (expTime <= end)]["LaserState"]
        clustered_on_count = count_clustered_ons(session_laser_states)
        counts.append(clustered_on_count)
    return tuple(counts)