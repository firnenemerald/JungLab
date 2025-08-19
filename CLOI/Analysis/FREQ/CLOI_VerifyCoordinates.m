%% Coordinate Match Verification
% Verify that head and body positions are within maze boundaries after coordinate fix
clear; close all;

fprintf('=== COORDINATE MATCH VERIFICATION ===\n');
fprintf('Checking if head/body positions are within maze boundaries\n\n');

% Load data with automatic coordinate fix
baseDir = 'H:\FREQ';
[sessionData, analysisData, miniAnalysisData] = CLOI_LoadData_FREQ(baseDir, 60, 10);

% Check coordinate alignment for all sessions
fprintf('Session Analysis:\n');
fprintf('ID\tMouse\t\tType\tMaze(cm)\t\tHead_In_Maze\tBody_In_Maze\tStatus\n');
fprintf('--\t-----\t\t----\t--------\t\t------------\t------------\t------\n');

overallStatus = true;
allHeadInMaze = [];
allBodyInMaze = [];

for i = 1:length(sessionData)
    % Get session info
    mouseName = sessionData(i).mouseName;
    sessionType = 'BASE';
    if contains(sessionData(i).sessionName, 'Parkinson')
        sessionType = 'PARK';
    end
    
    % Get maze parameters
    CENTER = sessionData(i).mazeCenter;
    RADIUS = sessionData(i).mazeRadius;
    
    % Get tracking data
    if i <= length(analysisData)
        headPos = analysisData(i).headPos;
        bodyPos = analysisData(i).bodyPos;
        
        if ~isempty(headPos) && ~isempty(bodyPos)
            % Calculate distances from center for all positions
            headDistances = sqrt(sum((headPos(:,1:2) - CENTER(:)').^2, 2));
            bodyDistances = sqrt(sum((bodyPos(:,1:2) - CENTER(:)').^2, 2));
            
            % Check how many positions are within maze boundary
            headInMaze = sum(headDistances <= RADIUS) / length(headDistances) * 100;
            bodyInMaze = sum(bodyDistances <= RADIUS) / length(bodyDistances) * 100;
            
            % Store for overall statistics
            allHeadInMaze(end+1) = headInMaze;
            allBodyInMaze(end+1) = bodyInMaze;
            
            % Determine status
            if headInMaze > 80 && bodyInMaze > 80  % At least 80% should be within maze
                status = 'GOOD';
            elseif headInMaze > 50 && bodyInMaze > 50
                status = 'OK';
                overallStatus = false;
            else
                status = 'BAD';
                overallStatus = false;
            end
            
            fprintf('%2d\t%s\t%s\t(%.0f,%.0f) R%.0f\t%.1f%%\t\t%.1f%%\t\t%s\n', ...
                i, mouseName, sessionType, CENTER(1), CENTER(2), RADIUS, ...
                headInMaze, bodyInMaze, status);
        else
            fprintf('%2d\t%s\t%s\t(%.0f,%.0f) R%.0f\tNo Data\t\tNo Data\t\tSKIP\n', ...
                i, mouseName, sessionType, CENTER(1), CENTER(2), RADIUS);
        end
    end
end

% Overall summary
fprintf('\n=== OVERALL COORDINATE ALIGNMENT SUMMARY ===\n');
fprintf('Average head positions in maze: %.1f%% ± %.1f%%\n', mean(allHeadInMaze), std(allHeadInMaze));
fprintf('Average body positions in maze: %.1f%% ± %.1f%%\n', mean(allBodyInMaze), std(allBodyInMaze));

% Check specific problematic sessions
badSessions = find(allHeadInMaze < 50 | allBodyInMaze < 50);
if ~isempty(badSessions)
    fprintf('\nProblematic sessions (< 50%% in maze):\n');
    for i = badSessions
        fprintf('  Session %d: %s - Head: %.1f%%, Body: %.1f%%\n', ...
            i, sessionData(i).mouseName, allHeadInMaze(i), allBodyInMaze(i));
    end
end

% Visual verification for a few representative sessions
fprintf('\n=== CREATING VISUAL VERIFICATION ===\n');

% Select sessions to visualize: good, ok, and potentially bad
goodIdx = find(allHeadInMaze > 80 & allBodyInMaze > 80, 1, 'first');
okIdx = find(allHeadInMaze > 50 & allHeadInMaze <= 80, 1, 'first');
badIdx = find(allHeadInMaze <= 50, 1, 'first');

plotIndices = [goodIdx, okIdx, badIdx];
plotIndices = plotIndices(~isnan(plotIndices) & plotIndices > 0);

if ~isempty(plotIndices)
    figure('Position', [50, 50, 1400, 500]);
    
    for i = 1:length(plotIndices)
        idx = plotIndices(i);
        subplot(1, length(plotIndices), i);
        
        % Get data
        CENTER = sessionData(idx).mazeCenter;
        RADIUS = sessionData(idx).mazeRadius;
        headPos = analysisData(idx).headPos;
        bodyPos = analysisData(idx).bodyPos;
        
        % Plot trajectories (subsample for clarity)
        subsample = 1:10:size(headPos,1);
        plot(headPos(subsample,1), headPos(subsample,2), '.', 'MarkerSize', 3, 'Color', [0.8, 0.2, 0.2], 'DisplayName', 'Head');
        hold on;
        plot(bodyPos(subsample,1), bodyPos(subsample,2), '.', 'MarkerSize', 3, 'Color', [0.2, 0.8, 0.2], 'DisplayName', 'Body');
        
        % Plot maze boundary
        theta = linspace(0, 2*pi, 100);
        maze_x = CENTER(1) + RADIUS * cos(theta);
        maze_y = CENTER(2) + RADIUS * sin(theta);
        plot(maze_x, maze_y, 'b-', 'LineWidth', 2, 'DisplayName', 'Maze');
        
        % Plot center
        plot(CENTER(1), CENTER(2), 'b+', 'MarkerSize', 15, 'LineWidth', 3, 'DisplayName', 'Center');
        
        % Calculate statistics
        headDistances = sqrt(sum((headPos(:,1:2) - CENTER(:)').^2, 2));
        bodyDistances = sqrt(sum((bodyPos(:,1:2) - CENTER(:)').^2, 2));
        headInMaze = sum(headDistances <= RADIUS) / length(headDistances) * 100;
        bodyInMaze = sum(bodyDistances <= RADIUS) / length(bodyDistances) * 100;
        
        axis equal;
        grid on;
        xlabel('X position (cm)');
        ylabel('Y position (cm)');
        title(sprintf('%s\nHead: %.1f%% in maze, Body: %.1f%% in maze', ...
            sessionData(idx).mouseName, headInMaze, bodyInMaze));
        
        if i == 1
            legend('show', 'Location', 'best');
        end
        
        % Set reasonable axis limits
        margin = RADIUS * 0.3;
        xlim([CENTER(1) - RADIUS - margin, CENTER(1) + RADIUS + margin]);
        ylim([CENTER(2) - RADIUS - margin, CENTER(2) + RADIUS + margin]);
    end
    
    sgtitle('Coordinate Alignment Verification: Head/Body Positions vs Maze Boundaries', 'FontSize', 14);
end

% Detailed analysis of one session
fprintf('\n=== DETAILED ANALYSIS OF REPRESENTATIVE SESSION ===\n');
if ~isempty(goodIdx)
    analyzeIdx = goodIdx;
elseif ~isempty(okIdx)
    analyzeIdx = okIdx;
else
    analyzeIdx = 1;
end

CENTER = sessionData(analyzeIdx).mazeCenter;
RADIUS = sessionData(analyzeIdx).mazeRadius;
headPos = analysisData(analyzeIdx).headPos;
bodyPos = analysisData(analyzeIdx).bodyPos;

fprintf('Session %d: %s\n', analyzeIdx, sessionData(analyzeIdx).sessionName);
fprintf('Maze center: (%.1f, %.1f) cm, Radius: %.1f cm\n', CENTER(1), CENTER(2), RADIUS);

% Sample a few positions throughout the session
sampleIndices = round(linspace(1, size(headPos,1), 10));
fprintf('Sample positions throughout session:\n');
fprintf('Time\tHead_X\tHead_Y\tHead_Dist\tBody_X\tBody_Y\tBody_Dist\tIn_Maze\n');

for i = 1:length(sampleIndices)
    idx = sampleIndices(i);
    headSample = headPos(idx, 1:2);
    bodySample = bodyPos(idx, 1:2);
    
    headDist = sqrt(sum((headSample - CENTER(:)').^2));
    bodyDist = sqrt(sum((bodySample - CENTER(:)').^2));
    
    inMaze = (headDist <= RADIUS && bodyDist <= RADIUS);
    
    fprintf('%d%%\t%.1f\t%.1f\t%.1f\t\t%.1f\t%.1f\t%.1f\t\t%s\n', ...
        round(i/length(sampleIndices)*100), headSample(1), headSample(2), headDist, ...
        bodySample(1), bodySample(2), bodyDist, char(inMaze*'Y' + (1-inMaze)*'N'));
end

% Final assessment
fprintf('\n=== COORDINATE FIX ASSESSMENT ===\n');
if overallStatus && mean(allHeadInMaze) > 70 && mean(allBodyInMaze) > 70
    fprintf('✅ COORDINATE FIX SUCCESSFUL!\n');
    fprintf('   - Most head/body positions are within maze boundaries\n');
    fprintf('   - Coordinate system alignment is working properly\n');
    fprintf('   - DLC tracking data matches maze geometry\n');
elseif mean(allHeadInMaze) > 40 && mean(allBodyInMaze) > 40
    fprintf('⚠️  COORDINATE FIX PARTIALLY SUCCESSFUL\n');
    fprintf('   - Some positions are within maze boundaries\n');
    fprintf('   - May need further fine-tuning of coordinate system\n');
    fprintf('   - Check specific problematic sessions\n');
else
    fprintf('❌ COORDINATE FIX NEEDS ATTENTION\n');
    fprintf('   - Many positions are outside maze boundaries\n');
    fprintf('   - Coordinate system may need additional correction\n');
    fprintf('   - Review scaling factors and alignment\n');
end

fprintf('\nCoordinate verification complete.\n');
