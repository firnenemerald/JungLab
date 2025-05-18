%% Function to get session names for specified mice

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function sessionNames = CLOI_GetSessionNameStruct(defaultDir, mouseNames)

    % Preallocate sessionNames struct
    sessionNames = struct('mouseName', [], 'sessionNameBaseCLOI', [], 'sessionNameBaseRAND', [], 'sessionNameParkCLOI', [], 'sessionNameParkRAND', []);

    % Iterate through each mouse name
    for mouseidx = 1:length(mouseNames)
        mouseName = mouseNames{mouseidx};
        mouseDir = fullfile(defaultDir, mouseName);
        % Check if the directory exists
        if ~isfolder(mouseDir)
            error('The specified directory does not exist: %s', fullfile(defaultDir, mouseName));
        end
        % Get the list of session directories
        sessionDirs = dir(mouseDir);
        sessionDirs = sessionDirs([sessionDirs.isdir] & ~startsWith({sessionDirs.name}, '.'));
        % Filter session directories to include specific formats
        sessionDirsBaseCLOI = sessionDirs(contains({sessionDirs.name}, '_Baseline_') & contains({sessionDirs.name}, '_CLOI_'));
        sessionDirsBaseRAND = sessionDirs(contains({sessionDirs.name}, '_Baseline_') & contains({sessionDirs.name}, '_Random_'));
        sessionDirsParkCLOI = sessionDirs(contains({sessionDirs.name}, '_Parkinson_') & contains({sessionDirs.name}, '_CLOI_'));
        sessionDirsParkRAND = sessionDirs(contains({sessionDirs.name}, '_Parkinson_') & contains({sessionDirs.name}, '_Random_'));
        % Extract session names and store them in the struct
        sessionNames(mouseidx).mouseName = {mouseName}';
        sessionNames(mouseidx).sessionNameBaseCLOI = {sessionDirsBaseCLOI.name}';
        sessionNames(mouseidx).sessionNameBaseRAND = {sessionDirsBaseRAND.name}';
        sessionNames(mouseidx).sessionNameParkCLOI = {sessionDirsParkCLOI.name}';
        sessionNames(mouseidx).sessionNameParkRAND = {sessionDirsParkRAND.name}';
    end
end