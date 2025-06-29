%% Function to plot speed vs time for stop events observed in multiple sessions

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function [] = CLOI_PlotStopEvent(sessionData, sessionDescription)
    % Check number of sessions in sessionData
    numSessions = length(sessionData);

    fig = figure;
    hold on;

    % Make a variable to store ON event data (15 + 1 + 30 frames)
    eventDataONDLC = zeros(0, 46);
    eventDataONMV = zeros(0, 46);

    % Iterate through each session
    for sessionNum = 1:numSessions
        % Extract session data
        session = sessionData(sessionNum);
        sessionName = session.sessionName;
        dlcTime = session.dlcTime;
        dlcCoordX = session.dlcCoordX;
        dlcCoordY = session.dlcCoordY;
        mvTime = session.mvTime;
        mvCentX = session.mvCentX;
        mvCentY = session.mvCentY;
        lsTime = session.lsTime;
        %lsState = session.lsState;

        % Get laser ON time and frame
        lsOnTime = lsTime(1:2:end);
        %lsOFFTime = lsTime(2:2:end);
        % Find closest mvTime index for each lsOnTime
        %lsFrame = arrayfun(@(t) find(abs(mvTime - t) == min(abs(mvTime - t)), 1, 'first'), lsOnTime);
        lsOnFrame = arrayfun(@(t) find(abs(mvTime - t) == min(abs(mvTime - t)), 1, 'first'), lsOnTime);
        %lsOFFFrame = arrayfun(@(t) find(abs(mvTime - t) == min(abs(mvTime - t)), 1, 'first'), lsOFFTime);

        % Get dlcSpeed and mvSpeed
        dlcSpeed = sqrt(diff(dlcCoordX).^2 + diff(dlcCoordY).^2) ./ diff(dlcTime);
        mvSpeed = sqrt(diff(mvCentX).^2 + diff(mvCentY).^2) ./ diff(mvTime);

        % Pad speed arrays to match time arrays (since diff reduces length by 1)
        dlcSpeedFull = [dlcSpeed(1); dlcSpeed];
        mvSpeedFull = [mvSpeed(1); mvSpeed];

        % Get windowed dlcWSpeed and mvWSpeed
        windowSize = 3; % Define window size for smoothing

        % Smoothed dlcWSpeed
        dlcWSpeed = zeros(size(dlcTime));
        for n = 1:length(dlcTime)
            idx1 = max(1, n - windowSize);
            idx2 = min(length(dlcTime), n + windowSize);
            dlcWSpeed(n) = mean(dlcSpeedFull(idx1:idx2));
        end

        % Smoothed mvWSpeed
        mvWSpeed = zeros(size(mvTime));
        for n = 1:length(mvTime)
            idx1 = max(1, n - windowSize);
            idx2 = min(length(mvTime), n + windowSize);
            mvWSpeed(n) = mean(mvSpeedFull(idx1:idx2));
        end

        % Plotting for each ON event (from -1.0s to 2.0s)
        for onIdx = 1:length(lsOnFrame)
            % Overlap plots for each ON event
            frameOfInterest = lsOnFrame(onIdx)-15:lsOnFrame(onIdx)+30;
            % Check if the frame indices are valid
            if all(frameOfInterest > 0) && all(frameOfInterest <= length(dlcTime))
                % Plot dlcWSpeed
                subplot(2, 1, 1);
                hold on;
                plot((-15:30)/15.0, dlcWSpeed(frameOfInterest), 'LineWidth', 0.5, 'Color', [0.8 0.2 0.2, 0.1]);

                % Plot mvWSpeed
                subplot(2, 1, 2);
                hold on;
                plot((-15:30)/15.0, mvWSpeed(frameOfInterest), 'LineWidth', 0.5, 'Color', [0.2 0.2 0.8, 0.1]);

                % Add data to eventDataON
                eventDataONDLC = [eventDataONDLC; dlcWSpeed(frameOfInterest)'];
                eventDataONMV = [eventDataONMV; mvWSpeed(frameOfInterest)'];

            end
        end
    end

    size(eventDataONDLC)
    size(eventDataONMV)

    % Plot the average DLC speed and envelope for each session
    subplot(2, 1, 1);
    plot((-15:30)/15.0, mean(eventDataONDLC), 'LineWidth', 2, 'Color', [1 0 0 1]);
    % Fill the area between the mean ± std/2 for the envelope
    % fill([-15:30, fliplr(-15:30)]/15.0, ...
    %     [mean(eventDataONDLC) + std(eventDataONDLC)/2, fliplr(mean(eventDataONDLC) - std(eventDataONDLC)/2)], ...
    %     [1 0 0], 'EdgeColor', 'none');
    % Plot the average MV speed and envelope for each session
    subplot(2, 1, 2);
    plot((-15:30)/15.0, mean(eventDataONMV), 'LineWidth', 2, 'Color', [0 0 1 1]);
    % Fill the area between the mean ± std/2 for the envelope
    % fill([-15:30, fliplr(-15:30)]/15.0, ...
    %     [mean(eventDataONMV) + std(eventDataONMV)/2, fliplr(mean(eventDataONMV) - std(eventDataONMV)/2)], ...
    %     [0 0 1], 'EdgeColor', 'none');

    % Set titles and labels
    subplot(2, 1, 1);
    title('DLC Speed');
    xlabel('Time (s)');
    ylabel('Speed (cm/s)');
    xline(0, 'g--', 'LineWidth', 1.5);
    xline(0.5, 'g--', 'LineWidth', 1.5);
    xline(1.5, 'k--', 'LineWidth', 1.5);

    subplot(2, 1, 2);
    title('Center Speed');
    xlabel('Time (s)');
    ylabel('Speed (cm/s)');
    xline(0, 'g--', 'LineWidth', 1.5);
    xline(0.5, 'g--', 'LineWidth', 1.5);
    xline(1.5, 'k--', 'LineWidth', 1.5);
end