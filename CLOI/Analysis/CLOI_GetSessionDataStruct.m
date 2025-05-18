%% Function to get session data for specified mice

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function sessionData = CLOI_GetSessionDataStruct(defaultDir, sessionNameCell)

    % Preallocate sessionData struct
    sessionData = struct('sessionName', [], 'dlcTime', [], 'dlcCoordX', [], 'dlcCoordY', [], 'mvTime', [], 'mvState', [], 'mvCentX', [], 'mvCentY', [], 'lsTime', [], 'lsState', []);

    % Iterate through each session name
    for sessionidx = 1:length(sessionNameCell)
        sessionName = sessionNameCell{sessionidx};
        sessionData(sessionidx).sessionName = sessionName;
        
        % Load DeepLabCut data
        [dlcTime, dlcCoordX, dlcCoordY] = CLOI_GetDLCData(defaultDir, sessionName, 'head');
        sessionData(sessionidx).dlcTime = dlcTime;
        sessionData(sessionidx).dlcCoordX = dlcCoordX;
        sessionData(sessionidx).dlcCoordY = dlcCoordY;
        
        % Load Movement data
        [mvTime, mvState, mvCentX, mvCentY] = CLOI_GetMvData(defaultDir, sessionName);
        sessionData(sessionidx).mvTime = mvTime;
        sessionData(sessionidx).mvState = mvState;
        sessionData(sessionidx).mvCentX = mvCentX;
        sessionData(sessionidx).mvCentY = mvCentY;
        
        % Load Laser data
        [lsTime, lsState] = CLOI_GetLaserData(defaultDir, sessionName);
        sessionData(sessionidx).lsTime = lsTime;
        sessionData(sessionidx).lsState = lsState;
    end
end