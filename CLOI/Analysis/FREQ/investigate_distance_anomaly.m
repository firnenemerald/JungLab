%% Investigate ChAT_971-3 PARK sessions high total distance
clear; close all;

% Load the data
baseDir = "H:\FREQ";
minisessionDuration = 60;
minisessionNum = 10;

[sessionData, analysisData, miniAnalysisData] = CLOI_LoadData_FREQ(baseDir, minisessionDuration, minisessionNum);

%% Find ChAT_971-3 sessions
fprintf('=== ChAT_971-3 Session Analysis ===\n');

% Find all ChAT_971-3 sessions
chatSessions = [];
for i = 1:length(miniAnalysisData)
    if contains(miniAnalysisData(i).mouseName, 'ChAT_971-3')
        chatSessions(end+1) = i;
        sessionType = 'Unknown';
        if contains(miniAnalysisData(i).sessionName, 'Baseline')
            sessionType = 'BASE';
        elseif contains(miniAnalysisData(i).sessionName, 'Parkinson')
            sessionType = 'PARK';
        end
        
        totalDist = miniAnalysisData(i).totalDistance;
        centerDist = miniAnalysisData(i).centerDistance;
        peripheralDist = miniAnalysisData(i).peripheralDistance;
        
        fprintf('Session %d: %s [%s]\n', i, miniAnalysisData(i).sessionName, sessionType);
        fprintf('  Total distances: %s\n', sprintf('%.1f ', totalDist));
        fprintf('  Center distances: %s\n', sprintf('%.1f ', centerDist));
        fprintf('  Peripheral distances: %s\n', sprintf('%.1f ', peripheralDist));
        fprintf('  Mean total distance: %.1f\n', mean(totalDist));
        
        % Check if total = center + peripheral
        validation = abs(totalDist - (centerDist + peripheralDist));
        fprintf('  Validation (should be ~0): %s\n', sprintf('%.3f ', validation));
        
        % Get head position data quality info
        headPos = analysisData(i).headPos;
        if ~isempty(headPos)
            fprintf('  Head position data: %d points\n', size(headPos, 1));
            fprintf('  Head pos range X: %.1f to %.1f\n', min(headPos(:,1)), max(headPos(:,1)));
            fprintf('  Head pos range Y: %.1f to %.1f\n', min(headPos(:,2)), max(headPos(:,2)));
            
            % Check for large jumps in position
            if size(headPos, 1) > 1
                posDiff = diff(headPos);
                segmentDist = sqrt(sum(posDiff.^2, 2));
                fprintf('  Segment distances - Mean: %.1f, Max: %.1f, Std: %.1f\n', ...
                    mean(segmentDist), max(segmentDist), std(segmentDist));
                
                % Count large jumps (>100 pixels)
                largeJumps = sum(segmentDist > 100);
                fprintf('  Large jumps (>100 pixels): %d out of %d segments\n', largeJumps, length(segmentDist));
                
                if largeJumps > 0
                    fprintf('  Large jump distances: %s\n', sprintf('%.1f ', segmentDist(segmentDist > 100)));
                end
            end
        end
        fprintf('\n');
    end
end

%% Compare with other mice for reference
fprintf('=== Comparison with other mice PARK sessions ===\n');
for i = 1:length(miniAnalysisData)
    if contains(miniAnalysisData(i).sessionName, 'Parkinson') && ~contains(miniAnalysisData(i).mouseName, 'ChAT_971-3')
        totalDist = miniAnalysisData(i).totalDistance;
        fprintf('%s: Mean total distance = %.1f\n', miniAnalysisData(i).mouseName, mean(totalDist));
    end
end

%% Plot individual session comparison
figure('Position', [100, 100, 1200, 800]);

% Get all PARK sessions
parkSessions = [];
parkLabels = {};
for i = 1:length(miniAnalysisData)
    if contains(miniAnalysisData(i).sessionName, 'Parkinson')
        parkSessions(end+1) = i;
        parkLabels{end+1} = miniAnalysisData(i).sessionName;
    end
end

if ~isempty(parkSessions)
    subplot(2, 1, 1);
    hold on;
    colors = lines(length(parkSessions));
    
    for i = 1:length(parkSessions)
        sessionIdx = parkSessions(i);
        totalDist = miniAnalysisData(sessionIdx).totalDistance;
        plot(1:10, totalDist, 'o-', 'Color', colors(i,:), 'LineWidth', 2, 'MarkerSize', 6);
    end
    
    xlabel('Minisession Number');
    ylabel('Total Distance (pixels)');
    title('Individual PARK Sessions - Total Distance');
    legend(parkLabels, 'Location', 'bestoutside', 'Interpreter', 'none');
    grid on;
    
    % Plot on log scale to see patterns better
    subplot(2, 1, 2);
    hold on;
    
    for i = 1:length(parkSessions)
        sessionIdx = parkSessions(i);
        totalDist = miniAnalysisData(sessionIdx).totalDistance;
        semilogy(1:10, totalDist, 'o-', 'Color', colors(i,:), 'LineWidth', 2, 'MarkerSize', 6);
    end
    
    xlabel('Minisession Number');
    ylabel('Total Distance (pixels) - Log Scale');
    title('Individual PARK Sessions - Total Distance (Log Scale)');
    legend(parkLabels, 'Location', 'bestoutside', 'Interpreter', 'none');
    grid on;
end

fprintf('Investigation completed!\n');
