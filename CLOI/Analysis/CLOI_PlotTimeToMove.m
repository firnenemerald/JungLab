function CLOI_PlotTimeToMove(sessionData)
    numSessions = length(sessionData);

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

    time_to_move_list = [];
    for i = 1:size(eventDataONDLC, 1)
        event_speed = eventDataONDLC(i, :);
        speed_at_2s = event_speed(46); % 2s is at index 46
        threshold = 0.632 * speed_at_2s;
        % Find first index after 0s (frame 16) where speed >= threshold
        idx_after_0s = 16:46;
        above_thresh = find(event_speed(idx_after_0s) >= threshold, 1, 'first');
        if ~isempty(above_thresh)
            time_to_move = (idx_after_0s(above_thresh) - 16) / 15.0; % time from 0s
        else
            time_to_move = NaN; % Not reached
        end
        time_to_move_list = [time_to_move_list; time_to_move];
    end

    % Scatter plot of time_to_move
    figure;
    scatter(time_to_move_list, 1:length(time_to_move_list), 60, 'filled');
    xlabel('Time to Move (s)');
    ylabel('Event #');
    title('Time to Move for Each Event');
    grid on;

    % Calculate and display average time to move
    avg_time_to_move = mean(time_to_move_list(~isnan(time_to_move_list)));
    hold on;
    xline(avg_time_to_move, '--r', 'LineWidth', 2, 'Label', sprintf('Mean = %.3f s', avg_time_to_move), 'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
    hold off;
end