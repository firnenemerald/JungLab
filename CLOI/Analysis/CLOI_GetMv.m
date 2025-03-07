%% Function to get the movement data of specified session
% Returns movement data (array with size: time point num x (1 + 1))

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

% For example, if session is ChAT_947-3_Baseline_CLOI_250109_145438,
% then mouseName is ChAT_947-3, mouseStatus is Baseline, expType is CLOI, dateTime is 250109_145438

function [mvArrayTime, mvArrayState] = CLOI_GetMv(mouseName, mouseStatus, expType, dateTime, baseDirectory)
    % Set default base directory
    baseDir = baseDirectory;
    % Construct session name
    sessionName = mouseName + "_" + mouseStatus + "_" + expType + "_" + dateTime;
    
    % Find movement csv file inside directory
    mvFileDir = dir(fullfile(baseDir, mouseName, sessionName, 'Log', 'log_movement_*.csv'));
    mvFile = fullfile(baseDir, mouseName, sessionName, 'Log', mvFileDir.name);

    % Read the csv file
    mvArray = readtable(mvFile, "Range", 2);

    % Extract the movement data
    mvArrayTime = table2array(mvArray(:, 2));
    mvArrayState = table2array(mvArray(:, 3));
end