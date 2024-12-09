function [Totdata] = fn_behavcluster_OF_v2(DLCArray, ArenaSize)
%% Extract Raw Coordinates and Confidence Scores

% Assuming DLCArray columns are as follows:
% Column 1: Frame number
% Columns 2-4: Nose x, y, confidence
% Columns 5-7: Center x, y, confidence
% Columns 8-10: Tail x, y, confidence

% Extract raw coordinates
nose_raw = DLCArray(:, 2:3);
centre_raw = DLCArray(:, 5:6);
tail_raw = DLCArray(:, 8:9);

% Apply calibration to raw coordinates
calib = 700 / ArenaSize; % Adjust 150 to your standard reference dimension

% Scale the raw coordinates
nose_raw = nose_raw * calib;
centre_raw = centre_raw * calib;
tail_raw = tail_raw * calib;

% Extract confidence scores
nose_confidence = DLCArray(:, 4);
centre_confidence = DLCArray(:, 7);
tail_confidence = DLCArray(:, 10);

% Frame numbers
DLCframe_raw = DLCArray(:, 1);

%% Downsampling

% Downsampling parameters
frames_to_combine = 3; % To downsample from 30Hz to 10Hz
numFrames = size(nose_raw, 1);
numGroups = floor(numFrames / frames_to_combine);

% Preallocate downsampled coordinate and confidence matrices
nose_ds = zeros(numGroups, 2);
centre_ds = zeros(numGroups, 2);
tail_ds = zeros(numGroups, 2);
nose_conf_ds = zeros(numGroups, 1);
centre_conf_ds = zeros(numGroups, 1);
tail_conf_ds = zeros(numGroups, 1);
DLCframe_ds = zeros(numGroups, 1);

% Loop through and average every 'frames_to_combine' frames
for idx = 1:numGroups
    frame_indices = (idx - 1) * frames_to_combine + (1:frames_to_combine);
    
    % Average coordinates
    nose_ds(idx, :) = mean(nose_raw(frame_indices, :), 1);
    centre_ds(idx, :) = mean(centre_raw(frame_indices, :), 1);
    tail_ds(idx, :) = mean(tail_raw(frame_indices, :), 1);
    
    % Average confidence scores
    nose_conf_ds(idx) = mean(nose_confidence(frame_indices));
    centre_conf_ds(idx) = mean(centre_confidence(frame_indices));
    tail_conf_ds(idx) = mean(tail_confidence(frame_indices));
    
    % Frame numbers (take the middle frame)
    DLCframe_ds(idx) = DLCframe_raw(frame_indices(floor(frames_to_combine / 2) + 1));
end

% Handle remaining frames if total number is not divisible by 'frames_to_combine'
if mod(numFrames, frames_to_combine) ~= 0
    remaining_indices = numGroups * frames_to_combine + 1:numFrames;
    nose_ds(end + 1, :) = mean(nose_raw(remaining_indices, :), 1);
    centre_ds(end + 1, :) = mean(centre_raw(remaining_indices, :), 1);
    tail_ds(end + 1, :) = mean(tail_raw(remaining_indices, :), 1);
    nose_conf_ds(end + 1) = mean(nose_confidence(remaining_indices));
    centre_conf_ds(end + 1) = mean(centre_confidence(remaining_indices));
    tail_conf_ds(end + 1) = mean(tail_confidence(remaining_indices));
    DLCframe_ds(end + 1) = DLCframe_raw(remaining_indices(floor(length(remaining_indices) / 2) + 1));
end

%% Kalman Filter for coordinates

% Time step (after downsampling to 10 Hz)
dt = 0.1;

% Process Noise Covariance (Adjust 'q' based on expected motion variability)
q = 0.01;

% Base Measurement Noise Covariance
r_base = 1;

% Minimum Measurement Noise Covariance (to prevent R from being too low)
R_min = 0.1; % Adjust this minimum value as needed based on your data

[centre_smoothed_x, centre_smoothed_y] = fn_KalmanFilter(centre_ds, centre_conf_ds, dt, q, r_base, R_min);
centre_ds(:, 1) = centre_smoothed_x;
centre_ds(:, 2) = centre_smoothed_y;

[nose_smoothed_x, nose_smoothed_y] = fn_KalmanFilter(nose_ds, nose_conf_ds, dt, q, r_base, R_min);
nose_ds(:, 1) = nose_smoothed_x;
nose_ds(:, 2) = nose_smoothed_y;

%% Now calculate the velocity from the downsampled coordinates

% NCT coordinate
nose_coord = nose_ds(:,1) + 1i*nose_ds(:,2);    
centre_coord = centre_ds(:,1) + 1i*centre_ds(:,2);  
tail_coord = tail_ds(:,1) + 1i*tail_ds(:,2);  

% NCT coordinate (abs)
nose_coord_abs = abs(nose_coord);
centre_coord_abs = abs(centre_coord);
tail_coord_abs = abs(tail_coord);

% NCT velocity (abs)
nose_v = abs(diff(nose_coord));
centre_v = abs(diff(centre_coord));
tail_v = abs(diff(tail_coord));

%% turn parameters

% Body Orientation (Nose-Center Vector Angle)
vectorX = nose_ds(:,1) - centre_ds(:,1);
vectorY = nose_ds(:,2) - centre_ds(:,2);
body_orientation = atan2(vectorY, vectorX);
body_orientation_uw = unwrap(body_orientation);

% Smoothing parameters (adjust as needed)
window_size = 15; % Window size for moving average

% Convert unwrapped body orientation angles to complex numbers on the unit circle
angles_complex = exp(1i * body_orientation);

% Separate real and imaginary parts
real_part = real(angles_complex);
imag_part = imag(angles_complex);

% Apply moving average to the real and imaginary parts separately
real_part_smoothed = movmean(real_part, window_size);
imag_part_smoothed = movmean(imag_part, window_size);

% Recompute the smoothed body orientation angles from the smoothed real and imaginary parts
body_orientation_smoothed = atan2(imag_part_smoothed, real_part_smoothed);

% Compute the angular velocity from the smoothed body orientation
angular_velocity = diff(unwrap(body_orientation_smoothed));

% Optional: Smooth the angular velocity further if necessary
% Using moving average
% angular_velocity_smoothed = movmean(angular_velocity, window_size);

% Alternatively, apply Gaussian smoothing to the angular velocity
% Define Gaussian kernel parameters
gaussian_window_size = 15; % Must be odd
gaussian_sigma = 2;

% Create the Gaussian kernel
t = -(gaussian_window_size - 1)/2 : (gaussian_window_size - 1)/2;
gauss_kernel = exp(-(t.^2) / (2 * gaussian_sigma^2));
gauss_kernel = gauss_kernel / sum(gauss_kernel); % Normalize the kernel

% Apply convolution to smooth the angular velocity
angular_velocity_smoothed = conv(angular_velocity, gauss_kernel, 'same');

%% Turn detection

angle_uw=rad2deg(unwrap(body_orientation_smoothed));
anglev=angular_velocity_smoothed;

t_th2=mean(abs(angular_velocity_smoothed))+2*std(abs(angular_velocity_smoothed));
t_th08=mean(abs(angular_velocity_smoothed))+0.8*std(abs(angular_velocity_smoothed));

t_ind2 = DLCframe_ds(find(abs(anglev) >= t_th2));     
t_end2 = t_ind2(find(diff(t_ind2)>3));                    
t_end2 = [t_end2(1:end);t_ind2(end)];
t_str2 = t_ind2(find(diff(t_ind2)>3)+1);               
t_str2 = [t_ind2(1);t_str2(1:end)];               

t_ind08 = DLCframe_ds(find(abs(anglev) >= t_th08));
t_end08 = t_ind08(find(diff(t_ind08)>3));
t_end08 = [t_end08(1:end);t_ind08(end)];
t_str08 = t_ind08(find(diff(t_ind08)>3)+1);
t_str08 = [t_ind08(1);t_str08(1:end)];

k=1;
for i=1:length(t_str08)
   temp = find(t_str2 > t_str08(i) & t_str2 < t_end08(i));
   if isempty(temp) < 1;    
   t_str2_08(k,1) = t_str08(i);  % 
   t_end2_08(k,1) = t_end08(i);  %
   k=k+1;
   end
   temp=[];
end

for i=1:length(t_str2_08)
    strAngle=angle_uw(find(DLCframe_ds==t_str2_08(i)));
    endAngle=angle_uw(find(DLCframe_ds==t_end2_08(i)));
    turnAngle(i,1)=endAngle-strAngle;
end

%
t_nc=[t_str2_08, t_end2_08, turnAngle];

t_cont=[];t_ipsi=[];
for i=1:length(t_str2_08)
    if turnAngle(i,1) < 0
        t_cont(end+1,:)=[t_str2_08(i,1),t_end2_08(i,1)];
    else if turnAngle(i,1) > 0
        t_ipsi(end+1,:)=[t_str2_08(i,1),t_end2_08(i,1)];
    else disp('turn angle change is zero\n')
    end
    end
end

%% test run

Cvhigh = fn_gaussian_RNN(fn_butterworth_RNN(centre_v, 10, 1, 2), 20, 4);
Nvhigh = fn_gaussian_RNN(fn_savgol_RNN(nose_v, 3, 21), 20, 6);
Cvhigh_z = zscore(Cvhigh);
Nvhigh_z = zscore(Nvhigh);

%% classification

% locomotion 
l_thmax05 = mean(Cvhigh_z) + 0.5*std(Cvhigh_z);
l_thmax1 = mean(Cvhigh_z) + 1*std(Cvhigh_z);
l_thmax15 = mean(Cvhigh_z) + 1.5*std(Cvhigh_z);
l_thmax2 = mean(Cvhigh_z) + 2*std(Cvhigh_z);

l_thmax05n = mean(Nvhigh_z) + 0.5*std(Nvhigh_z);
l_thmax1n = mean(Nvhigh_z) + 1*std(Nvhigh_z);
l_thmax15n = mean(Nvhigh_z) + 1.5*std(Nvhigh_z);
l_thmax2n = mean(Nvhigh_z) + 2*std(Nvhigh_z);

%idx
l_thlocind05 = DLCframe_ds(find(Cvhigh_z >=l_thmax05));
l_thlocend05 = l_thlocind05(find(diff(l_thlocind05)>3));
l_thlocend05 = [l_thlocend05(1:end); l_thlocind05(end)];
l_thlocstr05 = l_thlocind05(find(diff(l_thlocind05)>3)+1);
l_thlocstr05 = [l_thlocind05(1); l_thlocstr05(1:end)];

l_thlocind1 = DLCframe_ds(find(Cvhigh_z >=l_thmax1));
l_thlocend1 = l_thlocind1(find(diff(l_thlocind1)>3)); 
l_thlocend1 = [l_thlocend1(1:end); l_thlocind1(end)];
l_thlocstr1 = l_thlocind1(find(diff(l_thlocind1)>3)+1);
l_thlocstr1 = [l_thlocind1(1); l_thlocstr1(1:end)];
 
k=1;
for i=1:length(l_thlocstr05)
   temp = find(l_thlocstr1 > l_thlocstr05(i) & l_thlocstr1 < l_thlocend05(i));
   if isempty(temp) < 1;    
   l_thlocstr1_05(k,1) = l_thlocstr05(i);  % 
   l_thlocend1_05(k,1) = l_thlocend05(i);  %
   k=k+1;
   end
   temp=[];
end

% stop
s_thstopind_015 = DLCframe_ds(find(Cvhigh_z <= (mean(Cvhigh_z)-0.15*std(Cvhigh_z)) & Nvhigh_z <=(mean(Nvhigh_z)-0.15*std(Nvhigh_z))));
s_thstopend_015 = s_thstopind_015(find(diff(s_thstopind_015)>3));
s_thstopend_015 = [s_thstopend_015(1:end); s_thstopind_015(end)];
s_thstopstr_015 = s_thstopind_015(find(diff(s_thstopind_015)>3)+1);
s_thstopstr_015 = [s_thstopind_015(1);s_thstopstr_015(1:end)];

s_thstopind_03 = DLCframe_ds(find(Cvhigh_z <= (mean(Cvhigh_z)-0.3*std(Cvhigh_z)) & Nvhigh_z <=(mean(Nvhigh_z)-0.3*std(Nvhigh_z))));
s_thstopend_03 = s_thstopind_03(find(diff(s_thstopind_03)>3));
s_thstopend_03 = [s_thstopend_03(1:end); s_thstopind_03(end)];
s_thstopstr_03 = s_thstopind_03(find(diff(s_thstopind_03)>3)+1);
s_thstopstr_03 = [s_thstopind_03(1);s_thstopstr_03(1:end)];


k=1;
for i=1:length(s_thstopstr_015)
   temp = find(s_thstopstr_03 > s_thstopstr_015(i) & s_thstopstr_03 < s_thstopend_015(i));
   if isempty(temp) < 1;    
   s_thstopstr03_015(k,1) = s_thstopstr_015(i);  % 
   s_thstopend03_015(k,1) = s_thstopend_015(i);  %
   k=k+1;
   end
   temp=[];
end

%% Remove Overlapping Frames Between Turns and Locomotion

% Initialize new lists for adjusted locomotion events
new_locomotion_starts = [];
new_locomotion_ends = [];

% Turn events
turn_starts = t_nc(:, 1);
turn_ends = t_nc(:, 2);

% Loop over each locomotion event
for i = 1:length(l_thlocstr1_05)
    loc_start = l_thlocstr1_05(i);
    loc_end = l_thlocend1_05(i);
    
    % Initialize intervals to process for this locomotion event
    intervals_to_process = [loc_start, loc_end];
    
    % Find all turn events that overlap with this locomotion event
    % A turn overlaps if its start is less than loc_end and its end is greater than loc_start
    overlapping_turns_idx = find((turn_starts <= loc_end) & (turn_ends >= loc_start));
    
    if isempty(overlapping_turns_idx)
        % No overlapping turns, keep the locomotion event as is
        new_locomotion_starts(end+1) = loc_start;
        new_locomotion_ends(end+1) = loc_end;
    else
        % There are overlapping turns, need to adjust locomotion event
        % Collect all overlapping turn intervals
        overlapping_turns = [turn_starts(overlapping_turns_idx), turn_ends(overlapping_turns_idx)];
        
        % Sort overlapping turns by start time
        overlapping_turns = sortrows(overlapping_turns, 1);
        
        % Subtract overlapping turn intervals from the locomotion interval
        for j = 1:size(overlapping_turns, 1)
            sub_start = overlapping_turns(j, 1);
            sub_end = overlapping_turns(j, 2);
            new_intervals = [];
            
            for k = 1:size(intervals_to_process, 1)
                int_start = intervals_to_process(k, 1);
                int_end = intervals_to_process(k, 2);
                
                % Check if there is overlap
                if (int_end < sub_start) || (int_start > sub_end)
                    % No overlap, keep the interval
                    new_intervals = [new_intervals; int_start, int_end];
                else
                    % Overlapping interval, need to adjust
                    if int_start < sub_start
                        % Add interval before overlap
                        new_intervals = [new_intervals; int_start, sub_start - 1];
                    end
                    if int_end > sub_end
                        % Add interval after overlap
                        new_intervals = [new_intervals; sub_end + 1, int_end];
                    end
                end
            end
            % Update intervals to process with new intervals
            intervals_to_process = new_intervals;
        end
        
        % Add adjusted intervals to the new locomotion events list
        for k = 1:size(intervals_to_process, 1)
            seg_start = intervals_to_process(k, 1);
            seg_end = intervals_to_process(k, 2);
            % Ensure that start <= end
            if seg_start <= seg_end
                new_locomotion_starts(end+1) = seg_start;
                new_locomotion_ends(end+1) = seg_end;
            end
        end
    end
end

% Update locomotion events with the adjusted events
f_thlocstr1_05 = new_locomotion_starts';
f_thlocend1_05 = new_locomotion_ends';

% Remove any locomotion events with zero or negative duration
valid_idx = f_thlocend1_05 >= f_thlocstr1_05;
f_thlocstr1_05 = f_thlocstr1_05(valid_idx);
f_thlocend1_05 = f_thlocend1_05(valid_idx);

%% Combine Locomotion and Turn Events

% Initialize an empty list for combined events
combined_events = [];

% Get all event start and end frames
locomotion_events = [l_thlocstr1_05, l_thlocend1_05];
turn_events = [t_nc(:, 1), t_nc(:, 2)];

% Combine locomotion and turn events into a single list
all_events = [locomotion_events; turn_events];

% Sort all events by their start times
all_events = sortrows(all_events, 1);

% Merge overlapping or adjacent events
if ~isempty(all_events)
    % Initialize the first event
    current_start = all_events(1, 1);
    current_end = all_events(1, 2);

    for i = 2:size(all_events, 1)
        next_start = all_events(i, 1);
        next_end = all_events(i, 2);

        if next_start <= current_end + 3 % Adjust '+1' to define adjacency
            % Events overlap or are adjacent, extend the current event
            current_end = max(current_end, next_end);
        else
            % No overlap, save the current event and start a new one
            combined_events = [combined_events; current_start, current_end];
            current_start = next_start;
            current_end = next_end;
        end
    end

    % Add the last event
    combined_events = [combined_events; current_start, current_end];
end

l_thlocstr1_05=combined_events(:,1);
l_thlocend1_05=combined_events(:,2);

%% Post-processing

syncframe=DLCframe_ds(1)-1;
l_thlocstr1_05=l_thlocstr1_05-syncframe;
l_thlocend1_05=l_thlocend1_05-syncframe;
s_thstopstr03_015=s_thstopstr03_015-syncframe;
s_thstopend03_015=s_thstopend03_015-syncframe;
f_thlocstr1_05=f_thlocstr1_05-syncframe;
f_thlocend1_05=f_thlocend1_05-syncframe;
t_ipsi=t_ipsi-syncframe;
t_cont=t_cont-syncframe;
DLCframe_ds=DLCframe_ds-syncframe;

l_thlocdur1_05 = l_thlocend1_05-l_thlocstr1_05;
l_thlocstr1_05_short = l_thlocstr1_05(l_thlocdur1_05<=29);
l_thlocend1_05_short = l_thlocend1_05(l_thlocdur1_05<=29);
l_thlocstr1_05 = l_thlocstr1_05(l_thlocdur1_05>29);
l_thlocend1_05 = l_thlocend1_05(l_thlocdur1_05>29);
fprintf('number of LOCOMOTION events shorter than 29 frames: %d\n',size(l_thlocstr1_05_short,1));

f_thlocdur1_05 = f_thlocend1_05-f_thlocstr1_05;
f_thlocstr1_05_short = f_thlocstr1_05(f_thlocdur1_05<=25);
f_thlocend1_05_short = f_thlocend1_05(f_thlocdur1_05<=25);
f_thlocstr1_05 = f_thlocstr1_05(f_thlocdur1_05>25);
f_thlocend1_05 = f_thlocend1_05(f_thlocdur1_05>25);
fprintf('number of FWM events shorter than 25 frames: %d\n',size(f_thlocstr1_05_short,1));

s_thstopdur = s_thstopend03_015-s_thstopstr03_015;
s_thstopstr03_015_short = s_thstopstr03_015(s_thstopdur<=29);
s_thstopend03_015_short = s_thstopend03_015(s_thstopdur<=29);
s_thstopstr03_015 = s_thstopstr03_015(s_thstopdur>29);
s_thstopend03_015 = s_thstopend03_015(s_thstopdur>29);
fprintf('number of STOP events shorter than 29 frames: %d\n\n',size(s_thstopstr03_015_short,1));


%% store
clear('temp','i','k')
vars = who;
Totdata = struct();

for i = 1:length(vars)
    Totdata.(vars{i}) = eval(vars{i});
end

end