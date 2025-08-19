%% Compare Normal vs Problematic Sessions
% Visual comparison of tracking patterns between normal and problematic sessions
clear; close all;

fprintf('=== COMPARING NORMAL VS PROBLEMATIC SESSIONS ===\n');

% Load data
baseDir = 'H:\FREQ';
[sessionData, analysisData, miniAnalysisData] = CLOI_LoadData_FREQ(baseDir, 60, 10);

% Select representative sessions
normalSession = 1;  % ChAT_946-2_Baseline (1.79% outside)
problematicSession = 16;  % ChAT_971-3_Parkinson (22.23% outside)

figure('Position', [100, 100, 1400, 600]);

sessions = [normalSession, problematicSession];
titles = {'Normal Session (1.79% head outside)', 'Problematic Session (22.23% head outside)'};

for i = 1:2
    sessionIdx = sessions(i);
    session = sessionData(sessionIdx);
    analysis = analysisData(sessionIdx);
    
    fprintf('\n--- %s ---\n', titles{i});
    fprintf('Session: %s\n', session.sessionName);
    fprintf('Maze center: (%.1f, %.1f) cm, Radius: %.1f cm\n', ...
        session.mazeCenter(1), session.mazeCenter(2), session.mazeRadius);
    
    % Get tracking data
    headPos = analysis.headPos;
    bodyPos = analysis.bodyPos;
    
    % Calculate distances
    headDistances = sqrt(sum((headPos(:,1:2) - session.mazeCenter(:)').^2, 2));
    bodyDistances = sqrt(sum((bodyPos(:,1:2) - session.mazeCenter(:)').^2, 2));
    
    outsideHeadFrames = find(headDistances > session.mazeRadius);
    outsideBodyFrames = find(bodyDistances > session.mazeRadius);
    
    fprintf('Head outside: %d frames (%.2f%%)\n', ...
        length(outsideHeadFrames), length(outsideHeadFrames)/length(headDistances)*100);
    fprintf('Body outside: %d frames (%.2f%%)\n', ...
        length(outsideBodyFrames), length(outsideBodyFrames)/length(bodyDistances)*100);
    fprintf('Coordinate range - X: [%.1f, %.1f], Y: [%.1f, %.1f]\n', ...
        min(headPos(:,1)), max(headPos(:,1)), min(headPos(:,2)), max(headPos(:,2)));
    
    % Plot position map
    subplot(2, 3, (i-1)*3 + 1);
    
    % Plot all positions
    scatter(headPos(:,1), headPos(:,2), 5, [0.7 0.7 0.7], 'filled');
    hold on;
    
    % Plot outside positions in red
    if ~isempty(outsideHeadFrames)
        scatter(headPos(outsideHeadFrames,1), headPos(outsideHeadFrames,2), 20, 'red', 'filled');
    end
    
    % Draw maze boundary
    theta = linspace(0, 2*pi, 100);
    mazeX = session.mazeCenter(1) + session.mazeRadius * cos(theta);
    mazeY = session.mazeCenter(2) + session.mazeRadius * sin(theta);
    plot(mazeX, mazeY, 'b-', 'LineWidth', 2);
    
    % Mark maze center
    plot(session.mazeCenter(1), session.mazeCenter(2), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    
    xlabel('X position (cm)');
    ylabel('Y position (cm)');
    title(sprintf('%s\nHead Positions', titles{i}));
    axis equal;
    grid on;
    
    % Set axis limits to show context
    if i == 2  % Problematic session - expand view
        xlim([min(headPos(:,1))-10, max(headPos(:,1))+10]);
        ylim([min(headPos(:,2))-10, max(headPos(:,2))+10]);
    else
        xlim([session.mazeCenter(1)-50, session.mazeCenter(1)+50]);
        ylim([session.mazeCenter(2)-50, session.mazeCenter(2)+50]);
    end
    
    % Distance timeline
    subplot(2, 3, (i-1)*3 + 2);
    timeVec = (1:length(headDistances)) / 25; % 25 fps
    plot(timeVec, headDistances, 'g-', 'LineWidth', 1);
    hold on;
    yline(session.mazeRadius, 'b--', 'LineWidth', 2);
    
    % Highlight outside periods
    if ~isempty(outsideHeadFrames)
        plot(timeVec(outsideHeadFrames), headDistances(outsideHeadFrames), 'ro', 'MarkerSize', 2);
    end
    
    xlabel('Time (s)');
    ylabel('Distance from center (cm)');
    title('Distance Timeline');
    legend('Head distance', 'Maze boundary', 'Outside maze');
    
    % Distance histogram
    subplot(2, 3, (i-1)*3 + 3);
    histogram(headDistances, 50, 'FaceColor', 'g', 'FaceAlpha', 0.7);
    hold on;
    xline(session.mazeRadius, 'b--', 'LineWidth', 2);
    
    % Mark outside threshold
    outsideDistances = headDistances(headDistances > session.mazeRadius);
    if ~isempty(outsideDistances)
        histogram(outsideDistances, 20, 'FaceColor', 'red', 'FaceAlpha', 0.7);
    end
    
    xlabel('Distance from center (cm)');
    ylabel('Frame count');
    title('Distance Distribution');
    legend('All distances', 'Maze boundary', 'Outside maze');
end

% Summary comparison
fprintf('\n=== COMPARISON SUMMARY ===\n');
fprintf('Normal session: Tracking mostly within maze, occasional brief excursions\n');
fprintf('Problematic session: Frequent tracking far outside maze boundaries\n');
fprintf('This suggests either real behavioral differences or tracking issues in Parkinson sessions.\n');

% Check if there's a pattern in maze center coordinates
fprintf('\n=== MAZE CENTER ANALYSIS ===\n');
fprintf('Session\t\tMaze Center (cm)\t\tType\n');
fprintf('-------\t\t---------------\t\t----\n');
for i = 1:length(sessionData)
    sessionType = 'BASE';
    if contains(sessionData(i).sessionName, 'Parkinson')
        sessionType = 'PARK';
    end
    fprintf('%d\t\t(%.1f, %.1f)\t\t\t%s\n', i, ...
        sessionData(i).mazeCenter(1), sessionData(i).mazeCenter(2), sessionType);
end

fprintf('\nAnalysis complete!\n');
