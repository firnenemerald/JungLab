%% Function to get the movement status data of specified session

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function [mvTime, mvState, mvCenter] = CLOI_GetMvData(MvDir)

    % Read the csv file and extract movement data
    mvTable = readtable(MvDir, "Range", 2);
    mvTime = table2array(mvTable(:, 2)); % Time column
    mvState = table2array(mvTable(:, 3)); % Movement state column

    % Check if the movement data includes centroid coordinates
    if size(mvTable, 2) == 5
        mvCentX = table2array(mvTable(:, 4)); % Centroid coordinate X
        mvCentY = table2array(mvTable(:, 5)); % Centroid coordinate Y
        mvCenter = [mvCentX, mvCentY]; % Combine X and Y into a single matrix
    elseif size(mvTable, 2) == 3
        % No centroid coordinates available, only time and state
        mvCentX = NaN(size(mvTable, 1), 1); % Add NaN columns for empty centroid data X
        mvCentY = NaN(size(mvTable, 1), 1); % Add NaN columns for empty centroid data Y
        mvCenter = [mvCentX, mvCentY]; % Combine X and Y into a single matrix
    else
        error('Unexpected number of columns in movement data file: %d', size(mvTable, 2));
    end
end