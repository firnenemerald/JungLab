%% CLOI Open Field Analysis Main Script

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

% Clear workspace
clear
close all

% Constants
CENTER = [1400, 700]; % Center of the open field arena (in pixels)
RADIUS = 380; % Radius of the center maze area (in pixels)

% Specify default directory and get session data
defaultDir = "C:\Users\chanh\Downloads\CLOI_data_mini";
sessionData = CLOI_GetSessionData(defaultDir);

% Find indices of sessions with presets or regex patterns
sessionIndices = CLOI_GetSessionIndices(sessionData, 'preset1');
fprintf('Found %d sessions matching the pattern.\n', length(sessionIndices));

%{

%% Generate analysis data for the specified sessions

% Preallocate a struct to store analysis data
analysisData = struct('sessionName', {}, ...
    'frameNum', {}, ...
    'eossomTimes', {}, ...
    'eossomNum', {}, ...
    'velocityPeaks', {}, ...
    'velocityPeakNums', {}, ...
    'velocityMax', {}, ...
    'velocityMean', {}, ...
    'angVelPeaks', {}, ...
    'angVelPeakNums', {}, ...
    'angVelMax', {}, ...
    'angVelMean', {}, ...
    'turnIpsiTime', {}, ...
    'turnIpsiNum', {}, ...
    'turnContraTime', {}, ...
    'turnContraNum', {}, ...
    'turnTotalTime', {}, ...
    'turnTotalNum', {}, ...
    'centerMazeTime', {}, ...
    'centerMazeDist', {});

% Iterate through each session index
for idx = 1:length(sessionIndices)
    analysisDataIdx = length(analysisData)+1;
    sessIndex = sessionIndices(idx);
    fprintf('Processing session %d: %s\n', sessIndex, sessionData(sessIndex).sessionName);

    % Get session data
    sessName = sessionData(sessIndex).sessionName;

    % Get DLC data
    DLCframe = sessionData(sessIndex).dlcTime;
    DLCnose = [sessionData(sessIndex).dlcCoordHeadX, sessionData(sessIndex).dlcCoordHeadY, sessionData(sessIndex).dlcCoordHeadConf];
    DLCcentre = [sessionData(sessIndex).dlcCoordBodyX, sessionData(sessIndex).dlcCoordBodyY, sessionData(sessIndex).dlcCoordBodyConf];
    DLCtail = [sessionData(sessIndex).dlcCoordTailX, sessionData(sessIndex).dlcCoordTailY, sessionData(sessIndex).dlcCoordTailConf];

    % Get Mv and Ls data
    MvTime = sessionData(sessIndex).mvTime;
    MvState = sessionData(sessIndex).mvState;
    LsTime = sessionData(sessIndex).lsTime;
    LsState = sessionData(sessIndex).lsState;

    % Behavioral clustering
    behavData = CLOI_behavcluster(DLCframe, DLCnose, DLCcentre, DLCtail, 120);

    % Get DLC clustered data
    frameDownDLC = behavData.frames_downsampled;
    headPosDLC = behavData.nose_down;
    bodyPosDLC = behavData.centre_down;
    headVelDLC = behavData.nose_velocity;
    bodyVelDLC = behavData.centre_velocity;
    orientationDLC = behavData.orientation_deg;
    angularVelDLC = behavData.angular_velocity;
    turnIpsiEventDLC = behavData.turn_ipsiversive;
    turnContraEventDLC = behavData.turn_contraversive;
    locoEventDLC = behavData.locomotion_events;
    stopEventDLC = behavData.stop_events;

    % Get Minisession bool values in original frames
    boolOriFrameMS = cell(6, 1);
    for i = 1:6
        boolOriFrameMS{i} = (MvTime > (i-1)*120.0 & MvTime < i*120.0);
    end

    % Get Minisession range in downsampled frames
    rangeDownFrameMS = cell(6, 1);
    range = find(diff(boolOriFrameMS{1}) ~= 0);
    rangeDownFrameMS{1} = [1, range(1)];
    for i = 2:5
        range = find(diff(boolOriFrameMS{i}) ~= 0);
        rangeDownFrameMS{i} = [range(1)+1, range(2)];
    end
    range = find(diff(boolOriFrameMS{6}) ~= 0);
    rangeDownFrameMS{6} = [range(1)+1, length(boolOriFrameMS{6})];

    % Get Minisession bool values in downsampled frames
    boolDownFrameMS = cell(6, 1);
    for i = 1:6
        boolDownFrameMS{i} = (frameDownDLC >= rangeDownFrameMS{i}(1) & frameDownDLC <= rangeDownFrameMS{i}(2));
    end

    frameNum = cell(6, 1);
    eossomTimes = cell(6, 1);
    eossomNum = cell(6, 1);
    velocityPeaks = cell(6, 1);
    velocityPeakNums = cell(6, 1);
    velocityMax = cell(6, 1);
    velocityMean = cell(6, 1);
    angVelPeaks = cell(6, 1);
    angVelPeakNums = cell(6, 1);
    angVelMax = cell(6, 1);
    angVelMean = cell(6, 1);
    turnIpsiTime = cell(6, 1);
    turnIpsiNum = cell(6, 1);
    turnContraTime = cell(6, 1);
    turnContraNum = cell(6, 1);
    turnTotalTime = cell(6, 1);
    turnTotalNum = cell(6, 1);
    centerMazeTime = cell(6, 1);
    centerMazeDist = cell(6, 1);

    % Iterate through each minisession
    for i = 1:6
        frameNum{i} = sum(boolDownFrameMS{i});
        %fprintf('Mini Session %d: %d frames\n', i, frameNum{i});
        % Stop to Movement (EOSSOM) Analysis
        eossomTimesMS = CLOI_EOSSOM_MS(stopEventDLC, locoEventDLC, i, rangeDownFrameMS, MvTime, DLCframe);
        eossomTimes{i} = eossomTimesMS;
        eossomNum{i} = size(eossomTimesMS, 1);
        % Velocity Analysis
        [velValMS, velPeakList] = CLOI_Velocity_MS(bodyVelDLC, boolDownFrameMS, i);
        velocityPeaks{i} = velPeakList;
        velocityPeakNums{i} = length(velPeakList);
        velocityMax{i} = max(velValMS);
        velocityMean{i} = mean(velValMS);
        % Angular Velocity Analysis
        [angVelValMS, angVelPeakList] = CLOI_AngVelocity_MS(angularVelDLC, boolDownFrameMS, i);
        angVelPeaks{i} = angVelPeakList;
        angVelPeakNums{i} = length(angVelPeakList);
        angVelMax{i} = max(angVelValMS);
        angVelMean{i} = mean(angVelValMS);
        % Turning Analysis
        [turnIpsiTimesMS, turnContraTimesMS] = CLOI_Turning_MS(turnIpsiEventDLC, turnContraEventDLC, i, rangeDownFrameMS, MvTime, DLCframe);
        turnIpsiTime{i} = turnIpsiTimesMS;
        turnIpsiNum{i} = size(turnIpsiTimesMS, 1);
        turnContraTime{i} = turnContraTimesMS;
        turnContraNum{i} = size(turnContraTimesMS, 1);
        turnTotalTime{i} = [turnIpsiTimesMS; turnContraTimesMS];
        turnTotalNum{i} = size(turnTotalTime{i}, 1);
        % Center Maze Analysis
        [centerMazeTimeMS, centerMazeDistanceMS] = CLOI_CenterMaze_MS(bodyPosDLC, i, boolDownFrameMS, CENTER, RADIUS, 0.707);
        centerMazeTime{i} = centerMazeTimeMS;
        centerMazeDist{i} = centerMazeDistanceMS;
    end

    % Store analysis data in the struct
    analysisData(analysisDataIdx).sessionName = sessName;
    analysisData(analysisDataIdx).frameNum = frameNum;
    analysisData(analysisDataIdx).eossomTimes = eossomTimes;
    analysisData(analysisDataIdx).eossomNum = eossomNum;
    analysisData(analysisDataIdx).velocityPeaks = velocityPeaks;
    analysisData(analysisDataIdx).velocityPeakNums = velocityPeakNums;
    analysisData(analysisDataIdx).velocityMax = velocityMax;
    analysisData(analysisDataIdx).velocityMean = velocityMean;
    analysisData(analysisDataIdx).angVelPeaks = angVelPeaks;
    analysisData(analysisDataIdx).angVelPeakNums = angVelPeakNums;
    analysisData(analysisDataIdx).angVelMax = angVelMax;
    analysisData(analysisDataIdx).angVelMean = angVelMean;
    analysisData(analysisDataIdx).turnIpsiTime = turnIpsiTime;
    analysisData(analysisDataIdx).turnIpsiNum = turnIpsiNum;
    analysisData(analysisDataIdx).turnContraTime = turnContraTime;
    analysisData(analysisDataIdx).turnContraNum = turnContraNum;
    analysisData(analysisDataIdx).turnTotalTime = turnTotalTime;
    analysisData(analysisDataIdx).turnTotalNum = turnTotalNum;
    analysisData(analysisDataIdx).centerMazeTime = centerMazeTime;
    analysisData(analysisDataIdx).centerMazeDist = centerMazeDist;

end

% Save analysis data to a .mat file
save('CLOI_analysisData.mat', 'analysisData');

%}

% Load the analysis data if needed
load('CLOI_analysisData.mat', 'analysisData');
fprintf('Loaded analysis data from CLOI_analysisData.mat\n');

%% Plotting Laser ON and velocity
% There are two situations where laser is ON:
% 1. When the mouse is stops from movement
% 2. When the mouse continues to stop

% So, we should check if the movement state is stop before laser is ON
% If the mouse was already in stop state, we can consider it as an add laser ON event
% If the mouse was not in stop state, we can consider it as a new laser ON event

% plotIndices = {sort([1:12:48, 2:12:48, 3:12:48]), ...
%                sort([4:12:48, 5:12:48, 6:12:48]), ...
%                sort([7:12:48, 8:12:48, 9:12:48]), ...
%                sort([10:12:48, 11:12:48, 12:12:48])};

% VelocitiesTotal = CLOI_PlotEventData(sessionData, sessionIndices, analysisData, plotIndices, 1);
% VelocitiesTotal = CLOI_PlotEventData(sessionData, sessionIndices, analysisData, plotIndices, 2);
% VelocitiesTotal = CLOI_PlotEventData(sessionData, sessionIndices, analysisData, plotIndices, 3);
% VelocitiesTotal = CLOI_PlotEventData(sessionData, sessionIndices, analysisData, plotIndices, 4);

%% Plotting and Analysis
plotIndices = {sort([1:12:48, 2:12:48, 3:12:48]), ...
               sort([4:12:48, 5:12:48, 6:12:48]), ...
               sort([7:12:48, 8:12:48, 9:12:48]), ...
               sort([10:12:48, 11:12:48, 12:12:48])};
CLOI_PlotData(analysisData, plotIndices, 'velocityMean', 'onoff');

% You can access any field dynamically using:
% data = analysisData(analysisDataIdx).(var)

% Plot timeline for sessions
% CLOI_PlotTimeline(sessionData, 32);

%% Stop to Movement Analysis/Plotting
%CLOI_EOSSOM_Plot(analysisData, sessionIndices, 'a')

%% Velocity Analysis/Plotting
%CLOI_Velocity_Plot(analysisData, sessionIndices, 'a')
%CLOI_Velocity_Plot(analysisData, sessionIndices, 'c')

% % Get laser counts
% [laserCount10, laserCount3] = CLOI_GetLaserCount(sessionData, sessionIndices);

% % Indices for each group (adjust if your order changes)
% idx_baseline_cloi    = sort([1:12:48, 2:12:48, 3:12:48]);
% idx_baseline_random  = sort([4:12:48, 5:12:48, 6:12:48]);
% idx_parkinson_cloi   = sort([7:12:48, 8:12:48, 9:12:48]);
% idx_parkinson_random = sort([10:12:48, 11:12:48, 12:12:48]);

% % Extract laser counts (third column) for each group
% laser_baseline_cloi    = cellfun(@(x) x, laserCount3(idx_baseline_cloi, 3));
% laser_baseline_random  = cellfun(@(x) x, laserCount3(idx_baseline_random, 3));
% laser_parkinson_cloi   = cellfun(@(x) x, laserCount3(idx_parkinson_cloi, 3));
% laser_parkinson_random = cellfun(@(x) x, laserCount3(idx_parkinson_random, 3));

% % Combine for plotting
% laser_data = [laser_baseline_cloi(:), laser_baseline_random(:), ...
%               laser_parkinson_cloi(:), laser_parkinson_random(:)];

% group_names = {'Baseline CLOI', 'Baseline Random', 'Parkinson CLOI', 'Parkinson Random'};

% figure('Color', 'w');
% hold on
% bar(1:4, mean(laser_data), 0.6, 'FaceColor', [0.7 0.7 0.7]);

% % Scatter individual data points
% for g = 1:4
%     scatter(g*ones(12,1), laser_data(:,g), 60, 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.7);
% end

% errorbar(1:4, mean(laser_data), std(laser_data), 'k.', 'LineWidth', 1.5);

% set(gca, 'XTick', 1:4, 'XTickLabel', group_names, 'FontSize', 12);
% ylabel('Laser Count');
% title('Laser Counts by Session Type');
% hold off

% Stop to movement transition time analysis (Behavioral clustering based)
% From end of stop to start of movement

% Plot stop event data
% CLOI_PlotTimeToMove(sessionData_B_RAND);

% Analyze stop to movement transition time
% CLOI_PlotStopToMovement(sessionData_CLOI, "Stop to Movement Transition Time - CLOI Sessions");