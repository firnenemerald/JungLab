%% Function to get the file metadata of all mice
% Returns the file metadata of all mice (cell array with size: mouse num x n)

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function allMouseMeta = GetAllMouseMeta(baseDir, doDisplay)
    % Get all mouse folder directories
    mouseList = dir(baseDir);
    mouseList = mouseList([mouseList.isdir]);
    mouseList = mouseList(~ismember({mouseList.name}, {'.', '..'}));
    
    % Initialize variables
    allMouseMeta = {};

    for mouseIndex = 1:length(mouseList)
        mouseName = mouseList(mouseIndex).name;
        mouseDir = fullfile(baseDir, mouseName);
        
        % Check for Baseline files
        baselineCellSignal = isfile(fullfile(mouseDir, [mouseName '_B.csv'])) && ...
                     isfile(fullfile(mouseDir, [mouseName '_B-props.csv']));
        baselineGpioSignal = isfile(fullfile(mouseDir, [mouseName '_B_gpio.csv']));
        baselineDlcData = isfile(fullfile(mouseDir, [mouseName '_B_dlc.csv']));
        
        % Check for Parkinson files
        parkinsonCellSignal = isfile(fullfile(mouseDir, [mouseName '_P.csv'])) && ...
                      isfile(fullfile(mouseDir, [mouseName '_P-props.csv']));
        parkinsonGpioSignal = isfile(fullfile(mouseDir, [mouseName '_P_gpio.csv']));
        parkinsonDlcData = isfile(fullfile(mouseDir, [mouseName '_P_dlc.csv']));
        
        % Create the metadata row
        mouseMeta = {mouseName, mouseDir, baselineCellSignal, baselineGpioSignal, baselineDlcData, ...
                 parkinsonCellSignal, parkinsonGpioSignal, parkinsonDlcData};
        
        % Append the metadata to the list
        allMouseMeta = [allMouseMeta; mouseMeta];
    end

    % Display the metadata is doDisplay is true
    if doDisplay
        headers = {'mouseName', 'mouseDir', 'B_signal', 'B_gpio', 'B_dlc', 'P_signal', 'P_gpio', 'P_dlc'};

        % Convert boolean values to 'O' and 'X'
        allMouseMeta = cellfun(@(x) logicalToOX(x), allMouseMeta, 'UniformOutput', false);
        
        % Display the table without curly braces
        disp(cell2table(allMouseMeta, 'VariableNames', headers));
    end
end

%% Helper function that returns 'O' if x == true, 'X' if x == false (only if x is logical)

function out = logicalToOX(x)
    if islogical(x)
        if x
            out = 'O';
        else
            out = 'X';
        end
    else
        out = x;
    end
end