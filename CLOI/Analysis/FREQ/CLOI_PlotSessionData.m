function CLOI_PlotSessionData(miniAnalysisData, targetMouse, targetSessionType, targetParameter)
%CLOI_PlotSessionData Plot minisession data for specific mouse and session type
%
% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later
%
% This function creates a bar plot showing average values across minisessions
% with individual session data points overlaid as scatter plots.
%
% NOTE: Distance measurements are now in centimeters (cm) after coordinate system fix.
%       The coordinate scaling factor (30/mazeRadius) converts pixel coordinates to cm.
%
% Inputs:
%   miniAnalysisData - Struct array containing minisession analysis results
%   targetMouse - String specifying the target mouse (e.g., 'ChAT_946-2')
%   targetSessionType - String specifying session type (e.g., 'Baseline', 'FREQ')
%   targetParameter - String specifying the parameter to plot (e.g., 'velocityPeakCount', 'velocityMean')
%
% Example:
%   CLOI_PlotSessionData(miniAnalysisData, 'ChAT_946-2', 'Baseline', 'velocityPeakCount');
%   CLOI_PlotSessionData(miniAnalysisData, 'ChAT_946-2', 'FREQ', 'velocityMean');

% Find sessions for the target mouse and session type
targetSessionIndices = [];
for i = 1:length(miniAnalysisData)
    if contains(miniAnalysisData(i).mouseName, targetMouse) && contains(miniAnalysisData(i).sessionName, targetSessionType)
        targetSessionIndices(end+1) = i;
    end
end

fprintf('Found %d %s sessions for mouse %s:\n', length(targetSessionIndices), targetSessionType, targetMouse);
for i = 1:length(targetSessionIndices)
    fprintf('  Session %d: %s\n', i, miniAnalysisData(targetSessionIndices(i)).sessionName);
end

if isempty(targetSessionIndices)
    error('No sessions found for mouse %s with session type %s', targetMouse, targetSessionType);
end

% Check if the target parameter exists
if ~isfield(miniAnalysisData, targetParameter)
    error('Parameter "%s" does not exist in miniAnalysisData structure', targetParameter);
end

% Get the first session to determine minisession number
firstSessionIdx = targetSessionIndices(1);
sampleData = miniAnalysisData(firstSessionIdx).(targetParameter);

% Handle different data types (cell arrays vs numeric arrays)
if iscell(sampleData)
    minisessionNum = length(sampleData);
    % For cell arrays, extract numeric values (e.g., velocityPeak)
    parameterData = zeros(length(targetSessionIndices), minisessionNum);
    for i = 1:length(targetSessionIndices)
        sessionIdx = targetSessionIndices(i);
        cellData = miniAnalysisData(sessionIdx).(targetParameter);
        for ms = 1:minisessionNum
            if iscell(cellData{ms})
                parameterData(i, ms) = length(cellData{ms}); % Count for nested cells
            elseif isnumeric(cellData{ms})
                parameterData(i, ms) = length(cellData{ms}); % Count for numeric arrays
            else
                parameterData(i, ms) = cellData{ms}; % Direct value
            end
        end
    end
else
    % For numeric arrays
    minisessionNum = length(sampleData);
    parameterData = zeros(length(targetSessionIndices), minisessionNum);
    for i = 1:length(targetSessionIndices)
        sessionIdx = targetSessionIndices(i);
        parameterData(i, :) = miniAnalysisData(sessionIdx).(targetParameter);
    end
end

% Calculate mean and individual data points
parameterMean = mean(parameterData, 1);
minisessionNumbers = 1:minisessionNum;

% Create the plot
figure('Position', [100, 100, 800, 600]);
hold on;

% Create bar plot for the mean with different colors for odd/even minisessions
barColors = zeros(minisessionNum, 3); % RGB color matrix
for i = 1:minisessionNum
    if mod(i, 2) == 0
        barColors(i, :) = [0, 0.8, 0]; % Green for even minisessions
    else
        barColors(i, :) = [0.7, 0.7, 0.7]; % Gray for odd minisessions
    end
end

% Plot bars individually with different colors
barHandles = [];
for i = 1:minisessionNum
    h = bar(i, parameterMean(i), 'FaceColor', barColors(i, :), 'EdgeColor', 'black', 'LineWidth', 1);
    barHandles(end+1) = h;
end

% Add individual data points as scatter plot
colors = lines(length(targetSessionIndices)); % Generate distinct colors
scatterHandles = [];
for sessionIdx = 1:length(targetSessionIndices)
    % Add small random jitter to x-coordinates for better visibility
    xJitter = minisessionNumbers + (rand(1, minisessionNum) - 0.5) * 0.2;
    h = scatter(xJitter, parameterData(sessionIdx, :), 50, colors(sessionIdx, :), 'filled', 'MarkerEdgeColor', 'black');
    scatterHandles(end+1) = h;
end

% Customize the plot
xlabel('Minisession Number', 'FontSize', 12, 'FontWeight', 'bold');

% Create appropriate y-label based on parameter
yLabelText = formatParameterName(targetParameter);
ylabel(yLabelText, 'FontSize', 12, 'FontWeight', 'bold');

title(sprintf('%s - %s %s Sessions (n=%d)', yLabelText, targetMouse, targetSessionType, length(targetSessionIndices)), ...
      'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');

% Set axis properties
xlim([0.5, minisessionNum + 0.5]);
xticks(1:minisessionNum);
grid on;
grid minor;

% Add legend
legendEntries = cell(length(targetSessionIndices) + 2, 1);
legendEntries{1} = 'Mean (Odd)';
legendEntries{2} = 'Mean (Even)';
for i = 1:length(targetSessionIndices)
    legendEntries{i+2} = sprintf('Session %d', i);
end

% Create legend handles - use first odd and first even bar handles for legend
oddBarIdx = find(mod(1:minisessionNum, 2) == 1, 1); % First odd minisession
evenBarIdx = find(mod(1:minisessionNum, 2) == 0, 1); % First even minisession
legendHandles = [barHandles(oddBarIdx), barHandles(evenBarIdx), scatterHandles];
legend(legendHandles, legendEntries, 'Location', 'best');

hold off;

% Display summary statistics
fprintf('\n%s Summary for %s %s sessions:\n', yLabelText, targetMouse, targetSessionType);
fprintf('Minisession\tMean\tStd\tSessions\n');
for ms = 1:minisessionNum
    fprintf('%d\t\t%.2f\t%.2f\t%s\n', ms, parameterMean(ms), std(parameterData(:, ms)), ...
            sprintf('%.2f ', parameterData(:, ms)));
end

end

function formattedName = formatParameterName(parameterName)
%FORMATPARAMETERNAME Convert parameter name to readable format for labels
    switch parameterName
        case 'velocityPeakCount'
            formattedName = 'Velocity Peak Count';
        case 'velocityMax'
            formattedName = 'Maximum Velocity';
        case 'velocityMean'
            formattedName = 'Mean Velocity';
        case 'angVelPeakCount'
            formattedName = 'Angular Velocity Peak Count';
        case 'angVelMax'
            formattedName = 'Maximum Angular Velocity';
        case 'angVelMean'
            formattedName = 'Mean Angular Velocity';
        case 'eossomNum'
            formattedName = 'EOSSOM Count';
        case 'ipsiTurnNum'
            formattedName = 'Ipsilateral Turn Count';
        case 'contraTurnNum'
            formattedName = 'Contralateral Turn Count';
        case 'ipsiTurnTime'
            formattedName = 'Ipsilateral Turn Time';
        case 'contraTurnTime'
            formattedName = 'Contralateral Turn Time';
        case 'centerMazeTime'
            formattedName = 'Center Maze Time';
        case 'centerMazeDist'
            formattedName = 'Center Maze Distance (cm)';
        case 'totalDistance'
            formattedName = 'Total Distance (cm)';
        case 'centerDistance'
            formattedName = 'Center Distance (cm)';
        case 'peripheralDistance'
            formattedName = 'Peripheral Distance (cm)';
        otherwise
            % Convert camelCase to readable format
            formattedName = regexprep(parameterName, '([A-Z])', ' $1');
            formattedName = [upper(formattedName(1)), lower(formattedName(2:end))];
    end
end
