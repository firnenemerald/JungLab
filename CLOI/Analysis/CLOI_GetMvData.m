%% Function to get the movement status data of specified session

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function [mvTime, mvState, mvCentX, mvCentY] = CLOI_GetMvData(defaultDir, sessionName)
    
    % Find movement csv file inside directory
    sessionParts = split(sessionName, '_');
    mouseName = sessionParts{1} + "_" + sessionParts{2};
    mvFileDir = dir(fullfile(defaultDir, mouseName, sessionName, "Log", "log_movement_*.csv"));
    % Check if such file exists
    if isempty(mvFileDir)
        error('Movement file not found in the specified directory: %s', mvFileDir.name);
    end
    mvFile = fullfile(defaultDir, mouseName, sessionName, "Log", mvFileDir.name);

    % Read the csv file and extract movement data
    mvTable = readtable(mvFile, "Range", 2);
    mvTime = table2array(mvTable(:, 2)); % Time column
    mvState = table2array(mvTable(:, 3)); % Movement state column

    % Check if the movement data includes centroid coordinates
    if size(mvTable, 2) == 5
        mvCentX = table2array(mvTable(:, 4)); % Centroid coordinate X
        mvCentY = table2array(mvTable(:, 5)); % Centroid coordinate Y
    elseif size(mvTable, 2) == 3
        % No centroid coordinates available, only time and state
        mvCentX = NaN(size(mvTable, 1), 1); % Add NaN columns for empty centroid data X
        mvCentY = NaN(size(mvTable, 1), 1); % Add NaN columns for empty centroid data Y
    else
        error('Unexpected number of columns in movement data file: %d', size(mvTable, 2));
    end
end