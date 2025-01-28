%% Function to get the signals of the paired cells of specified mouse
% Returns paired cell names (cell array with size: paired cell num x 2),
%   baseline signal (array with size - time point num x (1 + paired cell num)),
%   and parkinson signal (array with size - time point num x (1 + paired cell num))

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function [cellNamesPaired, signalArrayBase, signalArrayPark] = GetPairSignals(mouseName, baseDirectory)
    % Set default base directory
    baseDir = baseDirectory;
    
    % Construct file paths
    pairDir = fullfile(baseDir, 'inscopix_pair.xlsx');
    % Read data from the specified sheet
    pairArray = table2array(readtable(pairDir, 'Sheet', mouseName, 'Range', 'A:C', 'ReadVariableNames', false));
    
    % Get cell signal data
    cellSignalBase = GetCellSignal(mouseName, 'B', baseDir);
    cellSignalPark = GetCellSignal(mouseName, 'P', baseDir);

    % Initialize variables
    cellNamesPaired = [];
    signalArrayBase = cellSignalBase(:, 1); % Time
    signalArrayPark = cellSignalPark(:, 1); % Time

    for baseIndex = 1:size(pairArray, 1)
        cellNameBase = pairArray{baseIndex, 1};
        pairedName = pairArray{baseIndex, 2};
        
        % Check if baseline cell or paired name is empty
        if strcmp(cellNameBase, "") || strcmp(pairedName, "")
            continue;
        end

        % Find the index of paired name in the parkinson cell names
        parkIndex = find(strcmp(pairArray(:, 3), pairedName));

        % Append the cell names and signals
        cellNamesPaired = [cellNamesPaired; {cellNameBase, pairedName}];
        signalArrayBase = [signalArrayBase, cellSignalBase(:, baseIndex + 1)];
        signalArrayPark = [signalArrayPark, cellSignalPark(:, parkIndex + 1)];
    end
end