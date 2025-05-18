%% Analysis and Plotting of Stop to Movement

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function sessionData_StopToMovement =  CLOI_PlotStopToMovement(sessionData_CLOI, titleStr)
    % Returns struct with mvTimeOnMv and mvStateSum for each session
    sessionData_StopToMovement = struct('sessionName', [], 'mvTimeOnMv', []);
    sessionData_StopToMovement.sessionName = {sessionData_CLOI.sessionName}';

    % Figure 1: Plot average movement state versus time for each session 
    fig1 = figure;
    ax1 = axes(fig1);
    WINDOW_SIZE = 30;
    mvTimeTotal = 0;
    % Figure 2: Plot bar graph and scatter plot of laser ON to movement time
    fig2 = figure;
    ax2 = axes(fig2);

    sessionNum = length(sessionData_CLOI);
    % Iterate for each session
    for sessionidx = 1:sessionNum
        % Get laser ON times and related movement states
        lsStateOnIdx = strcmp(sessionData_CLOI(sessionidx).lsState, "ON");
        lsStateOnTime = sessionData_CLOI(sessionidx).lsTime(lsStateOnIdx);
        lsStateOnNum = length(lsStateOnTime);
        mvTime = sessionData_CLOI(sessionidx).mvTime;
        mvState = sessionData_CLOI(sessionidx).mvState;
        % Initialize variables
        mvTimeOnMv = cell(1, lsStateOnNum);
        mvStateSum = zeros(WINDOW_SIZE + 1, 1);
        mvTimeSum = 0;
        % Iterate for each laser ON (movement Stop) time
        for laseronidx = 1:lsStateOnNum
            % Find the closest index in mvStateTime for the current laser ON time
            mvTimeOnIdx = find(mvTime < lsStateOnTime(laseronidx), 1, "last");
            mvStateOn = mvState(mvTimeOnIdx, :);
            % Find the next movement time after the current laser ON time
            for mvtimeidx = (mvTimeOnIdx + 1):length(mvState)
                mvStateNext = mvState(mvtimeidx, :);
                if strcmp(mvStateNext, 'Move')
                    mvTimeOnMv{1, laseronidx} = mvTime(mvtimeidx, :) - mvTime(mvTimeOnIdx, :);
                    break; % Stop searching when the next movement time is found
                end
            end
            % Search within the window size for the next movement time
            if mvTimeOnIdx + WINDOW_SIZE <= length(mvTime) % Only consider if within bounds
                windowState = mvState(mvTimeOnIdx:(mvTimeOnIdx + WINDOW_SIZE), :);
                windowState = double(strcmp(windowState, 'Move'));
                % Ensure that once windowState changes to 1, the rest are all 1
                firstMoveIdx = find(windowState == 1, 1, "first");
                if ~isempty(firstMoveIdx)
                    windowState(firstMoveIdx:end) = 1;
                end
                windowTime = mvTime(mvTimeOnIdx:(mvTimeOnIdx + WINDOW_SIZE), :);
                mvStateSum = mvStateSum + windowState;
                mvTimeSum = mvTimeSum + (windowTime(end) - windowTime(1));
            end
        end
        % Calculate the average mvState and mvTime for the current session
        mvStateAvg = mvStateSum / lsStateOnNum;
        mvTimeAvg = mvTimeSum / lsStateOnNum;
        mvTimeTotal = mvTimeTotal + mvTimeAvg;
        % Store mvTimeOnMv in the sessionData_StopToMovement struct
        sessionData_StopToMovement(sessionidx).mvTimeOnMv = mvTimeOnMv;

        % Plot the average movement state for the current session
        hold(ax1, 'on');
        plot(ax1, (0:1/WINDOW_SIZE:1) * mvTimeAvg, mvStateAvg, 'LineWidth', 2);
    end

    % Plot the laser ON to movement time for each session
    mvTimeAvg = zeros(1, sessionNum);
    for sessionidx = 1:sessionNum
        hold(ax2, 'on');
        % Get the laser ON times and related movement states
        mvTimeOnMv = sessionData_StopToMovement(sessionidx).mvTimeOnMv;
        % Convert cell array to numeric array for plotting
        mvTimeOnMv = cell2mat(mvTimeOnMv);
        mvTimeOnMvAvg = mean(mvTimeOnMv, 'omitnan'); % Calculate the average time for each session
        mvTimeAvg(sessionidx) = mvTimeOnMvAvg; % Store the average time for each session
        mvTimeOnMvSE = std(mvTimeOnMv, 'omitnan') / sqrt(length(mvTimeOnMv)); % Calculate the standard error
        % Create a bar graph with error bars
        bar(ax2, sessionidx, mvTimeOnMvAvg, 'FaceColor', 'flat', 'EdgeColor', 'none');
        errorbar(ax2, sessionidx, mvTimeOnMvAvg, mvTimeOnMvSE, 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
        % Create a scatter plot for individual data points
        scatter(ax2, sessionidx, mvTimeOnMv, 'filled', 'Marker', 'o', 'MarkerFaceColor', 'r', 'Jitter', 'on', 'JitterAmount', 0.1);
    end
    disp("mvTimeAvg: " + string(mean(mvTimeAvg)) + " +/- " + string(std(mvTimeAvg) / sqrt(sessionNum)));

    % Set figure 1 properties
    xlabel(ax1, 'Time (s)');
    xticks(ax1, (0:1/WINDOW_SIZE:1) * (mvTimeTotal / sessionNum));
    xlim(ax1, [0 (mvTimeTotal / sessionNum)]);
    ylabel(ax1, 'Movement State (0: No Movement, 1: Movement)');
    title(ax1, titleStr, "Interpreter", "none");
    grid(ax1, 'on');
    hold off

    % Set figure 2 properties
    xlabel(ax2, 'Session Number');
    ylabel(ax2, 'Time (s)');
    title(ax2, 'Laser ON to Movement Time', "Interpreter", "none");
    xticks(ax2, 1:sessionNum);
    xlim(ax2, [0 sessionNum + 1]);
    hold(ax2, 'off');
    %xticklabels(ax2, sessionData_StopToMovement.sessionName);
    %xtickangle(ax2, 45);
    %xlim(ax2, [0 sessionNum + 1]);
    %ylim(ax2, [0 max(cell2mat(sessionData_StopToMovement.mvTimeOnMv)) + 1]);
end