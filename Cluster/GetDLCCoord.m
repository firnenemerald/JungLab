%% Function to get the DeepLabCut (DLC) data of specified mouse and status
% Returns DLC coordinate data (array with size: time point num x (1 + 2 + 2 + 2))

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function dlcArray = GetDLCCoord(mouseName, mouseStatus, mousePart, baseDirectory)
    % Set default base directory
    baseDir = baseDirectory;
    
    % Construct file paths
    dlcFile = fullfile(baseDir, mouseName, [mouseName '_' mouseStatus '_dlc.csv']);
    
    % Read the CSV file
    dlcArray = table2array(readtable(dlcFile));
    
    % Extract the DLC coordinate data
    dlcArrayHead = dlcArray(:, [1, 2:4]);
    dlcArrayCent = dlcArray(:, [1, 5:7]);
    dlcArrayTail = dlcArray(:, [1, 8:10]);

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