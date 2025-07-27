function [VelocitiesTotal] = CLOI_PlotEventData(sessionData, sessionIndices, analysisData, plotIndices, plotVar)

figure;
hold on;

plotIndices = plotIndices{plotVar};

VelocitiesTotal = {};

for j = 1:length(plotIndices)
    % Get the indices for the current plot
    MOUSEIDX = plotIndices(j);

    sn = analysisData(MOUSEIDX).sessionName;
    fprintf('Session Name: %s\n', sn);

    % Get laser state for specified session
    laserStateRaw = sessionData(sessionIndices(MOUSEIDX)).lsState;
    % Process laser state from cell array to binary values
    laserStateBool = zeros(size(laserStateRaw));
    for i = 1:length(laserStateRaw)
        if strcmp(laserStateRaw{i}, 'ON')
            laserStateBool(i) = 1;
        elseif strcmp(laserStateRaw{i}, 'OFF')
            laserStateBool(i) = 0;
        end
    end
    % Process laser state to laser change events
    laserStateDiff = diff([0; laserStateBool]); % 1 for ON, -1 for OFF, 0 for no change
    laserOnIndex = find(laserStateDiff == 1); % Indices index when laser is ON

    % Get laser time for specified session
    laserTimeRaw = sessionData(sessionIndices(MOUSEIDX)).lsTime;
    % Get laser time for laser change events
    laserTime = laserTimeRaw(laserOnIndex); % Only keep times when laser is ON

    % Get movement state for specified session
    mvStateRaw = sessionData(sessionIndices(MOUSEIDX)).mvState;
    mvState = zeros(size(mvStateRaw));
    for i = 1:length(mvStateRaw)
        if strcmp(mvStateRaw{i}, 'Stop')
            mvState(i) = 0; % 0 for stop state
        elseif strcmp(mvStateRaw{i}, 'Move')
            mvState(i) = 1; % 1 for move state
        end
    end

    % Get movement time for specified session
    mvTime = sessionData(sessionIndices(MOUSEIDX)).mvTime;

    newLaserOnIndex = []; % To store new laser ON events
    addLaserOnIndex = []; % To store add laser ON events

    SEARCHTIME = 0.3; % Time before laser ON to check movement state

    % For each SEARCHTIME seconds before laser ON, check if the mouse was continuously in stop state
    for idx = 1:length(laserOnIndex)
        laserOnTime = laserTime(idx);
        % Find the indices of movement state before laser ON
        mvIndices = find(mvTime < laserOnTime & mvTime >= laserOnTime - SEARCHTIME);
        
        % Check if all movement states are 'Stop' in the last SEARCHTIME seconds
        if all(mvState(mvIndices) == 0)
            % If all are 'Stop', we can consider it as an add laser ON event
            addLaserOnIndex = [addLaserOnIndex; laserOnIndex(idx)];
        else
            % If not all are 'Stop', we can consider it as a new laser ON event
            newLaserOnIndex = [newLaserOnIndex; laserOnIndex(idx)];
        end
    end

    fprintf('New Laser ON Events: %d\n', length(newLaserOnIndex));
    fprintf('Add Laser ON Events: %d\n', length(addLaserOnIndex));

    % Get DLC data
    DLCframe = sessionData(sessionIndices(MOUSEIDX)).dlcTime;
    DLCheadX = sessionData(sessionIndices(MOUSEIDX)).dlcCoordHeadX;
    DLCheadY = sessionData(sessionIndices(MOUSEIDX)).dlcCoordHeadY;
    DLCheadConf = sessionData(sessionIndices(MOUSEIDX)).dlcCoordHeadConf;
    DLCbodyX = sessionData(sessionIndices(MOUSEIDX)).dlcCoordBodyX;
    DLCbodyY = sessionData(sessionIndices(MOUSEIDX)).dlcCoordBodyY;
    DLCbodyConf = sessionData(sessionIndices(MOUSEIDX)).dlcCoordBodyConf;
    DLCtailX = sessionData(sessionIndices(MOUSEIDX)).dlcCoordTailX;
    DLCtailY = sessionData(sessionIndices(MOUSEIDX)).dlcCoordTailY;
    DLCtailConf = sessionData(sessionIndices(MOUSEIDX)).dlcCoordTailConf;
    DLCnose = [DLCheadX, DLCheadY, DLCheadConf];
    DLCcentre = [DLCbodyX, DLCbodyY, DLCbodyConf];
    DLCtail = [DLCtailX, DLCtailY, DLCtailConf];

    behavData = CLOI_behavcluster(DLCframe, DLCnose, DLCcentre, DLCtail, 120);

    % Get DLC clustered data
    frameDownDLC = behavData.frames_downsampled;
    headPosDLC = behavData.nose_down;
    bodyPosDLC = behavData.centre_down;
    headVelDLC = behavData.nose_velocity;
    bodyVelDLC = behavData.centre_velocity;
    orientationDLC = behavData.orientation_deg;
    angularVelDLC = behavData.angular_velocity;
    turnIpsiEventDLC = behavData.turn_ipsiversive;
    turnContraEventDLC = behavData.turn_contraversive;
    locoEventDLC = behavData.locomotion_events;
    stopEventDLC = behavData.stop_events;

    % Get new laser ON frames in downsampled frames
    newLaserOnIndices = [];
    for idx = 1:length(newLaserOnIndex)
        laserOnFrame = newLaserOnIndex(idx);
        laserOnTime = laserTimeRaw(laserOnFrame);
        % Find the index of frame where laser is ON
        newLaserOnIndices = [newLaserOnIndices; find(mvTime(frameDownDLC) > laserOnTime, 1, 'first')];
    end

    sessionVelocities = [];
    % Find before and after around new laser ON events and plot velocity
    for idx = 1:length(newLaserOnIndices)
        laserOnFrameIdx = newLaserOnIndices(idx);

        % If new laser ON index is not valid, skip it
        if (laserOnFrameIdx - 5) < 1 || (laserOnFrameIdx + 25) > length(frameDownDLC)
            continue;
        end

        % Get the range of indices around the laser ON event
        startFrameIdx = laserOnFrameIdx - 5; % 5 down frames before laser ON
        endFrameIdx = laserOnFrameIdx + 20; % 20 down frames after laser ON
        
        % Extract the data for plotting
        frameRange = frameDownDLC(startFrameIdx:endFrameIdx);
        velocityRange = bodyVelDLC(startFrameIdx:endFrameIdx);

        % Store the velocities for further analysis
        sessionVelocities = [sessionVelocities, velocityRange];
    end
    VelocitiesTotal{j} = sessionVelocities;
end

hold on;
colors = lines(size(VelocitiesTotal, 2)/3); % Generate distinct colors for each mouse
legendEntries = cell(1, size(VelocitiesTotal, 2)/3); % Initialize legend entries array
sessName = ["ChAT 946-2", "ChAT 947-2", "ChAT 947-3", "ChAT 967-2"];
plotHandles = []; % Store plot handles for legend

for idxMouse = 1:size(VelocitiesTotal, 2)/3
    velocities_1 = VelocitiesTotal{idxMouse*3-2};
    velocities_2 = VelocitiesTotal{idxMouse*3-1};
    velocities_3 = VelocitiesTotal{idxMouse*3};
    velMeans_1 = mean(velocities_1, 2);
    velMeans_2 = mean(velocities_2, 2);
    velMeans_3 = mean(velocities_3, 2);
    velStd = std([velocities_1, velocities_2, velocities_3], 0, 2) / sqrt(size([velocities_1, velocities_2, velocities_3], 2)); % Standard error of the mean
    velMeans = mean([velMeans_1, velMeans_2, velMeans_3], 2); % Combine means for this mouse
    timeRange = -0.5:0.1:2.0; % Time range for plotting

    % Plot mean velocity
    h = plot(timeRange, velMeans, 'LineWidth', 2);
    plotHandles = [plotHandles, h]; % Store plot handle for legend
    
    % Fill area for standard deviation
    fill([timeRange, fliplr(timeRange)], [velMeans + velStd; flipud(velMeans - velStd)]', ...
         'k', 'FaceAlpha', 0.15, 'EdgeColor', 'none'); % Fill area for standard deviation
    % Build legend entry
    legendEntries{idxMouse} = sprintf('%s', sessName(idxMouse));
end

titleList = {"Base CLOI", "Base RAND", "Park CLOI", "Park RAND"};
title(sprintf('Velocity around new Laser ON, %s', titleList{plotVar}));
xlabel('Time (s)');
ylabel('Velocity (cm/s)');
xline(0.0, 'k--', 'LineWidth', 1.5); % Add a horizontal line at y=0
xline(0.5, 'g--', 'LineWidth', 1.5); % Add a vertical line at x=1.0

ylimits = ylim; % Get current y limits
patch([0 0.5 0.5 0], [ylimits(1) ylimits(1) ylimits(2) ylimits(2)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% Create legend using only the plot handles (not fill or patch)
legend(plotHandles, legendEntries, 'Location', 'Best');

% === Plot group average curve with SEM envelope ===
allVelocities = [];
for idxMouse = 1:size(VelocitiesTotal, 2)/3
    velocities_1 = VelocitiesTotal{idxMouse*3-2};
    velocities_2 = VelocitiesTotal{idxMouse*3-1};
    velocities_3 = VelocitiesTotal{idxMouse*3};
    allVelocities = [allVelocities, velocities_1, velocities_2, velocities_3];
end

groupMean = mean(allVelocities, 2);
groupSEM = std(allVelocities, 0, 2) / sqrt(size(allVelocities, 2));
timeRange = -0.5:0.1:2.0;

% Plot the group average with shaded error
hold on;
plot(timeRange, groupMean, 'k-', 'LineWidth', 3); % Black bold line
fill([timeRange, fliplr(timeRange)], ...
     [groupMean + groupSEM; flipud(groupMean - groupSEM)]', ...
     'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none');

% Add to legend
legend([plotHandles, plot(nan, nan, 'k-', 'LineWidth', 3)], ...
       [legendEntries, {'Group Mean'}], ...
       'Location', 'Best');

end