%% Visualize DLC Points Outside Maze Boundaries
% Show actual video frames with DLC tracking points that are outside maze boundaries
clear; close all;

fprintf('=== VISUALIZING DLC POINTS OUTSIDE MAZE ===\n');

% Load data
baseDir = 'H:\FREQ';
[sessionData, analysisData, miniAnalysisData] = CLOI_LoadData_FREQ(baseDir, 60, 10);

% Select session to analyze (start with first session)
sessionIdx = 1;
session = sessionData(sessionIdx);
analysis = analysisData(sessionIdx);

fprintf('Analyzing session: %s\n', session.sessionName);
fprintf('Maze center: (%.1f, %.1f) cm, Radius: %.1f cm\n', ...
    session.mazeCenter(1), session.mazeCenter(2), session.mazeRadius);

% Get head and body positions
headPos = analysis.headPos;
bodyPos = analysis.bodyPos;

% Calculate distances from maze center
headDistances = sqrt(sum((headPos(:,1:2) - session.mazeCenter(:)').^2, 2));
bodyDistances = sqrt(sum((bodyPos(:,1:2) - session.mazeCenter(:)').^2, 2));

% Find frames where tracking is outside maze
outsideHeadFrames = find(headDistances > session.mazeRadius);
outsideBodyFrames = find(bodyDistances > session.mazeRadius);
outsideFrames = unique([outsideHeadFrames; outsideBodyFrames]);

fprintf('Found %d frames with head outside maze (%.1f%%)\n', ...
    length(outsideHeadFrames), length(outsideHeadFrames)/length(headDistances)*100);
fprintf('Found %d frames with body outside maze (%.1f%%)\n', ...
    length(outsideBodyFrames), length(outsideBodyFrames)/length(bodyDistances)*100);
fprintf('Total frames with tracking outside maze: %d (%.1f%%)\n', ...
    length(outsideFrames), length(outsideFrames)/length(headDistances)*100);

if isempty(outsideFrames)
    fprintf('No frames found with tracking outside maze boundaries!\n');
    return;
end

% Load video file to extract frames
videoPath = fullfile(baseDir, session.sessionName, [session.sessionName '.mp4']);
if ~isfile(videoPath)
    % Try alternative video formats
    videoPath = fullfile(baseDir, session.sessionName, [session.sessionName '.avi']);
    if ~isfile(videoPath)
        fprintf('Warning: Video file not found. Creating visualization without video frames.\n');
        videoPath = '';
    end
end

% Create visualization
figure('Position', [100, 100, 1400, 800]);

% Select a few representative frames to show
numFramesToShow = min(6, length(outsideFrames));
framesToShow = outsideFrames(round(linspace(1, length(outsideFrames), numFramesToShow)));

for i = 1:numFramesToShow
    frameIdx = framesToShow(i);
    
    subplot(2, 3, i);
    
    if ~isempty(videoPath)
        try
            % Read video frame
            v = VideoReader(videoPath);
            v.CurrentTime = (frameIdx-1) / v.FrameRate;
            videoFrame = readFrame(v);
            
            % Display video frame
            imshow(videoFrame);
            hold on;
            
            % Convert cm coordinates back to pixel coordinates for overlay
            % Since we don't know the original pixel coordinates, we'll estimate
            % Assume original maze was around 280 pixels radius (typical)
            estimatedOriginalRadius = 280;
            scaleBackFactor = estimatedOriginalRadius / 30;  % Convert cm back to pixels
            
            % Convert back to pixels for overlay
            headPosPixels = headPos(frameIdx, 1:2) * scaleBackFactor;
            bodyPosPixels = bodyPos(frameIdx, 1:2) * scaleBackFactor;
            mazeCenterPixels = session.mazeCenter * scaleBackFactor;
            mazeRadiusPixels = session.mazeRadius * scaleBackFactor;
            
        catch ME
            fprintf('Warning: Could not read video frame %d: %s\n', frameIdx, ME.message);
            % Create blank image
            axis([0 1000 0 1000]);
            set(gca, 'YDir', 'reverse');
            
            % Use cm coordinates directly
            headPosPixels = headPos(frameIdx, 1:2);
            bodyPosPixels = bodyPos(frameIdx, 1:2);
            mazeCenterPixels = session.mazeCenter;
            mazeRadiusPixels = session.mazeRadius;
        end
    else
        % Create coordinate plot without video
        axis([0 200 0 200]);
        set(gca, 'YDir', 'reverse');
        grid on;
        
        % Use cm coordinates
        headPosPixels = headPos(frameIdx, 1:2);
        bodyPosPixels = bodyPos(frameIdx, 1:2);
        mazeCenterPixels = session.mazeCenter;
        mazeRadiusPixels = session.mazeRadius;
    end
    
    % Draw maze boundary
    theta = linspace(0, 2*pi, 100);
    mazeX = mazeCenterPixels(1) + mazeRadiusPixels * cos(theta);
    mazeY = mazeCenterPixels(2) + mazeRadiusPixels * sin(theta);
    plot(mazeX, mazeY, 'r-', 'LineWidth', 2);
    
    % Draw DLC points
    plot(headPosPixels(1), headPosPixels(2), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
    plot(bodyPosPixels(1), bodyPosPixels(2), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    
    % Calculate distances for this frame
    headDist = headDistances(frameIdx);
    bodyDist = bodyDistances(frameIdx);
    
    % Add distance information
    title(sprintf('Frame %d\nHead: %.1f cm, Body: %.1f cm', frameIdx, headDist, bodyDist));
    
    % Highlight points outside maze
    if headDist > session.mazeRadius
        plot(headPosPixels(1), headPosPixels(2), 'ro', 'MarkerSize', 12, 'LineWidth', 2);
    end
    if bodyDist > session.mazeRadius
        plot(bodyPosPixels(1), bodyPosPixels(2), 'ro', 'MarkerSize', 12, 'LineWidth', 2);
    end
    
    hold off;
end

% Add overall legend
sgtitle(sprintf('DLC Points Outside Maze - %s\nMaze: (%.1f, %.1f) R%.1f cm', ...
    session.sessionName, session.mazeCenter(1), session.mazeCenter(2), session.mazeRadius));

% Create legend in separate subplot or figure
figure('Position', [1500, 400, 300, 200]);
hold on;
plot(0, 0, 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
plot(0, 0, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
plot(0, 0, 'r-', 'LineWidth', 2);
plot(0, 0, 'ro', 'MarkerSize', 12, 'LineWidth', 2);
legend({'Head (inside)', 'Body (inside)', 'Maze boundary', 'Outside maze'}, 'Location', 'best');
axis off;
title('Legend');

% Summary statistics
fprintf('\n=== SUMMARY STATISTICS ===\n');
fprintf('Session: %s\n', session.sessionName);
fprintf('Total frames analyzed: %d\n', length(headDistances));
fprintf('Frames with head outside: %d (%.2f%%)\n', length(outsideHeadFrames), length(outsideHeadFrames)/length(headDistances)*100);
fprintf('Frames with body outside: %d (%.2f%%)\n', length(outsideBodyFrames), length(outsideBodyFrames)/length(bodyDistances)*100);
fprintf('Max head distance: %.1f cm\n', max(headDistances));
fprintf('Max body distance: %.1f cm\n', max(bodyDistances));

% Distance distribution
figure('Position', [100, 900, 800, 300]);
subplot(1,2,1);
histogram(headDistances, 50);
xline(session.mazeRadius, 'r--', 'LineWidth', 2);
xlabel('Distance from center (cm)');
ylabel('Number of frames');
title('Head Position Distances');
legend('Head distances', 'Maze boundary');

subplot(1,2,2);
histogram(bodyDistances, 50);
xline(session.mazeRadius, 'r--', 'LineWidth', 2);
xlabel('Distance from center (cm)');
ylabel('Number of frames');
title('Body Position Distances');
legend('Body distances', 'Maze boundary');

fprintf('Visualization complete!\n');
