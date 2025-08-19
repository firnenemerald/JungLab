function CLOI_PlotCollectiveData(miniAnalysisData, mouseNames, sessionTypes, parameterName)
%CLOI_PlotCollectiveData Plot collective minisession data across multiple mice and session types
%
% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later
%
% This function creates a bar plot showing average values across minisessions
% with individual mouse-session type combinations plotted as scatter points.
% Data from the same mouse and session type are averaged before plotting.
%
% NOTE: Distance measurements are now in centimeters (cm) after coordinate system fix.
%       The coordinate scaling factor (30/mazeRadius) converts pixel coordinates to cm.
%
% Inputs:
%   miniAnalysisData - Struct array containing minisession analysis results
%   mouseNames - Cell array of mouse names (e.g., {'ChAT_946-2', 'ChAT_967-3'}) or 'ALL'
%   sessionTypes - String specifying session types: 'BASE', 'PARK', or 'BOTH'
%   parameterName - String specifying the parameter to plot (e.g., 'totalDistance')
%
% Examples:
%   CLOI_PlotCollectiveData(miniAnalysisData, {'ChAT_946-2', 'ChAT_967-3'}, 'BOTH', 'totalDistance');
%   CLOI_PlotCollectiveData(miniAnalysisData, 'ALL', 'BASE', 'velocityPeakCount');

% Input validation
if ~isstruct(miniAnalysisData)
    error('miniAnalysisData must be a struct array');
end

if isempty(miniAnalysisData)
    error('miniAnalysisData is empty');
end

% Check if the target parameter exists
if ~isfield(miniAnalysisData, parameterName)
    error('Parameter "%s" does not exist in miniAnalysisData structure', parameterName);
end

% Process mouseNames input
if ischar(mouseNames) && strcmp(mouseNames, 'ALL')
    % Extract all unique mouse names from the data
    allMouseNames = {miniAnalysisData.mouseName};
    mouseNames = unique(allMouseNames);
    fprintf('Using all mice: %s\n', strjoin(mouseNames, ', '));
elseif ~iscell(mouseNames)
    error('mouseNames must be a cell array of strings or "ALL"');
end

% Process sessionTypes input
validSessionTypes = {'BASE', 'PARK', 'BOTH'};
if ~ismember(sessionTypes, validSessionTypes)
    error('sessionTypes must be one of: %s', strjoin(validSessionTypes, ', '));
end

% Define session type keywords for matching
if strcmp(sessionTypes, 'BASE')
    sessionKeywords = {'Baseline'};
elseif strcmp(sessionTypes, 'PARK')
    sessionKeywords = {'Parkinson'};
else % 'BOTH'
    sessionKeywords = {'Baseline', 'Parkinson'};
end

% Get minisession number from first valid session
minisessionNum = [];
for i = 1:length(miniAnalysisData)
    sampleData = miniAnalysisData(i).(parameterName);
    if iscell(sampleData)
        minisessionNum = length(sampleData);
        break;
    elseif isnumeric(sampleData)
        minisessionNum = length(sampleData);
        break;
    end
end

if isempty(minisessionNum)
    error('Could not determine minisession number from data');
end

% Collect and organize data
collectiveData = [];
groupLabels = {};
groupColors = [];
colorMap = lines(length(mouseNames) * length(sessionKeywords));
colorIdx = 1;

fprintf('Collecting data for %d mice and %d session types:\n', length(mouseNames), length(sessionKeywords));

for mouseIdx = 1:length(mouseNames)
    targetMouse = mouseNames{mouseIdx};
    
    for sessionTypeIdx = 1:length(sessionKeywords)
        sessionKeyword = sessionKeywords{sessionTypeIdx};
        
        % Find sessions for this mouse and session type
        sessionIndices = [];
        for i = 1:length(miniAnalysisData)
            if contains(miniAnalysisData(i).mouseName, targetMouse) && ...
               contains(miniAnalysisData(i).sessionName, sessionKeyword)
                sessionIndices(end+1) = i;
            end
        end
        
        if ~isempty(sessionIndices)
            % Extract parameter data for these sessions
            sessionData = zeros(length(sessionIndices), minisessionNum);
            
            for i = 1:length(sessionIndices)
                sessionIdx = sessionIndices(i);
                paramData = miniAnalysisData(sessionIdx).(parameterName);
                
                if iscell(paramData)
                    % Handle cell array data
                    for ms = 1:minisessionNum
                        if iscell(paramData{ms})
                            sessionData(i, ms) = length(paramData{ms});
                        elseif isnumeric(paramData{ms})
                            sessionData(i, ms) = length(paramData{ms});
                        else
                            sessionData(i, ms) = paramData{ms};
                        end
                    end
                else
                    % Handle numeric array data
                    sessionData(i, :) = paramData;
                end
            end
            
            % Average across sessions for this mouse-sessionType combination
            mouseSessionAvg = mean(sessionData, 1);
            collectiveData = [collectiveData; mouseSessionAvg];
            
            % Create group label
            sessionTypeShort = sessionKeyword;
            if strcmp(sessionKeyword, 'Baseline')
                sessionTypeShort = 'BASE';
            elseif strcmp(sessionKeyword, 'Parkinson')
                sessionTypeShort = 'PARK';
            end
            groupLabels{end+1} = sprintf('%s_%s', targetMouse, sessionTypeShort);
            groupColors = [groupColors; colorMap(colorIdx, :)];
            colorIdx = colorIdx + 1;
            
            fprintf('  %s %s: %d sessions averaged\n', targetMouse, sessionKeyword, length(sessionIndices));
        else
            fprintf('  %s %s: No sessions found\n', targetMouse, sessionKeyword);
        end
    end
end

if isempty(collectiveData)
    error('No data found for the specified mice and session types');
end

% Calculate overall mean and statistics across all groups
overallMean = mean(collectiveData, 1);
overallStd = std(collectiveData, 1);
overallSEM = overallStd / sqrt(size(collectiveData, 1)); % Standard Error of Mean
minisessionNumbers = 1:minisessionNum;

% Perform statistical testing between adjacent minisessions
pValues = [];
for i = 1:(minisessionNum-1)
    % Paired t-test between adjacent minisessions
    [~, p] = ttest(collectiveData(:, i), collectiveData(:, i+1));
    pValues(end+1) = p;
end

% Create the plot
figure('Position', [100, 100, 1200, 800]);
hold on;

% Create bar plot for the overall mean with different colors for odd/even minisessions
barColors = zeros(minisessionNum, 3);
for i = 1:minisessionNum
    if mod(i, 2) == 0
        barColors(i, :) = [0, 0.8, 0]; % Green for even minisessions (Laser ON)
    else
        barColors(i, :) = [0.7, 0.7, 0.7]; % Gray for odd minisessions (Laser OFF)
    end
end

% Plot bars individually with different colors
barHandles = [];
for i = 1:minisessionNum
    h = bar(i, overallMean(i), 'FaceColor', barColors(i, :), 'EdgeColor', 'black', 'LineWidth', 1);
    barHandles(end+1) = h;
end

% Add error bars
errorbar(minisessionNumbers, overallMean, overallSEM, 'k', 'LineStyle', 'none', ...
         'LineWidth', 1.5, 'CapSize', 4);

% Add individual group data points as scatter plot with connecting lines
scatterHandles = [];
lineHandles = [];
for groupIdx = 1:size(collectiveData, 1)
    % Plot connecting line first (so it appears behind points)
    h_line = plot(minisessionNumbers, collectiveData(groupIdx, :), '-', ...
                  'Color', groupColors(groupIdx, :), 'LineWidth', 2, 'MarkerSize', 8);
    lineHandles(end+1) = h_line;
    
    % Add scatter points on top of line
    h_scatter = scatter(minisessionNumbers, collectiveData(groupIdx, :), 80, groupColors(groupIdx, :), ...
                       'filled', 'MarkerEdgeColor', 'black', 'LineWidth', 1);
    scatterHandles(end+1) = h_scatter;
end

% Add statistical significance stars between adjacent bars
ymax = max(overallMean + overallSEM);
ymin = min(overallMean - overallSEM);
yRange = ymax - ymin;
starHeight = ymax + 0.05 * yRange; % Position stars slightly above the highest error bar

for i = 1:length(pValues)
    p = pValues(i);
    x_pos = i + 0.5; % Position between adjacent bars
    
    % Determine significance symbol
    if p < 0.001
        sigSymbol = '***';
    elseif p < 0.01
        sigSymbol = '**';
    elseif p < 0.05
        sigSymbol = '*';
    else
        sigSymbol = 'ns'; % not significant
    end
    
    % Plot significance symbol
    if ~strcmp(sigSymbol, 'ns')
        text(x_pos, starHeight, sigSymbol, 'HorizontalAlignment', 'center', ...
             'FontSize', 12, 'FontWeight', 'bold', 'Color', [1, 0, 0]); % Red color as RGB
        
        % Add line connecting the two bars being compared
        lineY = starHeight - 0.01 * yRange;
        plot([i, i+1], [lineY, lineY], 'k-', 'LineWidth', 1);
        plot([i, i], [lineY, lineY - 0.005 * yRange], 'k-', 'LineWidth', 1);
        plot([i+1, i+1], [lineY, lineY - 0.005 * yRange], 'k-', 'LineWidth', 1);
    else
        % Show p-value for non-significant comparisons
        text(x_pos, starHeight, sprintf('p=%.3f', p), 'HorizontalAlignment', 'center', ...
             'FontSize', 8, 'FontWeight', 'normal', 'Color', [0.5, 0.5, 0.5]); % Gray color as RGB
    end
end

% Customize the plot
xlabel('Minisession Number (Temporal Progression)', 'FontSize', 12, 'FontWeight', 'bold');

% Create appropriate y-label based on parameter
yLabelText = formatParameterName(parameterName);
ylabel(yLabelText, 'FontSize', 12, 'FontWeight', 'bold');

% Create title
mouseText = sprintf('%s', strjoin(mouseNames, ', '));
if length(mouseText) > 50
    mouseText = sprintf('%d mice', length(mouseNames));
end
title(sprintf('%s - %s (%s) (n=%d groups)\nConnected lines show temporal progression. Error bars: SEM. Stars: p<0.05*, p<0.01**, p<0.001***', ...
      yLabelText, mouseText, sessionTypes, size(collectiveData, 1)), ...
      'FontSize', 12, 'FontWeight', 'bold', 'Interpreter', 'none');

% Set axis properties
xlim([0.5, minisessionNum + 0.5]);
% Adjust y-axis to accommodate significance stars
ylim([0, starHeight + 0.5*yRange]);
xticks(1:minisessionNum);
grid on;
grid minor;

% Add legend
legendEntries = cell(size(collectiveData, 1) + 2, 1);
legendEntries{1} = 'Mean (Odd - Laser OFF)';
legendEntries{2} = 'Mean (Even - Laser ON)';
for i = 1:size(collectiveData, 1)
    legendEntries{i+2} = groupLabels{i};
end

% Create legend handles - use lines for individual groups since they show temporal progression
oddBarIdx = find(mod(1:minisessionNum, 2) == 1, 1);
evenBarIdx = find(mod(1:minisessionNum, 2) == 0, 1);
legendHandles = [barHandles(oddBarIdx), barHandles(evenBarIdx), lineHandles];
legend(legendHandles, legendEntries, 'Location', 'bestoutside', 'FontSize', 8, 'Interpreter', 'none');

hold off;

% Display summary statistics
fprintf('\n%s Collective Summary (%d groups):\n', yLabelText, size(collectiveData, 1));
fprintf('Minisession\tMean±SEM\tStd\tLaser\tGroups\n');
for ms = 1:minisessionNum
    laserStatus = '';
    if mod(ms, 2) == 0
        laserStatus = 'ON';
    else
        laserStatus = 'OFF';
    end
    fprintf('%d\t\t%.2f±%.2f\t%.2f\t%s\t%s\n', ms, overallMean(ms), overallSEM(ms), overallStd(ms), ...
            laserStatus, sprintf('%.2f ', collectiveData(:, ms)));
end

% Display statistical comparisons
fprintf('\nStatistical Comparisons (Adjacent Minisessions):\n');
fprintf('Comparison\t\tp-value\tSignificance\n');
for i = 1:length(pValues)
    p = pValues(i);
    if p < 0.001
        sigLevel = '***';
    elseif p < 0.01
        sigLevel = '**';
    elseif p < 0.05
        sigLevel = '*';
    else
        sigLevel = 'ns';
    end
    fprintf('%d vs %d\t\t%.4f\t%s\n', i, i+1, p, sigLevel);
end

fprintf('\nGroup composition:\n');
for i = 1:length(groupLabels)
    fprintf('  %s\n', groupLabels{i});
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
