%% CLOI DLC Tracking Inspection Script
% This script imports DLC data and visualizes it with maze information
% to identify tracking issues and prepare for data cleaning

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

clear; close all;

% Add current directory to path for accessing functions
addpath('.');

%% Configuration
% Set the base directory for FREQ data
baseDir = "H:\FREQ";

% For testing, we'll use a specific session
% You can modify these to test different sessions
testMouseName = "ChAT_971-3";  % Known problematic mouse
testSessionType = "Parkinson"; % Known to have tracking issues

fprintf('=== CLOI DLC TRACKING INSPECTION ===\n');
fprintf('Base directory: %s\n', baseDir);
fprintf('Target mouse: %s\n', testMouseName);
fprintf('Target session type: %s\n', testSessionType);

%% Find sessions in the base directory
sessionDirs = dir(baseDir);
sessionList = {};
for i = 1:length(sessionDirs)
    if sessionDirs(i).isdir && ~startsWith(sessionDirs(i).name, '.')
        sessionList{end+1} = sessionDirs(i).name;
    end
end

fprintf('\nFound %d sessions in directory:\n', length(sessionList));
for i = 1:length(sessionList)
    fprintf('  %d: %s\n', i, sessionList{i});
end

%% Select a specific session for detailed inspection
targetSessions = {};
for i = 1:length(sessionList)
    sessionName = sessionList{i};
    if contains(sessionName, testMouseName) && contains(sessionName, testSessionType)
        targetSessions{end+1} = sessionName;
    end
end

if isempty(targetSessions)
    fprintf('\nNo sessions found matching criteria. Using first available session.\n');
    if ~isempty(sessionList)
        selectedSession = sessionList{1};
    else
        error('No sessions found in directory: %s', baseDir);
    end
else
    fprintf('\nFound %d matching sessions:\n', length(targetSessions));
    for i = 1:length(targetSessions)
        fprintf('  %d: %s\n', i, targetSessions{i});
    end
    selectedSession = targetSessions{1}; % Use first matching session
end

fprintf('\nSelected session for inspection: %s\n', selectedSession);

%% Load DLC data for the selected session
sessionPath = fullfile(baseDir, selectedSession);
fprintf('\nSession path: %s\n', sessionPath);

% Look for DLC CSV file in the session directory
dlcFiles = dir(fullfile(sessionPath, '*DLC*.csv'));
if isempty(dlcFiles)
    dlcFiles = dir(fullfile(sessionPath, '*.csv'));
end

if isempty(dlcFiles)
    error('No DLC CSV file found in session directory: %s', sessionPath);
end

dlcFilePath = fullfile(sessionPath, dlcFiles(1).name);
fprintf('DLC file: %s\n', dlcFilePath);

% Load DLC data using the existing function
try
    [dlcTime, dlcHeadX, dlcHeadY, dlcHeadConf] = CLOI_GetDLCData(dlcFilePath, 'head');
    [~, dlcCenterX, dlcCenterY, dlcCenterConf] = CLOI_GetDLCData(dlcFilePath, 'center');
    [~, dlcTailX, dlcTailY, dlcTailConf] = CLOI_GetDLCData(dlcFilePath, 'tail');
    
    fprintf('Successfully loaded DLC data:\n');
    fprintf('  Number of frames: %d\n', length(dlcTime));
    fprintf('  Time range: %.2f to %.2f\n', min(dlcTime), max(dlcTime));
    
catch ME
    fprintf('Error loading DLC data: %s\n', ME.message);
    return;
end

%% Load maze geometry information
% Look for metadata file
metadataFile = fullfile(sessionPath, 'metadata.csv');
mazeCenter = [];
mazeRadius = [];

if isfile(metadataFile)
    fprintf('\nLoading maze geometry from metadata file...\n');
    try
        metaTable = readtable(metadataFile, "VariableNamingRule", "preserve");
        mazeCenterString = cell2mat(metaTable{1, 1});
        mazeRadiusString = cell2mat(metaTable{1, 2});
        mazeCenter = sscanf(mazeCenterString, '(%d, %d)')';
        mazeRadius = sscanf(mazeRadiusString, '%d');
        fprintf('Maze center: (%d, %d) pixels, Radius: %d pixels\n', ...
            mazeCenter(1), mazeCenter(2), mazeRadius);
    catch
        fprintf('Error reading metadata file. Will use manual input.\n');
        mazeCenter = [];
        mazeRadius = [];
    end
end

% If no metadata or failed to load, try to get from user or use defaults
if isempty(mazeCenter) || isempty(mazeRadius)
    fprintf('\nMaze geometry not available from metadata.\n');
    
    % Look for video file to manually select maze
    videoFiles = dir(fullfile(sessionPath, '*.mp4'));
    if isempty(videoFiles)
        videoFiles = dir(fullfile(sessionPath, '*.avi'));
    end
    
    if ~isempty(videoFiles)
        fprintf('Found video file: %s\n', videoFiles(1).name);
        videoPath = fullfile(sessionPath, videoFiles(1).name);
        
        % Try to read a frame from the video for manual circle selection
        try
            videoObj = VideoReader(videoPath);
            videoObj.CurrentTime = videoObj.Duration / 2; % Middle frame
            frame = readFrame(videoObj);
            
            fprintf('Click OK to manually select maze boundary, or Cancel to use estimated values.\n');
            answer = questdlg('Select maze boundary manually?', 'Maze Selection', 'OK', 'Cancel', 'OK');
            
            if strcmp(answer, 'OK')
                [centerX, centerY, radius, isConfirmed] = CLOI_GetCircleFromUser(frame);
                if isConfirmed
                    mazeCenter = [centerX, centerY];
                    mazeRadius = radius;
                    fprintf('User-selected maze center: (%.1f, %.1f), Radius: %.1f\n', ...
                        mazeCenter(1), mazeCenter(2), mazeRadius);
                end
            end
        catch
            fprintf('Could not read video file.\n');
        end
    end
    
    % If still no maze info, use estimated values based on data range
    if isempty(mazeCenter) || isempty(mazeRadius)
        fprintf('Using estimated maze geometry based on data range.\n');
        
        % Estimate center as median of coordinates
        validHeadX = dlcHeadX(dlcHeadConf > 0.5);
        validHeadY = dlcHeadY(dlcHeadConf > 0.5);
        
        if ~isempty(validHeadX) && ~isempty(validHeadY)
            mazeCenter = [median(validHeadX), median(validHeadY)];
            
            % Estimate radius as distance containing ~95% of points
            distances = sqrt((validHeadX - mazeCenter(1)).^2 + (validHeadY - mazeCenter(2)).^2);
            mazeRadius = prctile(distances, 95) * 1.1; % Add 10% margin
            
            fprintf('Estimated maze center: (%.1f, %.1f), Radius: %.1f\n', ...
                mazeCenter(1), mazeCenter(2), mazeRadius);
        else
            % Fallback default values
            mazeCenter = [400, 300];
            mazeRadius = 200;
            fprintf('Using default maze center: (%.1f, %.1f), Radius: %.1f\n', ...
                mazeCenter(1), mazeCenter(2), mazeRadius);
        end
    end
end

% Apply 1.1x radius expansion for more lenient boundary detection
mazeRadiusExpanded = mazeRadius * 1.1;
fprintf('Using expanded maze radius: %.1f pixels (1.1x original) for boundary detection\n', mazeRadiusExpanded);

%% Analyze tracking quality and detect outliers
fprintf('\n=== TRACKING QUALITY ANALYSIS ===\n');

% Calculate confidence statistics
meanHeadConf = mean(dlcHeadConf);
meanCenterConf = mean(dlcCenterConf);
meanTailConf = mean(dlcTailConf);

lowConfThreshold = 0.5;
lowConfHeadFrames = sum(dlcHeadConf < lowConfThreshold);
lowConfCenterFrames = sum(dlcCenterConf < lowConfThreshold);
lowConfTailFrames = sum(dlcTailConf < lowConfThreshold);

%% Advanced Outlier Detection
fprintf('\n=== OUTLIER DETECTION ===\n');

% 1. Distance-based outliers
headDistances = sqrt((dlcHeadX - mazeCenter(1)).^2 + (dlcHeadY - mazeCenter(2)).^2);
centerDistances = sqrt((dlcCenterX - mazeCenter(1)).^2 + (dlcCenterY - mazeCenter(2)).^2);
tailDistances = sqrt((dlcTailX - mazeCenter(1)).^2 + (dlcTailY - mazeCenter(2)).^2);

% 2. Velocity-based outliers (large jumps between frames)
headVelocity = sqrt(diff(dlcHeadX).^2 + diff(dlcHeadY).^2);
centerVelocity = sqrt(diff(dlcCenterX).^2 + diff(dlcCenterY).^2);
tailVelocity = sqrt(diff(dlcTailX).^2 + diff(dlcTailY).^2);

% Define thresholds
extremeDistanceThreshold = mazeRadiusExpanded * 2; % Use expanded radius for outlier detection
highVelocityThreshold = prctile(headVelocity, 99); % 99th percentile

% Identify different types of outliers
distanceOutliers = headDistances > extremeDistanceThreshold;
velocityOutliers = [false; headVelocity > highVelocityThreshold]; % Add false for first frame
lowConfidenceFrames = dlcHeadConf < lowConfThreshold;

% Combined problematic frames
problematicFrames = distanceOutliers | velocityOutliers | lowConfidenceFrames;

fprintf('Outlier Detection Results:\n');
fprintf('  Distance outliers: %d frames (%.1f%%)\n', sum(distanceOutliers), sum(distanceOutliers)/length(dlcTime)*100);
fprintf('  Velocity outliers: %d frames (%.1f%%)\n', sum(velocityOutliers), sum(velocityOutliers)/length(dlcTime)*100);
fprintf('  Low confidence: %d frames (%.1f%%)\n', sum(lowConfidenceFrames), sum(lowConfidenceFrames)/length(dlcTime)*100);
fprintf('  Total problematic: %d frames (%.1f%%)\n', sum(problematicFrames), sum(problematicFrames)/length(dlcTime)*100);

%% Data Cleaning and Interpolation
fprintf('\n=== DATA CLEANING AND INTERPOLATION ===\n');

% Create cleaned data copies
dlcHeadX_clean = dlcHeadX;
dlcHeadY_clean = dlcHeadY;
dlcCenterX_clean = dlcCenterX;
dlcCenterY_clean = dlcCenterY;
dlcTailX_clean = dlcTailX;
dlcTailY_clean = dlcTailY;

% Mark problematic points as NaN
dlcHeadX_clean(problematicFrames) = NaN;
dlcHeadY_clean(problematicFrames) = NaN;
dlcCenterX_clean(problematicFrames) = NaN;
dlcCenterY_clean(problematicFrames) = NaN;
dlcTailX_clean(problematicFrames) = NaN;
dlcTailY_clean(problematicFrames) = NaN;

% Interpolate missing values with spatial constraints
validFrames = ~isnan(dlcHeadX_clean);
if sum(validFrames) > 2 % Need at least 2 valid points for interpolation
    dlcHeadX_interp = dlcHeadX_clean;
    dlcHeadY_interp = dlcHeadY_clean;
    dlcCenterX_interp = dlcCenterX_clean;
    dlcCenterY_interp = dlcCenterY_clean;
    dlcTailX_interp = dlcTailX_clean;
    dlcTailY_interp = dlcTailY_clean;
    
    % Linear interpolation for missing values (no extrapolation)
    dlcHeadX_temp = interp1(dlcTime(validFrames), dlcHeadX_clean(validFrames), dlcTime, 'linear');
    dlcHeadY_temp = interp1(dlcTime(validFrames), dlcHeadY_clean(validFrames), dlcTime, 'linear');
    
    % Apply spatial constraints: ensure interpolated points stay within expanded maze
    for i = 1:length(dlcTime)
        if isnan(dlcHeadX_clean(i)) && ~isnan(dlcHeadX_temp(i)) % This was an interpolated point
            interpDist = sqrt((dlcHeadX_temp(i) - mazeCenter(1))^2 + (dlcHeadY_temp(i) - mazeCenter(2))^2);
            
            if interpDist > mazeRadiusExpanded
                % Project the interpolated point back onto the maze boundary
                angle = atan2(dlcHeadY_temp(i) - mazeCenter(2), dlcHeadX_temp(i) - mazeCenter(1));
                dlcHeadX_temp(i) = mazeCenter(1) + mazeRadiusExpanded * 0.95 * cos(angle); % 95% of radius for safety margin
                dlcHeadY_temp(i) = mazeCenter(2) + mazeRadiusExpanded * 0.95 * sin(angle);
            end
        end
    end
    
    % Use constrained interpolated values
    dlcHeadX_interp = dlcHeadX_temp;
    dlcHeadY_interp = dlcHeadY_temp;
    
    % For remaining NaN values (at edges), use nearest valid neighbor
    nanIndices = isnan(dlcHeadX_interp);
    if any(nanIndices)
        dlcHeadX_interp(nanIndices) = interp1(find(~nanIndices), dlcHeadX_interp(~nanIndices), find(nanIndices), 'nearest', 'extrap');
        dlcHeadY_interp(nanIndices) = interp1(find(~nanIndices), dlcHeadY_interp(~nanIndices), find(nanIndices), 'nearest', 'extrap');
    end
    
    % Similar process for center and tail (simplified for brevity)
    validCenterFrames = ~isnan(dlcCenterX_clean);
    if sum(validCenterFrames) > 2
        dlcCenterX_interp = interp1(dlcTime(validCenterFrames), dlcCenterX_clean(validCenterFrames), dlcTime, 'linear');
        dlcCenterY_interp = interp1(dlcTime(validCenterFrames), dlcCenterY_clean(validCenterFrames), dlcTime, 'linear');
        
        % Handle NaN values with nearest neighbor
        nanIndices = isnan(dlcCenterX_interp);
        if any(nanIndices)
            dlcCenterX_interp(nanIndices) = interp1(find(~nanIndices), dlcCenterX_interp(~nanIndices), find(nanIndices), 'nearest', 'extrap');
            dlcCenterY_interp(nanIndices) = interp1(find(~nanIndices), dlcCenterY_interp(~nanIndices), find(nanIndices), 'nearest', 'extrap');
        end
    end
    
    validTailFrames = ~isnan(dlcTailX_clean);
    if sum(validTailFrames) > 2
        dlcTailX_interp = interp1(dlcTime(validTailFrames), dlcTailX_clean(validTailFrames), dlcTime, 'linear');
        dlcTailY_interp = interp1(dlcTime(validTailFrames), dlcTailY_clean(validTailFrames), dlcTime, 'linear');
        
        % Handle NaN values with nearest neighbor
        nanIndices = isnan(dlcTailX_interp);
        if any(nanIndices)
            dlcTailX_interp(nanIndices) = interp1(find(~nanIndices), dlcTailX_interp(~nanIndices), find(nanIndices), 'nearest', 'extrap');
            dlcTailY_interp(nanIndices) = interp1(find(~nanIndices), dlcTailY_interp(~nanIndices), find(nanIndices), 'nearest', 'extrap');
        end
    end
    
    % Count how many points were projected back to boundary
    reProjectedPoints = 0;
    for i = 1:length(dlcTime)
        if isnan(dlcHeadX_clean(i)) && ~isnan(dlcHeadX_interp(i))
            interpDist = sqrt((dlcHeadX_interp(i) - mazeCenter(1))^2 + (dlcHeadY_interp(i) - mazeCenter(2))^2);
            if interpDist <= mazeRadiusExpanded * 0.96 % Close to boundary indicates projection
                reProjectedPoints = reProjectedPoints + 1;
            end
        end
    end
    
    fprintf('Spatially-constrained interpolation completed:\n');
    fprintf('  Cleaned %d problematic head frames\n', sum(problematicFrames));
    fprintf('  Interpolated based on %d valid frames\n', sum(validFrames));
    fprintf('  Projected %d interpolated points back to maze boundary\n', reProjectedPoints);
else
    fprintf('Warning: Too few valid frames for interpolation!\n');
    dlcHeadX_interp = dlcHeadX;
    dlcHeadY_interp = dlcHeadY;
    dlcCenterX_interp = dlcCenterX;
    dlcCenterY_interp = dlcCenterY;
    dlcTailX_interp = dlcTailX;
    dlcTailY_interp = dlcTailY;
end

% Recalculate distances after cleaning using expanded radius
headDistances_clean = sqrt((dlcHeadX_interp - mazeCenter(1)).^2 + (dlcHeadY_interp - mazeCenter(2)).^2);
outsideFrames_clean = sum(headDistances_clean > mazeRadiusExpanded);

% Verify interpolation quality
interpolatedFrames = isnan(dlcHeadX_clean) & ~isnan(dlcHeadX_interp);
interpolatedOutside = sum(headDistances_clean(interpolatedFrames) > mazeRadiusExpanded);

fprintf('Results after spatially-constrained cleaning (using 1.1x expanded radius):\n');
fprintf('  Original outside maze: %d frames (%.1f%%)\n', sum(headDistances > mazeRadiusExpanded), sum(headDistances > mazeRadiusExpanded)/length(headDistances)*100);
fprintf('  Cleaned outside maze: %d frames (%.1f%%)\n', outsideFrames_clean, outsideFrames_clean/length(headDistances_clean)*100);
fprintf('  Interpolated frames: %d total, %d outside maze (%.1f%%)\n', ...
    sum(interpolatedFrames), interpolatedOutside, interpolatedOutside/max(1,sum(interpolatedFrames))*100);

if interpolatedOutside == 0
    fprintf('✅ SUCCESS: All interpolated points are within maze boundary!\n');
elseif interpolatedOutside/sum(interpolatedFrames)*100 < 1
    fprintf('✅ GOOD: <1%% of interpolated points outside maze\n');
else
    fprintf('⚠️  ATTENTION: %.1f%% of interpolated points still outside maze\n', interpolatedOutside/sum(interpolatedFrames)*100);
end

fprintf('Confidence Statistics:\n');
fprintf('  Head   - Mean: %.3f, Low confidence frames: %d (%.1f%%)\n', ...
    meanHeadConf, lowConfHeadFrames, lowConfHeadFrames/length(dlcHeadConf)*100);
fprintf('  Center - Mean: %.3f, Low confidence frames: %d (%.1f%%)\n', ...
    meanCenterConf, lowConfCenterFrames, lowConfCenterFrames/length(dlcCenterConf)*100);
fprintf('  Tail   - Mean: %.3f, Low confidence frames: %d (%.1f%%)\n', ...
    meanTailConf, lowConfTailFrames, lowConfTailFrames/length(dlcTailConf)*100);

% Count frames outside maze (original data using expanded radius)
outsideHeadFrames = sum(headDistances > mazeRadiusExpanded);

fprintf('\nSpatial Analysis (Using 1.1x Expanded Radius):\n');
fprintf('  Head   - Outside expanded maze: %d frames (%.1f%%)\n', ...
    outsideHeadFrames, outsideHeadFrames/length(headDistances)*100);

%% Create comprehensive visualization
fprintf('\n=== CREATING VISUALIZATION ===\n');

figure('Name', sprintf('DLC Tracking Inspection: %s', selectedSession), ...
       'Position', [50, 50, 1600, 1200]);

% Subplot 1: Original tracking data with outliers
subplot(3, 3, 1);
hold on;

% Plot all points with transparency based on confidence
scatter(dlcHeadX, dlcHeadY, 15, dlcHeadConf, 'filled', 'o', 'MarkerFaceAlpha', 0.6);
colormap(gca, 'hot');
cb1 = colorbar;
cb1.Label.String = 'Head Confidence';

% Draw maze boundary (using expanded radius)
theta = linspace(0, 2*pi, 100);
mazeX = mazeCenter(1) + mazeRadiusExpanded * cos(theta);
mazeY = mazeCenter(2) + mazeRadiusExpanded * sin(theta);
plot(mazeX, mazeY, 'b-', 'LineWidth', 2);

% Mark maze center
plot(mazeCenter(1), mazeCenter(2), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');

% Highlight different types of outliers
if any(distanceOutliers)
    scatter(dlcHeadX(distanceOutliers), dlcHeadY(distanceOutliers), 80, 'red', 'x', 'LineWidth', 2);
end
if any(velocityOutliers)
    scatter(dlcHeadX(velocityOutliers), dlcHeadY(velocityOutliers), 60, [1 0.5 0], 's', 'LineWidth', 2);
end

xlabel('X coordinate (pixels)');
ylabel('Y coordinate (pixels)');
title('Original Head Tracking');
legend('Tracking points', 'Maze boundary', 'Center', 'Distance outliers', 'Velocity outliers', 'Location', 'bestoutside');
axis equal;
grid on;

% Subplot 2: Cleaned and interpolated data with spatial verification
subplot(3, 3, 2);
hold on;

% Plot cleaned/interpolated points with different markers for different types
validPoints = ~problematicFrames;
interpolatedFrames = isnan(dlcHeadX_clean) & ~isnan(dlcHeadX_interp);
originalValidPoints = validPoints & ~interpolatedFrames;

scatter(dlcHeadX_interp(originalValidPoints), dlcHeadY_interp(originalValidPoints), 15, 'green', 'filled', 'o', 'MarkerFaceAlpha', 0.7);
scatter(dlcHeadX_interp(interpolatedFrames), dlcHeadY_interp(interpolatedFrames), 20, 'blue', 'filled', 's', 'MarkerFaceAlpha', 0.8);

% Highlight any interpolated points that are still outside (should be none)
interpolatedOutsideIdx = interpolatedFrames & (headDistances_clean > mazeRadiusExpanded);
if any(interpolatedOutsideIdx)
    scatter(dlcHeadX_interp(interpolatedOutsideIdx), dlcHeadY_interp(interpolatedOutsideIdx), 30, 'red', 'x', 'LineWidth', 3);
end

% Draw maze boundary
plot(mazeX, mazeY, 'b-', 'LineWidth', 2);
plot(mazeCenter(1), mazeCenter(2), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');

xlabel('X coordinate (pixels)');
ylabel('Y coordinate (pixels)');
title('Spatially-Constrained Cleaned Data');
if any(interpolatedOutsideIdx)
    legend('Original valid', 'Interpolated (constrained)', 'Interpolated outside!', 'Maze boundary', 'Center', 'Location', 'bestoutside');
else
    legend('Original valid', 'Interpolated (constrained)', 'Maze boundary', 'Center', 'Location', 'bestoutside');
end
axis equal;
grid on;

% Subplot 3: Outlier detection timeline
subplot(3, 3, 3);
hold on;
plot(dlcTime, double(distanceOutliers), 'r-', 'LineWidth', 1.5, 'DisplayName', 'Distance outliers');
plot(dlcTime, double(velocityOutliers), 'g-', 'LineWidth', 1.5, 'DisplayName', 'Velocity outliers');
plot(dlcTime, double(lowConfidenceFrames), 'b-', 'LineWidth', 1.5, 'DisplayName', 'Low confidence');
plot(dlcTime, double(problematicFrames), 'k-', 'LineWidth', 2, 'DisplayName', 'Any problem');

xlabel('Frame number');
ylabel('Problem detected');
title('Outlier Detection Timeline');
legend('Location', 'bestoutside');
ylim([-0.1, 1.1]);
grid on;

% Subplot 4: Distance comparison (original vs cleaned)
subplot(3, 3, 4);
plot(dlcTime, headDistances, 'r-', 'LineWidth', 1, 'DisplayName', 'Original');
hold on;
plot(dlcTime, headDistances_clean, 'g-', 'LineWidth', 1.5, 'DisplayName', 'Cleaned');
yline(mazeRadiusExpanded, 'b--', 'LineWidth', 2, 'DisplayName', 'Expanded maze boundary');

xlabel('Frame number');
ylabel('Distance from center (pixels)');
title('Distance Comparison');
legend('Location', 'bestoutside');
grid on;

% Subplot 5: Velocity analysis
subplot(3, 3, 5);
histogram(headVelocity, 50, 'FaceColor', 'red', 'FaceAlpha', 0.7, 'DisplayName', 'Original velocity');
hold on;
cleanedVelocity = sqrt(diff(dlcHeadX_interp).^2 + diff(dlcHeadY_interp).^2);
histogram(cleanedVelocity, 50, 'FaceColor', 'green', 'FaceAlpha', 0.7, 'DisplayName', 'Cleaned velocity');
xline(highVelocityThreshold, 'k--', 'LineWidth', 2, 'DisplayName', 'Velocity threshold');

xlabel('Velocity (pixels/frame)');
ylabel('Frame count');
title('Velocity Distribution');
legend('Location', 'bestoutside');
grid on;

% Subplot 6: Confidence over time
subplot(3, 3, 6);
plot(dlcTime, dlcHeadConf, 'g-', 'LineWidth', 1);
hold on;
plot(dlcTime, dlcCenterConf, 'b-', 'LineWidth', 1);
plot(dlcTime, dlcTailConf, 'r-', 'LineWidth', 1);
yline(lowConfThreshold, 'k--', 'LineWidth', 1, 'DisplayName', 'Low confidence threshold');

xlabel('Frame number');
ylabel('Confidence');
title('DLC Confidence Over Time');
legend('Head', 'Center', 'Tail', 'Threshold', 'Location', 'bestoutside');
ylim([0, 1]);
grid on;

% Subplot 7: Distance histogram comparison
subplot(3, 3, 7);
histogram(headDistances, 50, 'FaceColor', 'red', 'FaceAlpha', 0.7, 'DisplayName', 'Original');
hold on;
histogram(headDistances_clean, 50, 'FaceColor', 'green', 'FaceAlpha', 0.7, 'DisplayName', 'Cleaned');
xline(mazeRadiusExpanded, 'b--', 'LineWidth', 2, 'DisplayName', 'Expanded maze boundary');

xlabel('Distance from center (pixels)');
ylabel('Frame count');
title('Distance Distribution Comparison');
legend('Location', 'bestoutside');
grid on;

% Subplot 8: Body part tracking quality
subplot(3, 3, 8);
bodyPartData = [sum(dlcHeadConf < lowConfThreshold), sum(dlcCenterConf < lowConfThreshold), sum(dlcTailConf < lowConfThreshold); ...
                sum(dlcHeadConf >= lowConfThreshold), sum(dlcCenterConf >= lowConfThreshold), sum(dlcTailConf >= lowConfThreshold)];
bar(bodyPartData', 'stacked');
set(gca, 'XTickLabel', {'Head', 'Center', 'Tail'});
ylabel('Frame count');
title('Confidence Quality by Body Part');
legend('Low confidence', 'Good confidence', 'Location', 'bestoutside');
grid on;

% Subplot 9: Cleaning effectiveness summary
subplot(3, 3, 9);
beforeAfterData = [sum(headDistances > mazeRadiusExpanded), outsideFrames_clean; ...
                   sum(problematicFrames), 0; ...
                   length(dlcTime) - sum(problematicFrames), length(dlcTime)];
bar(beforeAfterData', 'grouped');
set(gca, 'XTickLabel', {'Outside Maze', 'Problematic', 'Valid'});
ylabel('Frame count');
title('Cleaning Effectiveness');
legend('Before', 'After', 'Location', 'bestoutside');
grid on;

% Add overall statistics text
sgtitle(sprintf('Session: %s | Frames: %d | Original outside: %.1f%% | Cleaned outside: %.1f%% | Problematic: %.1f%%', ...
    selectedSession, length(dlcTime), ...
    outsideHeadFrames/length(headDistances)*100, ...
    outsideFrames_clean/length(headDistances_clean)*100, ...
    sum(problematicFrames)/length(dlcTime)*100), ...
    'FontSize', 12, 'FontWeight', 'bold');

%% Summary and recommendations
fprintf('\n=== SUMMARY AND RECOMMENDATIONS ===\n');

fprintf('Data Quality Assessment (using 1.1x expanded radius):\n');
fprintf('  Original data - Outside expanded maze: %.1f%%, Low confidence: %.1f%%\n', ...
    outsideHeadFrames/length(headDistances)*100, lowConfHeadFrames/length(dlcHeadConf)*100);
fprintf('  Cleaned data  - Outside expanded maze: %.1f%%, Improvement: %.1f%%\n', ...
    outsideFrames_clean/length(headDistances_clean)*100, ...
    (outsideHeadFrames - outsideFrames_clean)/length(headDistances)*100);

if outsideFrames_clean/length(headDistances_clean)*100 < 5
    fprintf('✅ EXCELLENT: Cleaning achieved <5%% outside maze\n');
elseif outsideFrames_clean/length(headDistances_clean)*100 < 10
    fprintf('✅ GOOD: Cleaning achieved <10%% outside maze\n');
elseif outsideFrames_clean/length(headDistances_clean)*100 < 20
    fprintf('⚠️  MODERATE: Still %.1f%% outside maze after cleaning\n', ...
        outsideFrames_clean/length(headDistances_clean)*100);
else
    fprintf('❌ POOR: High percentage still outside maze (%.1f%%)\n', ...
        outsideFrames_clean/length(headDistances_clean)*100);
end

fprintf('\nCleaning Statistics:\n');
fprintf('  Distance outliers removed: %d frames\n', sum(distanceOutliers));
fprintf('  Velocity outliers removed: %d frames\n', sum(velocityOutliers));
fprintf('  Low confidence frames cleaned: %d frames\n', sum(lowConfidenceFrames));
fprintf('  Total frames interpolated: %d frames (%.1f%%)\n', ...
    sum(problematicFrames), sum(problematicFrames)/length(dlcTime)*100);

fprintf('\nRecommendations for CLOI_GetDLCData.m implementation:\n');
if sum(problematicFrames)/length(dlcTime)*100 > 20
    fprintf('1. ⚠️  High percentage of problematic frames - consider stricter thresholds\n');
else
    fprintf('1. ✅ Reasonable percentage of problematic frames\n');
end

fprintf('2. Implement confidence threshold: %.1f (removes %.1f%% of frames)\n', ...
    lowConfThreshold, sum(lowConfidenceFrames)/length(dlcTime)*100);
fprintf('3. Implement distance threshold: %.1f pixels (removes %.1f%% of frames)\n', ...
    extremeDistanceThreshold, sum(distanceOutliers)/length(dlcTime)*100);
fprintf('4. Implement velocity threshold: %.1f pixels/frame (removes %.1f%% of frames)\n', ...
    highVelocityThreshold, sum(velocityOutliers)/length(dlcTime)*100);
fprintf('5. Use linear interpolation for gap filling\n');

fprintf('\nNext steps:\n');
fprintf('1. Review the 9-panel visualization above\n');
fprintf('2. Adjust thresholds based on your requirements\n');
fprintf('3. Implement the cleaning logic in CLOI_GetDLCData.m\n');
fprintf('4. Test on multiple sessions to validate performance\n');

fprintf('\nInspection complete!\n');
