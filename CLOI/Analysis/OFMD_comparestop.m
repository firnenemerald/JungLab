close all

%-------------------------------------------------------
% Part 1: Using the struct data (from previous code)
%-------------------------------------------------------
stop_data = behavcluster_Chat_parkinson.ChAT_925_2_24_09_10_11_39_48_OF.stop;
video_length_struct = stop_data(end, 2);

%-------------------------------------------------------
% Part 2: Using the CSV data (Frame, MOVE) with minimum stop duration
%-------------------------------------------------------
csv_data = readtable('C:/Users/chanh/Downloads/Video_ChAT/output_data.csv');

% Extract frames and movement info
frames = csv_data.Frame;
move = csv_data.MOVE;
video_length_csv = frames(end);

% Identify indices where mouse is stopped (MOVE == 0)
stopIndices = find(move == 0);

if ~isempty(stopIndices)
    % Find breaks between consecutive zero-frames
    diffIndices = diff(stopIndices);
    breakPoints = find(diffIndices > 1);

    % Start and end points of each zero-run
    startPoints = [stopIndices(1); stopIndices(breakPoints+1)];
    endPoints = [stopIndices(breakPoints); stopIndices(end)];

    % Minimum stop duration in frames
    minStopDuration = 30;

    % Compute the length of each run
    runLengths = endPoints - startPoints + 1;

    % Filter out runs shorter than the minimum duration
    validRuns = runLengths >= minStopDuration;
    startPoints = startPoints(validRuns);
    endPoints = endPoints(validRuns);
else
    startPoints = [];
    endPoints = [];
end

%-------------------------------------------------------
% Plotting
%-------------------------------------------------------
figure('Color', 'w');

%------------------ Subplot 1 (Struct Data) ------------------%
subplot(2,1,1);
hold on;
xlim([0, video_length_struct]);
ylim([0, 1]);
xlabel('Frame Number');
title('Stop Phases (Struct Data)');
set(gca, 'YTick', [], 'YColor', 'w'); % Hide y-axis ticks

% White background
rectangle('Position', [0, 0, video_length_struct, 1], 'FaceColor', 'w', 'EdgeColor', 'k');

% Plot red blocks for each stop interval from the struct
for i = 1:size(stop_data, 1)
    startFrame = stop_data(i, 1);
    endFrame = stop_data(i, 2);
    width = endFrame - startFrame;
    rectangle('Position', [startFrame, 0, width, 1], 'FaceColor','r', 'EdgeColor','none');
end
hold off;

%------------------ Subplot 2 (CSV Data, Filtered) ------------------%
subplot(2,1,2);
hold on;
xlim([0, video_length_csv]);
ylim([0, 1]);
xlabel('Frame Number');
title('Stop Phases (CSV Data with Minimum Duration)');
set(gca, 'YTick', [], 'YColor', 'w'); % Hide y-axis ticks

% White background
rectangle('Position',[0, 0, video_length_csv, 1], 'FaceColor','w', 'EdgeColor','k');

% Plot red blocks for valid stop intervals (≥30 frames)
for j = 1:length(startPoints)
    sFrame = startPoints(j);
    eFrame = endPoints(j);
    width = eFrame - sFrame + 1; 
    rectangle('Position', [sFrame, 0, width, 1], 'FaceColor','r', 'EdgeColor','none');
end
hold off;
