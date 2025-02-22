import random

def generate_intervals(total_time, N, interval = 1.5):
    if interval * N > total_time:
        raise ValueError("The total duration of intervals exceeds total time")
    
    random_starts = sorted(random.uniform(0, total_time - N * interval) for _ in range(N))
    random_intervals = [(start + i * interval, start + (i+1) * interval) for i, start in enumerate(random_starts)]
    return random_intervals

interval_time = 120.0 # seconds
# ChAT_947-1
N1 = 59; N2 = 53; N3 = 61
# ChAT_947-2
#N1 = 66, N2 = 60, N3 = 64
# ChAT_947-3
#N1 = 48, N2 = 56, N3 = 63
random_interval_1 = generate_intervals(interval_time, N1)
random_interval_2 = generate_intervals(interval_time, N2)
random_interval_3 = generate_intervals(interval_time, N3)

# Concatenate random intervals with adjusted times
adjusted_intervals_1 = [(start + interval_time * 1, end + interval_time * 1) for start, end in random_interval_1]
adjusted_intervals_2 = [(start + interval_time * 3, end + interval_time * 3) for start, end in random_interval_2]
adjusted_intervals_3 = [(start + interval_time * 5, end + interval_time * 5) for start, end in random_interval_3]

random_intervals = adjusted_intervals_1 + adjusted_intervals_2 + adjusted_intervals_3
print(random_intervals)
