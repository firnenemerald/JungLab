%% CLOI Count number of laser events in the session data

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function [laserCount10, laserCount3] = CLOI_GetLaserCount(sessionData, sessionIndices)
    % Initialize counters
    laserCount10 = cell(0, 11); % FREQ sessions, 20 minisessions, 10 ON sessions
    laserCount3 = cell(0, 4); % Other sessions, 6 minisessions, 3 ON sessions
    % Iterate through each session
    for i = 1:length(sessionIndices)
        sIdx = sessionIndices(i);
        sessionLaserTime = sessionData(sIdx).lsTime;
        sessionLaserState = sessionData(sIdx).lsState;
        sessionName = string(sessionData(sIdx).sessionName);
        if sessionName.contains('FREQ') % FREQ sessions
            laserCount10{end+1, 1} = sessionData(sIdx).sessionName;
            for n = 1:10
                len = size(laserCount10, 1);
                msStart = (n-1) * 120 + 60; msEnd = n * 120;
                msLaserState = sessionLaserState((sessionLaserTime > msStart) & (sessionLaserTime < msEnd));
                laserCount10{len, n+1} = sum(diff([0; strcmp(msLaserState, 'ON')]) == 1); % Count ON events
            end
        elseif sessionName.contains('CONT') % CONT sessions
            laserCount3{end+1, 1} = sessionData(sIdx).sessionName;
            for n = 1:3
                len = size(laserCount3, 1);
                laserCount3{len, n+1} = 1; % ON events are always 1
            end
        else % CLOI, RAND sessions
            laserCount3{end+1, 1} = sessionData(sIdx).sessionName;
            for n = 1:3
                len = size(laserCount3, 1);
                msStart = (n-1) * 240 + 120; msEnd = n * 240;
                msLaserState = sessionLaserState((sessionLaserTime > msStart) & (sessionLaserTime < msEnd));
                laserCount3{len, n+1} = sum(diff([0; strcmp(msLaserState, 'ON')]) == 1); % Count ON events
            end
        end
    end
end