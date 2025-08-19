%% Function to get the Laser status data of specified session

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function [lsTime, lsState] = CLOI_GetLaserData(LsDir)
    % Read the csv file and extract movement data
    lsTable = readtable(LsDir, "ReadVariableNames", false);
    lsTime = table2array(lsTable(:, 2));
    lsState = table2array(lsTable(:, 3));
end