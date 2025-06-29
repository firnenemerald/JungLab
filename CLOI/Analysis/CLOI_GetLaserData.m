%% Function to get the Laser status data of specified session

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function [lsTime, lsState] = CLOI_GetLaserData(defaultDir, sessionName)
    
    % Find movement csv file inside directory
    sessionParts = split(sessionName, '_');
    mouseName = sessionParts{1} + "_" + sessionParts{2};
    lsFileDir = dir(fullfile(defaultDir, mouseName, sessionName, "Log", "log_laser_*.csv"));
    % Check if such file exists
    if isempty(lsFileDir)
        error('Movement file not found in the specified directory: %s', lsFileDir.name);
    end
    lsFile = fullfile(defaultDir, mouseName, sessionName, "Log", lsFileDir.name);

    % Read the csv file and extract movement data
    lsTable = readtable(lsFile, "ReadVariableNames", false);
    lsTime = table2array(lsTable(:, 2));
    lsState = table2array(lsTable(:, 3));
end