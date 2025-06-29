%% Function to get the DeepLabCut (DLC) data of specified session

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function [dlcTime, dlcCoordX, dlcCoordY, dlcCoordConf] = CLOI_GetDLCData(defaultDir, sessionName, mousePart)

    % Find DLC csv file inside directory
    sessionParts = split(sessionName, '_');
    mouseName = sessionParts{1} + "_" + sessionParts{2};
    dlcFileDir = dir(fullfile(defaultDir, mouseName, sessionName, sessionName + "*.csv"));
    % Check if such file exists
    if isempty(dlcFileDir)
        error('DLC file not found in the specified directory: %s', dlcFileDir.name);
    end
    dlcFile = fullfile(defaultDir, mouseName, sessionName, dlcFileDir.name);

    % Read the csv file and extract coordinate data
    dlcArray = table2array(readtable(dlcFile, "VariableNamingRule", "preserve"));
    dlcTime = dlcArray(:, 1); % Time column
    dlcHead = dlcArray(:, 2:4); % Head coordinates
    dlcCent = dlcArray(:, 5:7); % Center coordinates
    dlcTail = dlcArray(:, 8:10); % Tail coordinates

    % Extract the DLC coordinate data for the specified mouse part
    switch mousePart
        case 'head'
            dlcCoordX = dlcHead(:, 1); % X coordinate of head
            dlcCoordY = dlcHead(:, 2); % Y coordinate of head
            dlcCoordConf = dlcHead(:, 3); % Confidence of head coordinates
        case 'center'
            dlcCoordX = dlcCent(:, 1); % X coordinate of center
            dlcCoordY = dlcCent(:, 2); % Y coordinate of center
            dlcCoordConf = dlcCent(:, 3); % Confidence of center coordinates
        case 'tail'
            dlcCoordX = dlcTail(:, 1); % X coordinate of tail
            dlcCoordY = dlcTail(:, 2); % Y coordinate of tail
            dlcCoordConf = dlcTail(:, 3); % Confidence of tail coordinates
        otherwise
            error('Invalid mouse part specified. Please specify either ''head'', ''center'', or ''tail''.');
    end
end