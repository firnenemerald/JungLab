%% CLOI Open Field Get Session Data

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function sessionData = CLOI_GetSessionData(defaultDir)

    % Check if mat file already exists (CLOI_SessionData_*.mat)
    matFiles = dir(fullfile(defaultDir, 'CLOI_SessionData_*.mat'));
    if ~isempty(matFiles)
        fprintf('Session data already exists. Loading from the latest file...\n');
        % Load the most recent mat file
        [~, idx] = max([matFiles.datenum]);
        matData = load(fullfile(defaultDir, matFiles(idx).name), 'sessionData');
        sessionData = matData.sessionData;
        fprintf('Loaded session data from %s\n', matFiles(idx).name);
        return;
    else
        fprintf('No existing session data found. Creating new session data...\n');
    end

    % Get mouse names from the default directory
    defaultDirContents = dir(defaultDir);
    mouseNames = {};
    for i = 1:length(defaultDirContents)
        if defaultDirContents(i).isdir && ~ismember(defaultDirContents(i).name, {'.', '..'})
            mouseNames{end+1, 1} = defaultDirContents(i).name;
        end
    end

    % Preallocate a struct to store session data
    sessionData = struct('mouseName', {}, 'sessionName', {}, 'center', {}, 'radius', {}, ...
        'dlcTime', {}, 'dlcCoordHeadX', {}, 'dlcCoordHeadY', {}, 'dlcCoordHeadConf', {}, ...
        'dlcCoordBodyX', {}, 'dlcCoordBodyY', {}, 'dlcCoordBodyConf', {}, ...
        'dlcCoordTailX', {}, 'dlcCoordTailY', {}, 'dlcCoordTailConf', {}, ...
        'mvTime', {}, 'mvState', {}, 'mvCentX', {}, 'mvCentY', {}, 'lsTime', {}, 'lsState', {});

    % Iterate through each mouse and get session data
    for mouseIdx = 1:length(mouseNames)
        mouseName = mouseNames{mouseIdx};

        % Make an empty cell variable to store session names for the current mouse
        mouseDirContents = dir(fullfile(defaultDir, mouseName));
        sessionNames = {};
        for j = 1:length(mouseDirContents)
            if mouseDirContents(j).isdir && ~ismember(mouseDirContents(j).name, {'.', '..'})
                sessionNames{end+1, 1} = mouseDirContents(j).name;
            end
        end
        
        % Iterate through each session and get DLC, movement, and laser data
        for sessionidx = 1:length(sessionNames)
            sessionName = sessionNames{sessionidx};
            sessionDataIdx = length(sessionData)+1;
            fprintf('Processing session # %s - %s\n', string(sessionDataIdx), sessionName);
            sessionData(sessionDataIdx).mouseName = mouseName;
            sessionData(sessionDataIdx).sessionName = sessionName;

            % Get Center and Radius
            [center, radius] = CLOI_GetCenterAndRadius(defaultDir, mouseName, sessionName);
            sessionData(sessionDataIdx).center = center;
            sessionData(sessionDataIdx).radius = radius;

            % Load DeepLabCut data
            [dlcTime, dlcCoordHeadX, dlcCoordHeadY, dlcCoordHeadConf] = CLOI_GetDLCData(defaultDir, sessionName, 'head');
            [~, dlcCoordBodyX, dlcCoordBodyY, dlcCoordBodyConf] = CLOI_GetDLCData(defaultDir, sessionName, 'center');
            [~, dlcCoordTailX, dlcCoordTailY, dlcCoordTailConf] = CLOI_GetDLCData(defaultDir, sessionName, 'tail');
            sessionData(sessionDataIdx).dlcTime = dlcTime;
            sessionData(sessionDataIdx).dlcCoordHeadX = dlcCoordHeadX;
            sessionData(sessionDataIdx).dlcCoordHeadY = dlcCoordHeadY;
            sessionData(sessionDataIdx).dlcCoordHeadConf = dlcCoordHeadConf;
            sessionData(sessionDataIdx).dlcCoordBodyX = dlcCoordBodyX;
            sessionData(sessionDataIdx).dlcCoordBodyY = dlcCoordBodyY;
            sessionData(sessionDataIdx).dlcCoordBodyConf = dlcCoordBodyConf;
            sessionData(sessionDataIdx).dlcCoordTailX = dlcCoordTailX;
            sessionData(sessionDataIdx).dlcCoordTailY = dlcCoordTailY;
            sessionData(sessionDataIdx).dlcCoordTailConf = dlcCoordTailConf;

            % Load Movement data
            [mvTime, mvState, mvCentX, mvCentY] = CLOI_GetMvData(defaultDir, sessionName);
            sessionData(sessionDataIdx).mvTime = mvTime;
            sessionData(sessionDataIdx).mvState = mvState;
            sessionData(sessionDataIdx).mvCentX = mvCentX;
            sessionData(sessionDataIdx).mvCentY = mvCentY;
            
            % Load Laser data
            [lsTime, lsState] = CLOI_GetLaserData(defaultDir, sessionName);
            sessionData(sessionDataIdx).lsTime = lsTime;
            sessionData(sessionDataIdx).lsState = lsState;
        end
    end

    % Save session data to a .mat file
    matFileName = 'CLOI_SessionData' + "_" + string(datetime('now', 'Format', 'yyyyMMdd')) + "_" + string(length(sessionData)) + ".mat";
    save(fullfile(defaultDir, matFileName), 'sessionData');

    return;
end