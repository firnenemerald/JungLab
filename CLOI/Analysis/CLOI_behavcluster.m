function [Totdata] = CLOI_behavcluster(DLCTime, DLCnose, DLCcentre, DLCtail, ArenaSize)
% CLOI_behavcluster
%   Process “nose”, “center”, “tail” DLC data to detect:
%     • locomotion intervals (0.5–1σ rule)
%     • FWM intervals (those same raw locomotion intervals, minus any overlap with turns)
%     • STOP intervals (low‐level vs high‐level stop rule)
%     • TURN intervals (ipsiversive vs contraversive)
%   Then:
%     1) Shift everything so that first downsampled frame is zero
%     2) Print counts of “short” events exactly as in the original

%% 1) CALIBRATION (pixels → cm)
scaleFactor = 170 / ArenaSize;

nose_raw   = DLCnose(:,   1:2) * scaleFactor;  % [N×2]
centre_raw = DLCcentre(:, 1:2) * scaleFactor;  % [N×2]
tail_raw   = DLCtail(:,   1:2) * scaleFactor;  % [N×2]

nose_conf   = DLCnose(:,   3);  % [N×1]
centre_conf = DLCcentre(:, 3);  % [N×1]
tail_conf   = DLCtail(:,   3);  % [N×1]

rawFrames = DLCTime;  % [N×1] original frame IDs

%% 2) DOWNSAMPLE (30 Hz → 10 Hz by averaging each block of 3 frames)
framesPerBin = 3;
numRaw = size(nose_raw, 1);
numBins = floor(numRaw / framesPerBin);

nose_ds       = zeros(numBins, 2);
centre_ds     = zeros(numBins, 2);
tail_ds       = zeros(numBins, 2);
noseConf_ds   = zeros(numBins, 1);
centreConf_ds = zeros(numBins, 1);
tailConf_ds   = zeros(numBins, 1);
frame_ds      = zeros(numBins, 1);

for iBin = 1:numBins
    idxRange = (iBin-1)*framesPerBin + (1:framesPerBin);
    % average XYZ coords & confidences
    nose_ds(iBin, :)       = mean(nose_raw(idxRange, :),   1);
    centre_ds(iBin, :)     = mean(centre_raw(idxRange, :), 1);
    tail_ds(iBin, :)       = mean(tail_raw(idxRange, :),   1);
    noseConf_ds(iBin)      = mean(nose_conf(idxRange));
    centreConf_ds(iBin)    = mean(centre_conf(idxRange));
    tailConf_ds(iBin)      = mean(tail_conf(idxRange));
    % pick middle frame of each 3‐frame block
    frame_ds(iBin)         = rawFrames(idxRange(floor(framesPerBin/2)+1));
end

% If leftover frames exist (not exactly divisible by 3)
if mod(numRaw, framesPerBin) ~= 0
    leftoverIdx = numBins*framesPerBin + 1 : numRaw;
    nose_ds(end+1, :)       = mean(nose_raw(leftoverIdx, :),   1);
    centre_ds(end+1, :)     = mean(centre_raw(leftoverIdx, :), 1);
    tail_ds(end+1, :)       = mean(tail_raw(leftoverIdx, :),   1);
    noseConf_ds(end+1)      = mean(nose_conf(leftoverIdx));
    centreConf_ds(end+1)    = mean(centre_conf(leftoverIdx));
    tailConf_ds(end+1)      = mean(tail_conf(leftoverIdx));
    frame_ds(end+1)         = rawFrames(leftoverIdx(floor(length(leftoverIdx)/2)+1));
end

%% 3) KALMAN‐SMOOTH “centre” and “nose” (leave “tail” as is)
dt     = 0.1;    % time step at 10 Hz
q      = 0.01;   % process noise for Kalman
r_base = 1;     % base measurement noise
R_min  = 0.1;   % minimum R value

% smooth centre
[centre_x_s, centre_y_s] = fn_KalmanFilter(centre_ds, centreConf_ds, dt, q, r_base, R_min);
centre_ds(:,1) = centre_x_s;
centre_ds(:,2) = centre_y_s;

% smooth nose
[nose_x_s, nose_y_s] = fn_KalmanFilter(nose_ds, noseConf_ds, dt, q, r_base, R_min);
nose_ds(:,1) = nose_x_s;
nose_ds(:,2) = nose_y_s;

%% 4) VELOCITY (magnitude only)
nose_complex   = nose_ds(:,1)   + 1i * nose_ds(:,2);
centre_complex = centre_ds(:,1) + 1i * centre_ds(:,2);
tail_complex   = tail_ds(:,1)   + 1i * tail_ds(:,2);

nose_vel   = abs(diff(nose_complex));   % [M×1],  M = #downsampled–1
centre_vel = abs(diff(centre_complex)); % [M×1]
tail_vel   = abs(diff(tail_complex));   % [M×1]

%% 5) BODY ORIENTATION + ANGULAR VELOCITY
dx = nose_ds(:,1) - centre_ds(:,1);
dy = nose_ds(:,2) - centre_ds(:,2);
orient_raw = atan2(dy, dx);           % [M+1×1] radians
orient_unw = unwrap(orient_raw);

% “Smooth on the unit‐circle” by averaging real & imag
windowSz = 15;
ang_cpx = exp(1i * orient_raw);
ang_real_sm = movmean(real(ang_cpx), windowSz);
ang_imag_sm = movmean(imag(ang_cpx), windowSz);
orient_smooth = atan2(ang_imag_sm, ang_real_sm);

% raw angular velocity (rad/frame)
ang_vel_raw = diff(unwrap(orient_smooth));  % [M×1]

% further Gaussian smoothing
gaussWin   = 15;  
gaussSigma = 2;
tAxis = -(gaussWin-1)/2 : (gaussWin-1)/2;
gaussKern = exp(-(tAxis.^2)/(2*gaussSigma^2));
gaussKern = gaussKern / sum(gaussKern);

ang_vel = conv(ang_vel_raw, gaussKern, 'same');  % [M×1]

orient_deg = rad2deg(unwrap(orient_smooth));    % [M+1×1]

%% 6) TURN DETECTION (ipsiversive vs contraversive)
angv = ang_vel;  % alias

% define thresholds (same as original)
th_high = mean(abs(angv)) + 2 * std(abs(angv));
th_med  = mean(abs(angv)) + 0.8* std(abs(angv));

idx_high = find(abs(angv) >= th_high);
idx_med  = find(abs(angv) >= th_med);

frames_high = frame_ds(idx_high);
frames_med  = frame_ds(idx_med);

% group consecutive high‐frames into intervals (gap > 3 splits)
[startHigh, endHigh] = splitIntervals(frames_high, 3);
[startMed,  endMed]  = splitIntervals(frames_med,  3);

% keep only those [startMed(i), endMed(i)] that contain at least one high‐peak
valid_turnStarts = [];
valid_turnEnds   = [];
kCt = 1;
for i = 1:length(startMed)
    if any(frames_high > startMed(i) & frames_high < endMed(i))
        valid_turnStarts(kCt,1) = startMed(i);
        valid_turnEnds(kCt,1)   = endMed(i);
        kCt = kCt + 1;
    end
end

numT = size(valid_turnStarts,1);
turnAngle = zeros(numT,1);
for i = 1:numT
    idxS = find(frame_ds == valid_turnStarts(i));
    idxE = find(frame_ds == valid_turnEnds(i));
    turnAngle(i) = orient_deg(idxE) - orient_deg(idxS);
end

t_ipsi = [];  % ipsiversive
t_cont = [];  % contraversive
for i = 1:numT
    if turnAngle(i) > 0
        t_ipsi(end+1, :) = [valid_turnStarts(i), valid_turnEnds(i)];
    elseif turnAngle(i) < 0
        t_cont(end+1, :) = [valid_turnStarts(i), valid_turnEnds(i)];
    else
        % angle == 0 → ignore
    end
end

%% 7) LOCOMOTION DETECTION (0.5σ → 1σ rule)
centre_filt = fn_gaussian_RNN(fn_butterworth_RNN(centre_vel, 10,1,2), 20,4);
nose_filt   = fn_gaussian_RNN(fn_savgol_RNN(nose_vel, 3,21), 20,6);

centre_z = zscore(centre_filt);
nose_z   = zscore(nose_filt);

loc_th05 = mean(centre_z) + 0.5 * std(centre_z);
loc_th1  = mean(centre_z) + 1   * std(centre_z);

idx_loc05 = find( centre_z >= loc_th05 );
idx_loc1  = find( centre_z >= loc_th1 );

locFrames05 = frame_ds(idx_loc05);
locFrames1  = frame_ds(idx_loc1);

[rawLocStart05, rawLocEnd05] = splitIntervals(locFrames05, 3);
[rawLocStart1,  rawLocEnd1]  = splitIntervals(locFrames1,  3);

% raw “l_thlocstr1_05/l_thlocend1_05” as in original
rawLocStarts = [];
rawLocEnds   = [];
kCt = 1;
for i = 1:length(rawLocStart05)
    if any(locFrames1 > rawLocStart05(i) & locFrames1 < rawLocEnd05(i))
        rawLocStarts(kCt,1) = rawLocStart05(i);
        rawLocEnds(kCt,1)   = rawLocEnd05(i);
        kCt = kCt + 1;
    end
end

%% 8) STOP DETECTION (0.15σ vs 0.30σ rule)
stop_idx_lo = find( centre_z <= (mean(centre_z)-0.15*std(centre_z)) & ...
                   nose_z   <= (mean(nose_z)  -0.15*std(nose_z)) );
stop_idx_hi = find( centre_z <= (mean(centre_z)-0.30*std(centre_z)) & ...
                   nose_z   <= (mean(nose_z)  -0.30*std(nose_z)) );

stopFramesLo = frame_ds(stop_idx_lo);
stopFramesHi = frame_ds(stop_idx_hi);

[stopStartLo, stopEndLo] = splitIntervals(stopFramesLo, 3);
[stopStartHi, stopEndHi] = splitIntervals(stopFramesHi, 3);

stopStarts = [];
stopEnds   = [];
kCt = 1;
for i = 1:length(stopStartLo)
    if any(stopStartHi > stopStartLo(i) & stopStartHi < stopEndLo(i))
        stopStarts(kCt,1) = stopStartLo(i);
        stopEnds(kCt,1)   = stopEndLo(i);
        kCt = kCt + 1;
    end
end

%% 9) “FWM” = rawLoc minus any overlap with all turns (t_cont & t_ipsi)
allTurns = [t_cont; t_ipsi];  % [W×2], W = total # turns

turnStarts_all = allTurns(:,1);
turnEnds_all   = allTurns(:,2);

fLocStarts = [];
fLocEnds   = [];

for i = 1:size(rawLocStarts,1)
    Lstart = rawLocStarts(i);
    Lend   = rawLocEnds(i);
    intervals = [Lstart, Lend];
    
    overlapIdx = find((turnStarts_all <= Lend) & (turnEnds_all >= Lstart));
    if isempty(overlapIdx)
        % no overlap → keep [Lstart, Lend]
        fLocStarts(end+1) = Lstart;
        fLocEnds(end+1)   = Lend;
    else
        % subtract each overlapping turn
        overlaps = [ turnStarts_all(overlapIdx), turnEnds_all(overlapIdx) ];
        overlaps = sortrows(overlaps, 1);
        for j = 1:size(overlaps,1)
            sT = overlaps(j,1);
            eT = overlaps(j,2);
            newIntervals = [];
            for k2 = 1:size(intervals,1)
                iS = intervals(k2,1);
                iE = intervals(k2,2);
                if (iE < sT) || (iS > eT)
                    % no overlap, keep entire [iS, iE]
                    newIntervals = [newIntervals; iS, iE];
                else
                    % overlap exists, cut out [sT, eT]
                    if iS < sT
                        newIntervals = [newIntervals; iS,   sT-1];
                    end
                    if iE > eT
                        newIntervals = [newIntervals; eT+1, iE];
                    end
                end
            end
            intervals = newIntervals;
        end
        % keep whatever sub‐intervals remain
        for k2 = 1:size(intervals,1)
            sS = intervals(k2,1);
            sE = intervals(k2,2);
            if sS <= sE
                fLocStarts(end+1) = sS;
                fLocEnds(end+1)   = sE;
            end
        end
    end
end

% drop “zero‐length” or negative durations
validF = fLocEnds >= fLocStarts;
fLocStarts = fLocStarts(validF)';
fLocEnds   = fLocEnds(validF)';

%% 10) MERGE locomotion (rawLoc) + all turns into final locomotion/turn timeline
locEvents  = [rawLocStarts, rawLocEnds];
turnEvents = allTurns;  % [W×2]

allEvents = [locEvents; turnEvents];
allEvents = sortrows(allEvents, 1);

mergedEvents = [];
if ~isempty(allEvents)
    cS = allEvents(1,1);
    cE = allEvents(1,2);
    for i = 2:size(allEvents,1)
        nS = allEvents(i,1);
        nE = allEvents(i,2);
        if nS <= (cE + 3)  % allow gap ≤ 3 to merge
            cE = max(cE, nE);
        else
            mergedEvents = [mergedEvents; cS, cE];
            cS = nS;
            cE = nE;
        end
    end
    mergedEvents = [mergedEvents; cS, cE];
end

MergedLocStarts = mergedEvents(:,1);
MergedLocEnds   = mergedEvents(:,2);

%% 11) SHIFT everything so first downsampled frame → 0
frameOffset = frame_ds(1) - 1;

MergedLocStarts_shifted = MergedLocStarts - frameOffset;
MergedLocEnds_shifted   = MergedLocEnds   - frameOffset;

fLocStarts_shifted = fLocStarts - frameOffset;
fLocEnds_shifted   = fLocEnds   - frameOffset;

stopStarts_shifted = stopStarts - frameOffset;
stopEnds_shifted   = stopEnds   - frameOffset;

t_ipsi_shifted = t_ipsi - frameOffset;
t_cont_shifted = t_cont - frameOffset;

downsampledFrames = frame_ds - frameOffset;

%% 12) COUNT “SHORT” EVENTS exactly as original did:
%  • locomotion short:    (MergedLocEnds – MergedLocStarts) ≤ 29
%  • FWM short:           (fLocEnds – fLocStarts) ≤ 25
%  • STOP short:          (stopEnds – stopStarts) ≤ 29

% LOCOMOTION short
locDur = MergedLocEnds_shifted - MergedLocStarts_shifted;
shortLocIdx = locDur <= 29;
%fprintf('number of LOCOMOTION events shorter than 29 frames: %d\n', sum(shortLocIdx));

% FWM short
fwmDur = fLocEnds_shifted - fLocStarts_shifted;
shortFwmIdx = fwmDur <= 25;
%fprintf('number of FWM events shorter than 25 frames: %d\n', sum(shortFwmIdx));

% STOP short
stopDur    = stopEnds_shifted - stopStarts_shifted;
shortStopIdx = stopDur <= 29;
%fprintf('number of STOP events shorter than 29 frames: %d\n\n', sum(shortStopIdx));

%% 13) PACKAGE every output into Totdata
Totdata = struct();

% downsampled positions & confidences
Totdata.nose_down       = nose_ds;
Totdata.centre_down     = centre_ds;
Totdata.tail_down       = tail_ds;
Totdata.nose_confout    = noseConf_ds;
Totdata.centre_confout  = centreConf_ds;
Totdata.tail_confout    = tailConf_ds;

% downsampled + shifted frame IDs
Totdata.frames_downsampled = downsampledFrames;

% velocities
Totdata.nose_velocity   = nose_vel;
Totdata.centre_velocity = centre_vel;
Totdata.tail_velocity   = tail_vel;

% body orientation & angular velocity
Totdata.orientation_deg  = orient_deg;
Totdata.angular_velocity = ang_vel;

% final event arrays (shifted)
Totdata.turn_ipsiversive   = t_ipsi_shifted;
Totdata.turn_contraversive = t_cont_shifted;
Totdata.locomotion_events  = [MergedLocStarts_shifted, MergedLocEnds_shifted];
Totdata.FWM_events         = [fLocStarts_shifted, fLocEnds_shifted];
Totdata.stop_events        = [stopStarts_shifted, stopEnds_shifted];

end


%% ------------------------------------------------------------------------
function [startFrames, endFrames] = splitIntervals(frameList, gapThreshold)
% Given a sorted vector of “frameList”, group them into intervals so that
% consecutive frames that differ by ≤ gapThreshold stay together.
% If diff > gapThreshold, we begin a new interval.
%
% Outputs startFrames and endFrames as N×1 vectors.

if isempty(frameList)
    startFrames = [];
    endFrames   = [];
    return;
end

diffFrames = [Inf; diff(frameList)];
newGroupIdx = find(diffFrames > gapThreshold);
numGroups   = length(newGroupIdx);

startFrames = zeros(numGroups, 1);
endFrames   = zeros(numGroups, 1);

for i = 1:numGroups
    idxS = newGroupIdx(i);
    if i < numGroups
        idxE = newGroupIdx(i+1) - 1;
    else
        idxE = length(frameList);
    end
    startFrames(i) = frameList(idxS);
    endFrames(i)   = frameList(idxE);
end
end
