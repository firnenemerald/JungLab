%% Function to get the DeepLabCut (DLC) data of specified session
% Returns DLC coordinate data (array with size: time point num x (1 + 2))

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

% For example, if session is ChAT_947-3_Baseline_CLOI_250109_145438,
% then mouseName is ChAT_947-3, mouseStatus is Baseline, expType is CLOI, dateTime is 250109_145438

function dlcArray = CLOI_GetDLC(mouseName, mouseStatus, expType, dateTime, mousePart, baseDirectory)
    % Set default base directory
    baseDir = baseDirectory;
    % Construct session name
    sessionName = mouseName + "_" + mouseStatus + "_" + expType + "_" + dateTime;
    
    % Find DLC csv file inside directory
    dlcFileDir = dir(fullfile(baseDir, mouseName, sessionName, '*.csv'));
    dlcFile = fullfile(baseDir, mouseName, sessionName, dlcFileDir.name);

    % Read the csv file
    dlcArray = table2array(readtable(dlcFile, "VariableNamingRule", "preserve"));
    
    % Extract the DLC coordinate data
    dlcArrayHead = dlcArray(:, [1, 2:3]);
    dlcArrayCent = dlcArray(:, [1, 5:6]);
    dlcArrayTail = dlcArray(:, [1, 8:9]);

    % Extract the DLC coordinate data for the specified mouse part
    switch mousePart
        case 'head'
            dlcArray = dlcArrayHead;
        case 'center'
            dlcArray = dlcArrayCent;
        case 'tail'
            dlcArray = dlcArrayTail;
        otherwise
            error('Invalid mouse part specified. Please specify either ''head'', ''center'', or ''tail''.');
    end
end