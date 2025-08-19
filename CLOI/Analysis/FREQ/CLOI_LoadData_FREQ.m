function [sessionData, analysisData, miniAnalysisData] = CLOI_LoadData_FREQ(baseDir, minisessionDuration, minisessionNum)
%CLOI_LoadData_FREQ Load and process FREQ session data for CLOI analysis
%
% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later
%
% This function loads session data, performs behavioral analysis, and
% generates minisession analysis for FREQ protocol experiments.
%
% Inputs:
%   baseDir - Base directory containing FREQ session folders
%   minisessionDuration - Duration of each minisession in seconds (default: 60)
%   minisessionNum - Number of minisessions (default: 10)
%
% Outputs:
%   sessionData - Struct array containing raw session data
%   analysisData - Struct array containing behavioral analysis results
%   miniAnalysisData - Struct array containing minisession analysis results

if nargin < 2
    minisessionDuration = 60;
end

if nargin < 3
    minisessionNum = 10;
end

if ~isfolder(baseDir)
    error('Base directory does not exist: %s\n', baseDir);
end

addpath('..');

%% Check if session data already exists and load it
% Add current date to mat file name for better version management
currentDate = datestr(now, 'yyyymmdd');
matFileName = sprintf('CLOI_FREQ_SessionData_%s.mat', currentDate);
matFilePath = fullfile(baseDir, matFileName);

if isfile(matFilePath)
    fprintf('Loading existing session data from: %s\n', matFilePath);
    load(matFilePath, 'sessionData', 'mouseNames', 'sessionNames');
    mouseNum = length(mouseNames);
    sessionNum = length(sessionNames);
    fprintf('Loaded %d sessions for %d mice from existing data file.\n', sessionNum, mouseNum);
    
    % Display session counts for each mouse
    sessionCount = cell(mouseNum, 1);
    for i = 1:mouseNum
        sessionCount{i, 1} = 0;
        for j = 1:sessionNum
            if contains(sessionNames{j}, mouseNames{i}) && contains(sessionNames{j}, 'FREQ')
                sessionCount{i, 1} = sessionCount{i, 1} + 1;
            end
        end
        fprintf('Mouse %s: %d FREQ sessions\n', mouseNames{i}, sessionCount{i, 1});
    end
    
    % IMPORTANT: Apply coordinate fix to cached data as well
    % The coordinate fix needs to be applied whether loading from cache or processing fresh
    fprintf('Applying coordinate system fix to loaded data...\n');
    for sIdx = 1:length(sessionData)
        if sessionData(sIdx).mazeRadius > 50 % Only apply if coordinates are still in pixels
            scaleFactor = 30 / sessionData(sIdx).mazeRadius;
            sessionData(sIdx).mazeCenter = sessionData(sIdx).mazeCenter * scaleFactor;
            sessionData(sIdx).mazeRadius = 30; % Standardize to 30 cm
        end
    end
    fprintf('Coordinate fix applied to %d sessions.\n', length(sessionData));
    
else
    fprintf('No existing session data found. Processing data from scratch...\n');
    
    %% Get mouse and session names
    sessionDir = dir(baseDir);
    mouseNames = {};
    sessionNames = {};
    for i = 1:length(sessionDir)
        if sessionDir(i).isdir && ~ismember(sessionDir(i).name, {'.', '..'})
            sessionNameTemp = sessionDir(i).name;
            sessionNames{end+1, 1} = sessionNameTemp;
            sessionNamePartTemp = split(sessionNameTemp, '_');
            mouseNameTemp = strcat(sessionNamePartTemp{1}, '_', sessionNamePartTemp{2});
            if isempty(mouseNames) || ~isequal(mouseNameTemp, mouseNames{end})
                mouseNames{end+1, 1} = mouseNameTemp;
            end
        end
    end

    %% Summarize session data
    mouseNum = length(mouseNames);
    sessionNum = length(sessionNames);
    fprintf('Total mice #: %d, Total session #: %d\n', mouseNum, sessionNum);

    % Count sessions for individual mouse
    sessionCount = cell(mouseNum, 1);
    for i = 1:mouseNum
        sessionCount{i, 1} = 0; % Initialize FREQ count for each mouse
        for j = 1:sessionNum
            if contains(sessionNames{j}, mouseNames{i}) && contains(sessionNames{j}, 'FREQ')
                sessionCount{i, 1} = sessionCount{i, 1} + 1;
            end
        end
        fprintf('Mouse %s: %d FREQ sessions\n', mouseNames{i}, sessionCount{i, 1});
    end

    %% Get session data
    sessionData = struct( ...
        'mouseName', {}, ...
        'sessionName', {}, ...
        'mazeCenter', {}, ...
        'mazeRadius', {}, ...
        'dlcTime', {}, ...
        'dlcHead', {}, ...
        'dlcBody', {}, ...
        'dlcTail', {}, ...
        'mvTime', {}, ...
        'mvState', {}, ...
        'mvCenter', {}, ...
        'lsTime', {}, ...
        'lsState', {});

    for sIdx = 1:sessionNum
        % Get session information
        sessionName = sessionNames{sIdx};
        sessionNamePart = split(sessionName, '_');
        mouseName = strcat(sessionNamePart{1}, '_', sessionNamePart{2});
        sessionPath = fullfile(baseDir, sessionName);
        
        fprintf('Processing session: %s\n', sessionName);
        sessionData(sIdx).mouseName = mouseName;
        sessionData(sIdx).sessionName = sessionName;

        % Get open-field maze geometry
        sessionMetaRegex = fullfile(sessionPath, 'Log', 'log_metadata_*.csv');
        sessionMetaFinds = dir(sessionMetaRegex);
        if ~isempty(sessionMetaFinds)
            % If metadata file exists, read maze center and radius
            fprintf('Using metadata file for maze geometry.\n');
            sessionMetaDir = fullfile(sessionPath, 'Log', sessionMetaFinds(1).name);
            metaTable = readtable(sessionMetaDir, 'ReadVariableNames', false);
            mazeCenterString = cell2mat(metaTable{1, 1});
            mazeRadiusString = cell2mat(metaTable{1, 2});
            mazeCenter = sscanf(mazeCenterString, '(%d, %d)')';
            mazeRadius = sscanf(mazeRadiusString, '%d');
            sessionData(sIdx).mazeCenter = mazeCenter;
            sessionData(sIdx).mazeRadius = mazeRadius;
            fprintf('Maze center: (%d, %d), Radius: %d\n', mazeCenter(1), mazeCenter(2), mazeRadius);

        else
            % If metadata file is not found, use video file as fallback
            fprintf('Metadata file not found, using video file for maze geometry...');
            sessionVideoDir = fullfile(sessionPath, 'output_video.mp4');
            if isfile(sessionVideoDir)
                sessionVideoObj = VideoReader(sessionVideoDir);
                sessionVideoFrameNum = sessionVideoObj.NumFrames;
                sessionVideoFrameMid = round(sessionVideoFrameNum / 2);
                sessionVideoObj.CurrentTime = (sessionVideoFrameMid - 1) / sessionVideoObj.FrameRate;
                sessionVideoMidFrame = readFrame(sessionVideoObj);
                [mazeCenterX, mazeCenterY, mazeRadius, ~] = CLOI_GetCircleFromUser(sessionVideoMidFrame);
                sessionData(sIdx).mazeCenter = [mazeCenterX, mazeCenterY]';
                sessionData(sIdx).mazeRadius = mazeRadius;
                fprintf('Maze center: (%d, %d), Radius: %d\n', mazeCenterX, mazeCenterY, mazeRadius);
            else
                warning('Video file not found for session: %s\n', sessionName);
                sessionData(sIdx).mazeCenter = [1400, 700]'; % Default center
                sessionData(sIdx).mazeRadius = 380; % Default radius
                fprintf('Maze center: (1400, 700), Radius: 380 (default geometry)\n');
            end
        end

        % Get DLC data
        sessionDLCRegex = fullfile(sessionPath, strcat(sessionName, '*.csv'));
        sessionDLCFinds = dir(sessionDLCRegex);
        if ~isempty(sessionDLCFinds)
            sessionDLCDir = fullfile(sessionPath, sessionDLCFinds(1).name);
            % Convert to character array for compatibility with CLOI_GetDLCData
            sessionDLCDir = char(sessionDLCDir);
            
            % Get maze parameters
            mazeCenter = sessionData(sIdx).mazeCenter;
            mazeRadius = sessionData(sIdx).mazeRadius;
            
            % Load and clean DLC data with maze parameters
            [dlcTime, dlcCoordX, dlcCoordY, dlcCoordConf, cleaningStats] = CLOI_GetDLCData(sessionDLCDir, 'head', ...
                'MazeCenter', mazeCenter, 'MazeRadius', mazeRadius);
            sessionData(sIdx).dlcTime = dlcTime;
            sessionData(sIdx).dlcHead = [dlcCoordX, dlcCoordY, dlcCoordConf];
            sessionData(sIdx).headCleaningStats = cleaningStats;
            
            [~, dlcCoordX, dlcCoordY, dlcCoordConf, cleaningStats] = CLOI_GetDLCData(sessionDLCDir, 'center', ...
                'MazeCenter', mazeCenter, 'MazeRadius', mazeRadius);
            sessionData(sIdx).dlcBody = [dlcCoordX, dlcCoordY, dlcCoordConf];
            sessionData(sIdx).centerCleaningStats = cleaningStats;
            
            [~, dlcCoordX, dlcCoordY, dlcCoordConf, cleaningStats] = CLOI_GetDLCData(sessionDLCDir, 'tail', ...
                'MazeCenter', mazeCenter, 'MazeRadius', mazeRadius);
            sessionData(sIdx).dlcTail = [dlcCoordX, dlcCoordY, dlcCoordConf];
            sessionData(sIdx).tailCleaningStats = cleaningStats;
            
            % Display cleaning results
            fprintf('  DLC Cleaning Results:\n');
            fprintf('    Head: %.1f%% improvement (%.1f%% -> %.1f%% outside maze)\n', ...
                cleaningStats.improvementPercent, cleaningStats.outsideOriginalPercent, cleaningStats.outsideCleanedPercent);
            if cleaningStats.outsideCleanedPercent < 1
                fprintf('    ✅ Excellent: <1%% outside maze after cleaning\n');
            elseif cleaningStats.outsideCleanedPercent < 5
                fprintf('    ✅ Good: <5%% outside maze after cleaning\n');
            else
                fprintf('    ⚠️  Warning: %.1f%% still outside maze after cleaning\n', cleaningStats.outsideCleanedPercent);
            end
        else
            warning('DLC CSV files not found for session: %s\n', sessionName);
            sessionData(sIdx).dlcTime = [];
            sessionData(sIdx).dlcHead = [];
            sessionData(sIdx).dlcBody = [];
            sessionData(sIdx).dlcTail = [];
        end

        % Get Mv data
        sessionMvRegex = fullfile(sessionPath, 'Log', 'log_movement_*.csv');
        sessionMvFinds = dir(sessionMvRegex);
        if ~isempty(sessionMvFinds)
            mvFileDir = fullfile(sessionPath, 'Log', sessionMvFinds(1).name);
            [mvTime, mvState, mvCenter] = CLOI_GetMvData(mvFileDir);
            sessionData(sIdx).mvTime = mvTime;
            sessionData(sIdx).mvState = mvState;
            sessionData(sIdx).mvCenter = mvCenter;
        else
            warning('Movement data file not found for session: %s\n', sessionName);
            sessionData(sIdx).mvTime = [];
            sessionData(sIdx).mvState = [];
            sessionData(sIdx).mvCenter = [];
        end

        % Get laser data
        sessionLsRegex = fullfile(sessionPath, 'Log', 'log_laser_*.csv');
        sessionLsFinds = dir(sessionLsRegex);
        if ~isempty(sessionLsFinds)
            lsFileDir = fullfile(sessionPath, 'Log', sessionLsFinds(1).name);
            [lsTime, lsState] = CLOI_GetLaserData(lsFileDir);
            sessionData(sIdx).lsTime = lsTime;
            sessionData(sIdx).lsState = lsState;
        else
            warning('Laser data file not found for session: %s\n', sessionName);
            sessionData(sIdx).lsTime = [];
            sessionData(sIdx).lsState = [];
        end
    end

    %% Save session data to .mat file
    matFileName = sprintf('CLOI_FREQ_SessionData_%s.mat', currentDate);
    matFilePath = fullfile(baseDir, matFileName);
    fprintf('Saving session data to: %s\n', matFilePath);
    save(matFilePath, 'sessionData', 'mouseNames', 'sessionNames');
    fprintf('Successfully saved %d sessions for %d mice to %s\n', sessionNum, mouseNum, matFileName);
end

%% Check if analysis data already exists and load it
analysisMatFileName = sprintf('CLOI_FREQ_AnalysisData_%s.mat', currentDate);
analysisMatFilePath = fullfile(baseDir, analysisMatFileName);

if isfile(analysisMatFilePath)
    fprintf('Loading existing analysis data from: %s\n', analysisMatFilePath);
    loadedVars = load(analysisMatFilePath);
    
    % Check if both analysisData and miniAnalysisData exist
    if isfield(loadedVars, 'analysisData') && isfield(loadedVars, 'miniAnalysisData')
        analysisData = loadedVars.analysisData;
        miniAnalysisData = loadedVars.miniAnalysisData;
        fprintf('Loaded complete analysis data for %d sessions from existing data file.\n', length(analysisData));
        fprintf('Analysis complete - using cached data.\n');
        return; % Skip all analysis since everything is already loaded
    elseif isfield(loadedVars, 'analysisData')
        analysisData = loadedVars.analysisData;
        fprintf('Loaded analysisData for %d sessions. Will generate miniAnalysisData...\n', length(analysisData));
        % Skip main analysis, go directly to minisession analysis
    else
        fprintf('Analysis file exists but incomplete. Processing from scratch...\n');
        processMainAnalysis = true;
    end
else
    fprintf('No existing analysis data found. Processing analysis from scratch...\n');
    processMainAnalysis = true;
end

% Only do main analysis if needed
if exist('processMainAnalysis', 'var') && processMainAnalysis

    %% Analysis of FREQ sessions
    analysisData = struct( ...
        'mouseName', {}, ...
        'sessionName', {}, ...
        'frameNum', {}, ...
        'headPos', {}, ...
        'bodyPos', {}, ...
        'headVel', {}, ...
        'bodyVel', {}, ...
        'angVel', {}, ...
        'ipsiTurn', {}, ...
        'contraTurn', {}, ...
        'locoState', {}, ...
        'stopState', {} ...
        );

    for sIdx = 1:sessionNum
        analysisData(sIdx).mouseName = sessionData(sIdx).mouseName;
        analysisData(sIdx).sessionName = sessionData(sIdx).sessionName;
        fprintf('Analyzing session: %s\n', analysisData(sIdx).sessionName);

        % Maze data
        mazeRadius = sessionData(sIdx).mazeRadius;
        mazeCenter = [sessionData(sIdx).mazeCenter(1), sessionData(sIdx).mazeCenter(2)];

        % DLC data
        DLCframe = sessionData(sIdx).dlcTime;
        DLChead = sessionData(sIdx).dlcHead;
        DLCbody = sessionData(sIdx).dlcBody;
        DLCtail = sessionData(sIdx).dlcTail;

        % Mv, Ls data
        mvTime = sessionData(sIdx).mvTime;
        mvState = sessionData(sIdx).mvState;
        lsTime = sessionData(sIdx).lsTime;
        lsState = sessionData(sIdx).lsState;

        % Behavioral clustering
        behavData = CLOI_behavcluster(DLCframe, DLChead, DLCbody, DLCtail, mazeRadius);
        
        % IMPORTANT: Apply same scaling to maze coordinates as applied to DLC coordinates
        % The CLOI_behavcluster function scales DLC coordinates by (30/mazeRadius) to convert to cm
        % This means we need to scale the maze coordinates by the same factor
        scaleFactor = 30 / mazeRadius;
        sessionData(sIdx).mazeCenter = sessionData(sIdx).mazeCenter * scaleFactor;
        sessionData(sIdx).mazeRadius = 30; % The radius is now standardized to 30 cm
        
        dsDLCframe = behavData.frames_downsampled;
        dsDLCHeadPos = behavData.nose_down;
        dsDLCBodyPos = behavData.centre_down;
        dsDLCHeadVel = behavData.nose_velocity;
        dsDLCBodyVel = behavData.centre_velocity;
        dsDLCOrientation = behavData.orientation_deg;
        dsDLCAngVel = behavData.angular_velocity;
        dsDLCIpsiTurn = behavData.turn_ipsiversive;
        dsDLCContraTurn = behavData.turn_contraversive;
        dsDLCLocomotion = behavData.locomotion_events;
        dsDLCStop = behavData.stop_events;

        analysisData(sIdx).frameNum = dsDLCframe;
        analysisData(sIdx).headPos = dsDLCHeadPos;
        analysisData(sIdx).bodyPos = dsDLCBodyPos;
        analysisData(sIdx).headVel = dsDLCHeadVel;
        analysisData(sIdx).bodyVel = dsDLCBodyVel;
        analysisData(sIdx).angVel = dsDLCAngVel;
        analysisData(sIdx).ipsiTurn = dsDLCIpsiTurn;
        analysisData(sIdx).contraTurn = dsDLCContraTurn;
        analysisData(sIdx).locoState = dsDLCLocomotion;
        analysisData(sIdx).stopState = dsDLCStop;
    end

    %% Save analysis data to .mat file (partial save after main analysis)
    fprintf('Saving partial analysis data to: %s\n', analysisMatFilePath);
    save(analysisMatFilePath, 'analysisData', '-v7.3');
    fprintf('Main analysis data saved. Proceeding to minisession analysis...\n');
end

%% Analysis of minisessions
miniAnalysisData = struct ( ...
    'mouseName', {}, ...
    'sessionName', {}, ...
    'eossomTime', {}, ...
    'eossomNum', {}, ...
    'velocityPeak', {}, ...
    'velocityPeakCount', {}, ...
    'velocityMax', {}, ...
    'velocityMean', {}, ...
    'angVelPeak', {}, ...
    'angVelPeakCount', {}, ...
    'angVelMax', {}, ...
    'angVelMean', {}, ...
    'ipsiTurnTime', {}, ...
    'ipsiTurnNum', {}, ...
    'contraTurnTime', {}, ...
    'contraTurnNum', {}, ...
    'bothTurnTime', {}, ...
    'bothTurnNum', {}, ...
    'centerMazeTime', {}, ...
    'centerMazeDist', {}, ...
    'totalDistance', {}, ...
    'centerDistance', {}, ...
    'peripheralDistance', {} ...
);

for sIdx = 1:sessionNum
    miniAnalysisData(sIdx).mouseName = sessionData(sIdx).mouseName;
    miniAnalysisData(sIdx).sessionName = sessionData(sIdx).sessionName;
    fprintf("Analyzing minisession: %s\n", miniAnalysisData(sIdx).sessionName);

    % Get data from analysisData
    frameDownDLC = analysisData(sIdx).frameNum;
    headPosDLC = analysisData(sIdx).headPos;
    bodyVelDLC = analysisData(sIdx).bodyVel;
    angularVelDLC = analysisData(sIdx).angVel;
    turnIpsiEventDLC = analysisData(sIdx).ipsiTurn;
    turnContraEventDLC = analysisData(sIdx).contraTurn;
    locoEventDLC = analysisData(sIdx).locoState;
    stopEventDLC = analysisData(sIdx).stopState;
    
    % Get Mv and DLC time
    MvTime = sessionData(sIdx).mvTime;
    DLCframe = sessionData(sIdx).dlcTime;

    % Get maze info
    CENTER = sessionData(sIdx).mazeCenter;
    RADIUS = sessionData(sIdx).mazeRadius;

    % Get minisession indices
    boolDownFrameMS = cell(minisessionNum, 1);
    rangeDownFrameMS = cell(minisessionNum, 1);
    for i = 1:minisessionNum
        minisessionStart = (i-1) * minisessionDuration;
        minisessionEnd = i * minisessionDuration;
        
        % Get original frame indices for minisession
        oriFrameIdx = find(MvTime > minisessionStart & MvTime < minisessionEnd);
        if isempty(oriFrameIdx)
            rangeDownFrameMS{i} = [NaN, NaN];
            boolDownFrameMS{i} = false(size(frameDownDLC));
            continue;
        end
        
        % Find corresponding downsampled frame indices
        startFrame = DLCframe(oriFrameIdx(1));
        endFrame = DLCframe(oriFrameIdx(end));
        
        downSampledStartIdx = find(frameDownDLC >= startFrame, 1, 'first');
        downSampledEndIdx = find(frameDownDLC <= endFrame, 1, 'last');
        
        if isempty(downSampledStartIdx) || isempty(downSampledEndIdx)
            rangeDownFrameMS{i} = [NaN, NaN];
            boolDownFrameMS{i} = false(size(frameDownDLC));
            continue;
        end
        
        rangeDownFrameMS{i} = [frameDownDLC(downSampledStartIdx), frameDownDLC(downSampledEndIdx)];
        
        boolDownFrameMS{i} = false(size(frameDownDLC));
        boolDownFrameMS{i}(downSampledStartIdx:downSampledEndIdx) = true;
    end

    % Initialize fields for minisession data
    eossomTimeMS = cell(minisessionNum, 1);
    eossomNumMS = zeros(minisessionNum, 1);
    velocityPeakMS = cell(minisessionNum, 1);
    velocityPeakCountMS = zeros(minisessionNum, 1);
    velocityMaxMS = zeros(minisessionNum, 1);
    velocityMeanMS = zeros(minisessionNum, 1);
    angVelPeakMS = cell(minisessionNum, 1);
    angVelPeakCountMS = zeros(minisessionNum, 1);
    angVelMaxMS = zeros(minisessionNum, 1);
    angVelMeanMS = zeros(minisessionNum, 1);
    ipsiTurnTimeMS = zeros(minisessionNum, 1);
    ipsiTurnNumMS = zeros(minisessionNum, 1);
    contraTurnTimeMS = zeros(minisessionNum, 1);
    contraTurnNumMS = zeros(minisessionNum, 1);
    totalDistanceMS = zeros(minisessionNum, 1);
    centerDistanceMS = zeros(minisessionNum, 1);
    peripheralDistanceMS = zeros(minisessionNum, 1);

    for msIdx = 1:minisessionNum
        if any(isnan(rangeDownFrameMS{msIdx}))
            continue;
        end
        
        % EOSSOM
        eossomTimes = CLOI_EOSSOM_MS(stopEventDLC, locoEventDLC, msIdx, rangeDownFrameMS, MvTime, DLCframe);
        eossomTimeMS{msIdx} = eossomTimes;
        eossomNumMS(msIdx) = length(eossomTimes);

        % Velocity
        [velValMS, velocityPeakList] = CLOI_Velocity_MS(bodyVelDLC, boolDownFrameMS, msIdx);
        velocityPeakMS{msIdx} = velocityPeakList;
        velocityPeakCountMS(msIdx) = length(velocityPeakList);
        if ~isempty(velValMS)
            velocityMaxMS(msIdx) = max(velValMS);
            velocityMeanMS(msIdx) = mean(velValMS, 'omitnan');
        end

        % Angular velocity
        [angVelValMS, angVelPeakList] = CLOI_AngVelocity_MS(angularVelDLC, boolDownFrameMS, msIdx);
        angVelPeakMS{msIdx} = angVelPeakList;
        angVelPeakCountMS(msIdx) = length(angVelPeakList);
        if ~isempty(angVelValMS)
            angVelMaxMS(msIdx) = max(angVelValMS);
            angVelMeanMS(msIdx) = mean(angVelValMS, 'omitnan');
        end

        % Turning
        [turnIpsiT, turnContraT] = CLOI_Turning_MS(turnIpsiEventDLC, turnContraEventDLC, msIdx, rangeDownFrameMS, MvTime, DLCframe);
        ipsiTurnTimeMS(msIdx) = sum(turnIpsiT);
        ipsiTurnNumMS(msIdx) = length(turnIpsiT);
        contraTurnTimeMS(msIdx) = sum(turnContraT);
        contraTurnNumMS(msIdx) = length(turnContraT);
        
        % Distance calculations using head position data
        msHeadPos = headPosDLC(boolDownFrameMS{msIdx}, :);
        if size(msHeadPos, 1) > 1
            % Calculate total distance traveled
            headPosDiff = diff(msHeadPos, 1, 1);
            segmentDistances = sqrt(sum(headPosDiff.^2, 2));
            totalDistanceMS(msIdx) = sum(segmentDistances);
            
            % Calculate distance from maze center for each position
            % CENTER is [x; y] column vector, msHeadPos is [N x 2] matrix
            % Need to broadcast CENTER as row vector for subtraction
            distFromCenter = sqrt(sum((msHeadPos - CENTER(:)').^2, 2));
            
            % Determine which segments are in center vs peripheral regions
            % Center region: within 1/2 radius of maze center
            centerThreshold = RADIUS / 2;
            inCenterRegion = distFromCenter <= centerThreshold;
            
            % Calculate center and peripheral distances
            centerDistanceMS(msIdx) = 0;
            peripheralDistanceMS(msIdx) = 0;
            
            for segIdx = 1:length(segmentDistances)
                % Check if both start and end points of segment are in center
                if inCenterRegion(segIdx) && inCenterRegion(segIdx + 1)
                    centerDistanceMS(msIdx) = centerDistanceMS(msIdx) + segmentDistances(segIdx);
                else
                    peripheralDistanceMS(msIdx) = peripheralDistanceMS(msIdx) + segmentDistances(segIdx);
                end
            end
            
            % Validation: ensure total distance equals sum of center and peripheral distances
            calculatedTotal = centerDistanceMS(msIdx) + peripheralDistanceMS(msIdx);
            if abs(calculatedTotal - totalDistanceMS(msIdx)) > 1e-10
                warning('Distance calculation mismatch in session %s, minisession %d: total=%.6f, sum=%.6f', ...
                    sessionData(sIdx).sessionName, msIdx, totalDistanceMS(msIdx), calculatedTotal);
            end
        else
            totalDistanceMS(msIdx) = 0;
            centerDistanceMS(msIdx) = 0;
            peripheralDistanceMS(msIdx) = 0;
        end
    end

    % Store minisession analysis
    miniAnalysisData(sIdx).eossomTime = eossomTimeMS;
    miniAnalysisData(sIdx).eossomNum = eossomNumMS;
    miniAnalysisData(sIdx).velocityPeak = velocityPeakMS;
    miniAnalysisData(sIdx).velocityPeakCount = velocityPeakCountMS;
    miniAnalysisData(sIdx).velocityMax = velocityMaxMS;
    miniAnalysisData(sIdx).velocityMean = velocityMeanMS;
    miniAnalysisData(sIdx).angVelPeak = angVelPeakMS;
    miniAnalysisData(sIdx).angVelPeakCount = angVelPeakCountMS;
    miniAnalysisData(sIdx).angVelMax = angVelMaxMS;
    miniAnalysisData(sIdx).angVelMean = angVelMeanMS;
    miniAnalysisData(sIdx).ipsiTurnTime = ipsiTurnTimeMS;
    miniAnalysisData(sIdx).ipsiTurnNum = ipsiTurnNumMS;
    miniAnalysisData(sIdx).contraTurnTime = contraTurnTimeMS;
    miniAnalysisData(sIdx).contraTurnNum = contraTurnNumMS;
    miniAnalysisData(sIdx).totalDistance = totalDistanceMS;
    miniAnalysisData(sIdx).centerDistance = centerDistanceMS;
    miniAnalysisData(sIdx).peripheralDistance = peripheralDistanceMS;
end

%% Save complete analysis data to .mat file
fprintf('Saving complete analysis data (analysisData + miniAnalysisData) to: %s\n', analysisMatFilePath);
save(analysisMatFilePath, 'analysisData', 'miniAnalysisData', '-v7.3');
fprintf('Successfully saved complete analysis data for %d sessions to %s\n', length(analysisData), analysisMatFileName);

end
