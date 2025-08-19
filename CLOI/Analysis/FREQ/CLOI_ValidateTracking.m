function CLOI_ValidateTracking(sessionData, analysisData, sessionIndex)
%CLOI_ValidateTracking Visual validation of DLC tracking and maze parameters
%
% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later
%
% This function displays 15 randomly selected frames from a session to
% visually validate DLC tracking accuracy and maze geometry parameters.
%
% Inputs:
%   sessionData - Session data struct from CLOI_LoadData_FREQ
%   analysisData - Analysis data struct from CLOI_LoadData_FREQ
%   sessionIndex - Index of the session to validate
%
% Example:
%   CLOI_ValidateTracking(sessionData, analysisData, 16); % ChAT_971-3 PARK session

if nargin < 3
    error('Please provide sessionData, analysisData, and sessionIndex');
end

if sessionIndex > length(sessionData)
    error('Session index %d exceeds available sessions (%d)', sessionIndex, length(sessionData));
end

% Get session info
sessionName = sessionData(sessionIndex).sessionName;
fprintf('Validating session: %s\n', sessionName);

% Get video file
sessionPath = fullfile(sessionData(sessionIndex).sessionName);
baseDir = "H:\FREQ"; % Adjust this if needed
videoPath = fullfile(baseDir, sessionPath, 'output_video.mp4');

if ~isfile(videoPath)
    error('Video file not found: %s', videoPath);
end

% Get maze parameters
CENTER = sessionData(sessionIndex).mazeCenter;
RADIUS = sessionData(sessionIndex).mazeRadius;
fprintf('Maze center: (%.1f, %.1f), Radius: %.1f\n', CENTER(1), CENTER(2), RADIUS);

% Get DLC tracking data
dsDLCframe = analysisData(sessionIndex).frameNum;
dsDLCHeadPos = analysisData(sessionIndex).headPos;
dsDLCBodyPos = analysisData(sessionIndex).bodyPos;

fprintf('DLC data: %d frames, Head pos range X: %.1f-%.1f, Y: %.1f-%.1f\n', ...
    length(dsDLCframe), min(dsDLCHeadPos(:,1)), max(dsDLCHeadPos(:,1)), ...
    min(dsDLCHeadPos(:,2)), max(dsDLCHeadPos(:,2)));

% Open video
videoObj = VideoReader(videoPath);
totalFrames = videoObj.NumFrames;
fprintf('Video: %d total frames, %.1f FPS\n', totalFrames, videoObj.FrameRate);

% Select 15 random frames that have corresponding DLC data
validFrameIndices = find(dsDLCframe <= totalFrames & dsDLCframe >= 1);
if length(validFrameIndices) < 15
    warning('Only %d valid frames available, using all of them', length(validFrameIndices));
    selectedIndices = validFrameIndices;
else
    % Randomly select 15 indices
    selectedIndices = randsample(validFrameIndices, 15);
end
selectedIndices = sort(selectedIndices);

% Create figure with 3x5 subplot layout
figure('Position', [50, 50, 1400, 900]);
sgtitle(sprintf('DLC Tracking Validation: %s', sessionName), 'Interpreter', 'none', 'FontSize', 14);

for i = 1:length(selectedIndices)
    dlcIdx = selectedIndices(i);
    frameNum = dsDLCframe(dlcIdx);
    
    % Read the frame
    videoObj.CurrentTime = (frameNum - 1) / videoObj.FrameRate;
    frame = readFrame(videoObj);
    
    % Get DLC positions for this frame
    headPos = dsDLCHeadPos(dlcIdx, 1:2);
    bodyPos = dsDLCBodyPos(dlcIdx, 1:2);
    
    % Create subplot
    subplot(3, 5, i);
    imshow(frame);
    hold on;
    
    % Draw maze center and radius
    % Draw circle manually if viscircles is not available
    theta = linspace(0, 2*pi, 100);
    circle_x = CENTER(1) + RADIUS * cos(theta);
    circle_y = CENTER(2) + RADIUS * sin(theta);
    plot(circle_x, circle_y, 'c-', 'LineWidth', 2);
    plot(CENTER(1), CENTER(2), 'c+', 'MarkerSize', 15, 'LineWidth', 3);
    
    % Draw inner radius (center region = RADIUS/2)
    inner_circle_x = CENTER(1) + (RADIUS/2) * cos(theta);
    inner_circle_y = CENTER(2) + (RADIUS/2) * sin(theta);
    plot(inner_circle_x, inner_circle_y, 'y--', 'LineWidth', 1);
    
    % Draw DLC head position
    plot(headPos(1), headPos(2), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'red', 'LineWidth', 2);
    
    % Draw DLC body position
    plot(bodyPos(1), bodyPos(2), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'green', 'LineWidth', 2);
    
    % Draw line connecting head and body
    plot([headPos(1), bodyPos(1)], [headPos(2), bodyPos(2)], 'b-', 'LineWidth', 2);
    
    % Calculate distance from center
    headDistFromCenter = sqrt(sum((headPos - CENTER(:)').^2));
    
    % Determine if in center region
    inCenterRegion = headDistFromCenter <= (RADIUS/2);
    if inCenterRegion
        regionText = 'CENTER';
        regionColor = 'yellow';
    else
        regionText = 'PERIPH';
        regionColor = 'magenta';
    end
    
    % Add frame info
    title(sprintf('Frame %d\nHead: (%.1f,%.1f)\nDist: %.1f [%s]', ...
        frameNum, headPos(1), headPos(2), headDistFromCenter, regionText), ...
        'FontSize', 9, 'Color', regionColor);
    
    % Add text annotations
    text(10, 30, 'Head', 'Color', 'red', 'FontSize', 8, 'FontWeight', 'bold', 'BackgroundColor', 'white');
    text(10, 50, 'Body', 'Color', 'green', 'FontSize', 8, 'FontWeight', 'bold', 'BackgroundColor', 'white');
    text(10, 70, 'Center', 'Color', 'cyan', 'FontSize', 8, 'FontWeight', 'bold', 'BackgroundColor', 'white');
    
    hold off;
    axis on;
end

% Add overall legend
axes('Position', [0.02, 0.02, 0.96, 0.05], 'Visible', 'off');
text(0.1, 0.5, '● Red: Head Position', 'Color', 'red', 'FontSize', 12, 'FontWeight', 'bold');
text(0.3, 0.5, '● Green: Body Position', 'Color', 'green', 'FontSize', 12, 'FontWeight', 'bold');
text(0.5, 0.5, '━ Cyan: Maze Boundary', 'Color', 'cyan', 'FontSize', 12, 'FontWeight', 'bold');
text(0.7, 0.5, '-- Yellow: Center Region', 'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold');
text(0.9, 0.5, '+ Cyan: Maze Center', 'Color', 'cyan', 'FontSize', 12, 'FontWeight', 'bold');

% Print summary statistics
fprintf('\n=== Validation Summary ===\n');
fprintf('Selected %d frames for validation\n', length(selectedIndices));
fprintf('Frame numbers: %s\n', sprintf('%d ', dsDLCframe(selectedIndices)));

% Print video and DLC coordinate ranges for debugging
fprintf('\n=== Coordinate System Debugging ===\n');
fprintf('Video dimensions: %d x %d pixels\n', videoObj.Width, videoObj.Height);
fprintf('DLC Head position ranges: X=[%.1f, %.1f], Y=[%.1f, %.1f]\n', ...
    min(dsDLCHeadPos(:,1)), max(dsDLCHeadPos(:,1)), ...
    min(dsDLCHeadPos(:,2)), max(dsDLCHeadPos(:,2)));
fprintf('DLC Body position ranges: X=[%.1f, %.1f], Y=[%.1f, %.1f]\n', ...
    min(dsDLCBodyPos(:,1)), max(dsDLCBodyPos(:,1)), ...
    min(dsDLCBodyPos(:,2)), max(dsDLCBodyPos(:,2)));
fprintf('Maze center: (%.1f, %.1f), Radius: %.1f\n', CENTER(1), CENTER(2), RADIUS);

% Check tracking quality
headPositions = dsDLCHeadPos(selectedIndices, 1:2);
bodyPositions = dsDLCBodyPos(selectedIndices, 1:2);

% Calculate distances from center
% Ensure CENTER is a row vector for proper broadcasting
centerRow = CENTER(:)'; % Convert to row vector [1 x 2]
headDistances = sqrt(sum((headPositions - centerRow).^2, 2));
bodyDistances = sqrt(sum((bodyPositions - centerRow).^2, 2));

fprintf('Head distances from center: Mean=%.1f, Range=%.1f-%.1f\n', ...
    mean(headDistances), min(headDistances), max(headDistances));
fprintf('Body distances from center: Mean=%.1f, Range=%.1f-%.1f\n', ...
    mean(bodyDistances), min(bodyDistances), max(bodyDistances));

% Check how many are in center vs peripheral regions
headInCenter = sum(headDistances <= RADIUS/2);
fprintf('Head positions: %d/%d in center region, %d/%d in peripheral region\n', ...
    headInCenter, length(headDistances), length(headDistances)-headInCenter, length(headDistances));

% Check for potential tracking errors (positions outside maze)
headOutsideMaze = sum(headDistances > RADIUS);
bodyOutsideMaze = sum(bodyDistances > RADIUS);
fprintf('Potential tracking issues: %d/%d head positions outside maze, %d/%d body positions outside maze\n', ...
    headOutsideMaze, length(headDistances), bodyOutsideMaze, length(bodyDistances));

fprintf('Validation complete!\n');

end
