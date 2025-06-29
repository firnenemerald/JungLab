function CLOI_PlotTimeline(sessionData, sessionIndices)

    for i = 1:length(sessionIndices)
        % Get the index of the current session
        sessIndex = sessionIndices(i);

        % Get session data
        sessName = sessionData(sessIndex).sessionName;

        % Get DLC data
        DLCframe = sessionData(sessIndex).dlcTime;
        DLCnose = [sessionData(sessIndex).dlcCoordHeadX, sessionData(sessIndex).dlcCoordHeadY, sessionData(sessIndex).dlcCoordHeadConf];
        DLCcentre = [sessionData(sessIndex).dlcCoordBodyX, sessionData(sessIndex).dlcCoordBodyY, sessionData(sessIndex).dlcCoordBodyConf];
        DLCtail = [sessionData(sessIndex).dlcCoordTailX, sessionData(sessIndex).dlcCoordTailY, sessionData(sessIndex).dlcCoordTailConf];

        % Get Mv and Ls data
        MvTime = sessionData(sessIndex).mvTime;
        MvState = sessionData(sessIndex).mvState;
        lsTime = sessionData(sessIndex).lsTime;
        lsState = sessionData(sessIndex).lsState;

        % Behavioral clustering analysis
        behavData = CLOI_behavcluster(DLCframe, DLCnose, DLCcentre, DLCtail, 120);

        %% Stop event related analysis
        % DLC based stop event analysis

        % Extract event arrays
        locEvents = behavData.locomotion_events;  % [N_loc × 2], each row = [startFrame, endFrame]
        stopEvents = behavData.stop_events;       % [N_stop × 2], each row = [startFrame, endFrame]
        allFrames  = behavData.frames_downsampled; % [1 × M] downsampled frame indices

        % Make a wide figure (e.g. 1920×300 pixels)
        figure('Position',[50, 200, 1920, 300]);
        hold on

        % Define vertical span (0→1) for both sets of rectangles
        y_bottom = 0;
        y_height = 1;

        % Plot locomotion intervals in semi-transparent blue
        for i = 1:size(locEvents,1)
            x_start = locEvents(i,1);
            x_end   = locEvents(i,2);
            h = rectangle( ...
                'Position',[ x_start, y_bottom, (x_end - x_start), y_height ], ...
                'FaceColor',[0 0 1], ...
                'EdgeColor','none' ...
            );
            set(h,'FaceAlpha',0.3);
        end

        % Plot stop intervals in semi-transparent red
        for j = 1:size(stopEvents,1)
            x_start = stopEvents(j,1);
            x_end   = stopEvents(j,2);
            h = rectangle( ...
                'Position',[ x_start, y_bottom, (x_end - x_start), y_height ], ...
                'FaceColor',[1 0 0], ...
                'EdgeColor','none' ...
            );
            set(h,'FaceAlpha',0.3);
        end

        % Plot vertical lines for mini sessions
        miniSessionTimes = [120, 240, 360, 480, 600];
        for k = 1:length(miniSessionTimes)
            x_time = miniSessionTimes(k);
            x_frame = find(MvTime >= x_time, 1, 'first'); % Find the first frame that is greater than or equal to x_time
            x_framereduced = find(allFrames >= x_frame, 1, 'first'); % Find the first frame in allFrames that is greater than or equal to x_frame
            x_pos = allFrames(x_framereduced); % Get the corresponding position in allFrames
            line([x_pos, x_pos], [y_bottom, y_bottom + y_height], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
        end

        % Plot laser ON events
        % Find indices where laser turns ON and OFF
        lsStateStr = string(lsState); % Convert cell to string array for easier comparison
        onIdx = find(lsStateStr == "ON");
        offIdx = find(lsStateStr == "OFF");

        % Align laser ON and OFF events
        % Ensure that ON and OFF events are paired correctly
        if ~isempty(onIdx) && ~isempty(offIdx)
            % If first event is OFF, ignore it
            if offIdx(1) < onIdx(1)
                offIdx(1) = [];
            end
            % Ensure that ON and OFF events are paired correctly
            for j = 1:length(onIdx)-3
                if onIdx(j) > offIdx(j)
                    % If an ON event is found after an OFF event, remove the OFF
                    offIdx(j) = [];
                elseif onIdx(j+1) < offIdx(j)
                    % If the next ON event is before the current OFF, remove the current ON
                    onIdx(j) = []; 
                end
            end
            % If last ON has no following OFF, ignore it
            if length(onIdx) > length(offIdx)
                onIdx(end) = [];
            end
            % If last OFF has no preceding ON, ignore it
            if length(offIdx) > length(onIdx)
                offIdx(end) = [];
            end
            % Now, ON and OFF are paired
            laserIntervals = [onIdx, offIdx];
        else
            laserIntervals = [];
        end

        % For each ON interval, get corresponding time and frame intervals
        for x = 1:size(laserIntervals,1)
            t_on = lsTime(laserIntervals(x,1));
            t_off = lsTime(laserIntervals(x,2));
            % Find frame indices in MvTime
            frame_on = find(MvTime >= t_on, 1, 'first');
            frame_off = find(MvTime >= t_off, 1, 'first');
            % Map to downsampled frames
            frame_on_ds = find(allFrames >= frame_on, 1, 'first');
            frame_off_ds = find(allFrames >= frame_off, 1, 'first');
            % Get frame numbers in downsampled space
            x_on = allFrames(frame_on_ds);
            x_off = allFrames(frame_off_ds);
            % Plot a green rectangle for laser ON interval
            h = rectangle('Position', [x_on, 0.6, (x_off - x_on), 0.2], ...
                'FaceColor', [0 1 0], 'EdgeColor', 'none');
            set(h, 'FaceAlpha', 0.8);
        end

        % % Plot MvState
        % % Convert MvState to a logical array for plotting
        % MvStateLogical = strcmp(MvState, 'Move');
        % % Plot MvState as vertical lines
        % y_bottom = 0.2; % Adjusted bottom position for MvState
        % y_height = 0.2; % Height of the MvState line
        % % Plot MvState as a line
        % MvStateLogical = double(MvStateLogical); % Convert logical to double for plotting

        % % Create MvStateLogical with vertical position adjustment
        % MvStateLogical_plot = y_bottom + MvStateLogical * y_height;

        % % Initialize line widths array
        % lineWidths = ones(size(MvStateLogical_plot)) * 0.5;

        % % Find segments where the value doesn't change (flat line segments)
        % for k = 1:length(MvStateLogical_plot)-1
        %     if MvStateLogical_plot(k) == MvStateLogical_plot(k+1)
        %         lineWidths(k) = 2.0;
        %     end
        % end

        % % Plot using a loop to apply different line widths for each segment
        % for k = 1:length(MvStateLogical_plot)-1
        %     plot([k, k+1], [MvStateLogical_plot(k), MvStateLogical_plot(k+1)], 'b-', 'LineWidth', lineWidths(k));
        % end
        % hold on;

        % Adjust axes and labels
        xlim([ allFrames(1), allFrames(end) ]);
        ylim([ y_bottom, y_bottom + y_height ]);
        xlabel(strcat('Frame number = ', int2str(length(MvTime))));
        yticks([])
        title(strcat(sessName, ' Timeline: Locomotion (blue) vs. Stop (red)'), "Interpreter", "none");
        box on
        hold off
    end
end