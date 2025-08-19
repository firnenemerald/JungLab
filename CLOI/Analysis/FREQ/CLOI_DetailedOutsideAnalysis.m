%% Detailed Analysis of DLC Points Outside Maze
% Analyze temporal patterns and characteristics of outside-maze tracking events
clear; close all;

fprintf('=== DETAILED ANALYSIS OF OUTSIDE-MAZE TRACKING ===\n');

% Load data
baseDir = 'H:\FREQ';
[sessionData, analysisData, miniAnalysisData] = CLOI_LoadData_FREQ(baseDir, 60, 10);

% Analyze multiple sessions to see patterns
sessionsToAnalyze = min(3, length(sessionData));

figure('Position', [100, 100, 1600, 1000]);

for sessionIdx = 1:sessionsToAnalyze
    session = sessionData(sessionIdx);
    analysis = analysisData(sessionIdx);
    
    fprintf('\n--- Session %d: %s ---\n', sessionIdx, session.sessionName);
    fprintf('Maze center: (%.1f, %.1f) cm, Radius: %.1f cm\n', ...
        session.mazeCenter(1), session.mazeCenter(2), session.mazeRadius);
    
    % Get tracking data
    headPos = analysis.headPos;
    bodyPos = analysis.bodyPos;
    
    % Calculate distances from maze center
    headDistances = sqrt(sum((headPos(:,1:2) - session.mazeCenter(:)').^2, 2));
    bodyDistances = sqrt(sum((bodyPos(:,1:2) - session.mazeCenter(:)').^2, 2));
    
    % Find outside frames
    outsideHeadFrames = find(headDistances > session.mazeRadius);
    outsideBodyFrames = find(bodyDistances > session.mazeRadius);
    
    fprintf('Head outside maze: %d frames (%.2f%%)\n', ...
        length(outsideHeadFrames), length(outsideHeadFrames)/length(headDistances)*100);
    fprintf('Body outside maze: %d frames (%.2f%%)\n', ...
        length(outsideBodyFrames), length(outsideBodyFrames)/length(bodyDistances)*100);
    
    % Plot 1: Distance timeline
    subplot(sessionsToAnalyze, 4, (sessionIdx-1)*4 + 1);
    timeVec = (1:length(headDistances)) / 25; % Assuming 25 fps
    plot(timeVec, headDistances, 'g-', 'LineWidth', 1);
    hold on;
    plot(timeVec, bodyDistances, 'b-', 'LineWidth', 1);
    yline(session.mazeRadius, 'r--', 'LineWidth', 2);
    
    % Highlight outside periods
    if ~isempty(outsideHeadFrames)
        plot(timeVec(outsideHeadFrames), headDistances(outsideHeadFrames), 'ro', 'MarkerSize', 3);
    end
    if ~isempty(outsideBodyFrames)
        plot(timeVec(outsideBodyFrames), bodyDistances(outsideBodyFrames), 'ro', 'MarkerSize', 3);
    end
    
    xlabel('Time (s)');
    ylabel('Distance (cm)');
    title(sprintf('Session %d: Distance Timeline', sessionIdx));
    legend('Head', 'Body', 'Maze boundary', 'Outside', 'Location', 'best');
    ylim([0, max([headDistances; bodyDistances]) + 5]);
    
    % Plot 2: Position scatter
    subplot(sessionsToAnalyze, 4, (sessionIdx-1)*4 + 2);
    scatter(headPos(:,1), headPos(:,2), 20, headDistances, 'filled', 'o');
    hold on;
    scatter(bodyPos(:,1), bodyPos(:,2), 20, bodyDistances, 'filled', 's');
    
    % Draw maze boundary
    theta = linspace(0, 2*pi, 100);
    mazeX = session.mazeCenter(1) + session.mazeRadius * cos(theta);
    mazeY = session.mazeCenter(2) + session.mazeRadius * sin(theta);
    plot(mazeX, mazeY, 'r-', 'LineWidth', 2);
    
    % Highlight outside points
    if ~isempty(outsideHeadFrames)
        scatter(headPos(outsideHeadFrames,1), headPos(outsideHeadFrames,2), 50, 'r', 'filled', '^');
    end
    if ~isempty(outsideBodyFrames)
        scatter(bodyPos(outsideBodyFrames,1), bodyPos(outsideBodyFrames,2), 50, 'r', 'filled', 'v');
    end
    
    colorbar;
    xlabel('X position (cm)');
    ylabel('Y position (cm)');
    title(sprintf('Session %d: Position Map', sessionIdx));
    axis equal;
    
    % Plot 3: Distance histogram
    subplot(sessionsToAnalyze, 4, (sessionIdx-1)*4 + 3);
    histogram(headDistances, 30, 'FaceColor', 'g', 'FaceAlpha', 0.7);
    hold on;
    histogram(bodyDistances, 30, 'FaceColor', 'b', 'FaceAlpha', 0.7);
    xline(session.mazeRadius, 'r--', 'LineWidth', 2);
    xlabel('Distance from center (cm)');
    ylabel('Frame count');
    title(sprintf('Session %d: Distance Distribution', sessionIdx));
    legend('Head', 'Body', 'Maze boundary');
    
    % Plot 4: Outside events analysis
    subplot(sessionsToAnalyze, 4, (sessionIdx-1)*4 + 4);
    
    % Analyze temporal clustering of outside events
    allOutsideFrames = unique([outsideHeadFrames; outsideBodyFrames]);
    
    if ~isempty(allOutsideFrames)
        % Find continuous segments of outside frames
        frameGaps = diff(allOutsideFrames);
        segmentBreaks = find(frameGaps > 1);
        
        segmentStarts = [allOutsideFrames(1); allOutsideFrames(segmentBreaks + 1)];
        segmentEnds = [allOutsideFrames(segmentBreaks); allOutsideFrames(end)];
        segmentDurations = segmentEnds - segmentStarts + 1;
        
        fprintf('Number of outside-maze segments: %d\n', length(segmentStarts));
        fprintf('Average segment duration: %.1f frames (%.2f s)\n', ...
            mean(segmentDurations), mean(segmentDurations)/25);
        fprintf('Longest segment: %d frames (%.2f s)\n', ...
            max(segmentDurations), max(segmentDurations)/25);
        
        % Plot segment durations
        histogram(segmentDurations, min(20, length(segmentDurations)));
        xlabel('Segment duration (frames)');
        ylabel('Count');
        title(sprintf('Session %d: Outside Segments', sessionIdx));
        
        % Add statistics as text
        text(0.6, 0.8, sprintf('Segments: %d\nAvg: %.1f frames\nMax: %d frames', ...
            length(segmentStarts), mean(segmentDurations), max(segmentDurations)), ...
            'Units', 'normalized', 'BackgroundColor', 'white');
    else
        text(0.5, 0.5, 'No outside-maze events', 'HorizontalAlignment', 'center', ...
            'Units', 'normalized', 'FontSize', 12);
        title(sprintf('Session %d: No Outside Events', sessionIdx));
    end
end

sgtitle('DLC Tracking Outside Maze Analysis - Multiple Sessions');

% Create summary statistics table
fprintf('\n=== SUMMARY TABLE ===\n');
fprintf('Session\t\tHead_Outside%%\tBody_Outside%%\tMax_Head_Dist\tMax_Body_Dist\n');
fprintf('-------\t\t------------\t------------\t------------\t------------\n');

for sessionIdx = 1:length(sessionData)
    session = sessionData(sessionIdx);
    analysis = analysisData(sessionIdx);
    
    headPos = analysis.headPos;
    bodyPos = analysis.bodyPos;
    
    headDistances = sqrt(sum((headPos(:,1:2) - session.mazeCenter(:)').^2, 2));
    bodyDistances = sqrt(sum((bodyPos(:,1:2) - session.mazeCenter(:)').^2, 2));
    
    outsideHeadFrames = find(headDistances > session.mazeRadius);
    outsideBodyFrames = find(bodyDistances > session.mazeRadius);
    
    fprintf('%d\t\t%.2f%%\t\t%.2f%%\t\t%.1f cm\t\t%.1f cm\n', ...
        sessionIdx, ...
        length(outsideHeadFrames)/length(headDistances)*100, ...
        length(outsideBodyFrames)/length(bodyDistances)*100, ...
        max(headDistances), ...
        max(bodyDistances));
end

fprintf('\nAnalysis complete!\n');
