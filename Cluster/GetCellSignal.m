%% Function to extract the cell signal data of specified mouse and status
% Returns cell signal data (array with size: time point num x (1 + cell num))

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function cellArray = GetCellSignal(mouseName, mouseStatus)
    % Set default base directory
    baseDir = './data';
    
    % Construct file paths
    signalFile = fullfile(baseDir, 'inscopix_csv', [mouseName '_' mouseStatus '.csv']);
    propsFile = fullfile(baseDir, 'inscopix_csv', [mouseName '_' mouseStatus '-props.csv']);
    
    % Read the CSV files
    dataTable = readtable(signalFile);
    propsTable = readtable(propsFile);
    
    % Extract the cell signal data
    cellArrayTotal = table2array(dataTable);
    cellArray = cellArrayTotal(:, [1; find(string(propsTable.Status) == 'accepted') + 1]');
end