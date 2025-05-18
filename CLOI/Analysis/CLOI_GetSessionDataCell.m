%% Function to get specific session data for specified mice

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

% mouseState = "All" for all states, "Baseline" for baseline, "Parkinson" for parkinsonian state
% expType = "Both" for both experiments, "CLOI" for CLOI experiment, "Random" for random experiment
% miniSession = "All" for all sessions, "OFF" for MS1, 3, 5, "ON" for MS 2, 4, 6, "Rest" for MS2-6, "MS1" ~ "MS6" for specific sessions
% isMerged = true for merging all session data, false for separating session data
function sessionData = CLOI_GetSessionDataCell(sessionDataStruct, mouseState, expType, miniSession, isMerged)
    
    % Preallocate sessionData
    sessionData = {};

    % Check mouse state and experiment type to filter session data
    sessionDataBase = sessionDataStruct(contains({sessionDataStruct.sessionName}, '_Baseline_'));
    sessionDataPark = sessionDataStruct(contains({sessionDataStruct.sessionName}, '_Parkinson_'));
    if strcmp(mouseState, "All")
        if strcmp(expType, "Both")
            sessionData = sessionDataStruct;
        elseif strcmp(expType, "CLOI")
            sessionData = sessionDataStruct(contains({sessionDataStruct.sessionName}, '_CLOI_'));
        elseif strcmp(expType, "Random")
            sessionData = sessionDataStruct(contains({sessionDataStruct.sessionName}, '_Random_'));
        end
    elseif mouseState == "Baseline"
        if strcmp(expType, "Both")
            sessionData = sessionDataBase;
        elseif strcmp(expType, "CLOI")
            sessionData = sessionDataBase(contains({sessionDataBase.sessionName}, '_CLOI_'));
        elseif strcmp(expType, "Random")
            sessionData = sessionDataBase(contains({sessionDataBase.sessionName}, '_Random_'));
        end
    elseif mouseState == "Parkinson"
        if strcmp(expType, "Both")
            sessionData = sessionDataPark;
        elseif strcmp(expType, "CLOI")
            sessionData = sessionDataPark(contains({sessionDataPark.sessionName}, '_CLOI_'));
        elseif strcmp(expType, "Random")
            sessionData = sessionDataPark(contains({sessionDataPark.sessionName}, '_Random_'));
        end
    else
        error('Invalid mouse state or experiment type specified. Please check the input parameters.');
    end

    % Filter session data based on miniSession
    fieldNameList = fieldnames(sessionData);
    if strcmp(miniSession, "All")
        % No filtering needed, all sessions are included
    elseif strcmp(miniSession, "OFF")
        for sessionidx = 1:length(sessionData)
            sessionMvTime = sessionData(sessionidx).mvTime;
            sessionLsTime = sessionData(sessionidx).lsTime;
            sessionFilter = (sessionMvTime >= 10.0 & sessionMvTime < 120.0) | (sessionMvTime >= 240.0 & sessionMvTime < 360.0) | (sessionMvTime >= 480.0 & sessionMvTime < 600.0);
            for residx = 2:length(fieldNameList)-2
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter, :);
            end
            sessionFilter2 = (sessionLsTime >= 10.0 & sessionLsTime < 120.0) | (sessionLsTime >= 240.0 & sessionLsTime < 360.0) | (sessionLsTime >= 480.0 & sessionLsTime < 600.0);
            for residx = length(fieldNameList)-1:length(fieldNameList)
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter2, :);
            end
        end
    elseif strcmp(miniSession, "ON")
        for sessionidx = 1:length(sessionData)
            sessionMvTime = sessionData(sessionidx).mvTime;
            sessionLsTime = sessionData(sessionidx).lsTime;
            sessionFilter = (sessionMvTime >= 120.0 & sessionMvTime < 240.0) | (sessionMvTime >= 360.0 & sessionMvTime < 480.0) | (sessionMvTime >= 600.0 & sessionMvTime < 720.0);
            for residx = 2:length(fieldNameList)-2
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter, :);
            end
            sessionFilter2 = (sessionLsTime >= 120.0 & sessionLsTime < 240.0) | (sessionLsTime >= 360.0 & sessionLsTime < 480.0) | (sessionLsTime >= 600.0 & sessionLsTime < 720.0);
            for residx = length(fieldNameList)-1:length(fieldNameList)
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter2, :);
            end
        end
    elseif strcmp(miniSession, "Rest")
        for sessionidx = 1:length(sessionData)
            sessionMvTime = sessionData(sessionidx).mvTime;
            sessionLsTime = sessionData(sessionidx).lsTime;
            sessionFilter = (sessionMvTime >= 120.0 & sessionMvTime < 600.0);
            for residx = 2:length(fieldNameList)-2
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter, :);
            end
            sessionFilter2 = (sessionLsTime >= 120.0 & sessionLsTime < 600.0);
            for residx = length(fieldNameList)-1:length(fieldNameList)
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter2, :);
            end
        end
    elseif strcmp(miniSession, "MS1")
        for sessionidx = 1:length(sessionData)
            sessionMvTime = sessionData(sessionidx).mvTime;
            sessionLsTime = sessionData(sessionidx).lsTime;
            sessionFilter = (sessionMvTime >= 10.0 & sessionMvTime < 120.0);
            for residx = 2:length(fieldNameList)-2
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter, :);
            end
            sessionFilter2 = (sessionLsTime >= 10.0 & sessionLsTime < 120.0);
            for residx = length(fieldNameList)-1:length(fieldNameList)
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter2, :);
            end
        end
    elseif strcmp(miniSession, "MS2")
        for sessionidx = 1:length(sessionData)
            sessionMvTime = sessionData(sessionidx).mvTime;
            sessionLsTime = sessionData(sessionidx).lsTime;
            sessionFilter = (sessionMvTime >= 120.0 & sessionMvTime < 240.0);
            for residx = 2:length(fieldNameList)-2
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter, :);
            end
            sessionFilter2 = (sessionLsTime >= 120.0 & sessionLsTime < 240.0);
            for residx = length(fieldNameList)-1:length(fieldNameList)
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter2, :);
            end
        end
    elseif strcmp(miniSession, "MS3")
        for sessionidx = 1:length(sessionData)
            sessionMvTime = sessionData(sessionidx).mvTime;
            sessionLsTime = sessionData(sessionidx).lsTime;
            sessionFilter = (sessionMvTime >= 240.0 & sessionMvTime < 360.0);
            for residx = 2:length(fieldNameList)-2
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter, :);
            end
            sessionFilter2 = (sessionLsTime >= 240.0 & sessionLsTime < 360.0);
            for residx = length(fieldNameList)-1:length(fieldNameList)
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter2, :);
            end
        end
    elseif strcmp(miniSession, "MS4")
        for sessionidx = 1:length(sessionData)
            sessionMvTime = sessionData(sessionidx).mvTime;
            sessionLsTime = sessionData(sessionidx).lsTime;
            sessionFilter = (sessionMvTime >= 360.0 & sessionMvTime < 480.0);
            for residx = 2:length(fieldNameList)-2
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter, :);
            end
            sessionFilter2 = (sessionLsTime >= 360.0 & sessionLsTime < 480.0);
            for residx = length(fieldNameList)-1:length(fieldNameList)
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter2, :);
            end
        end
    elseif strcmp(miniSession, "MS5")
        for sessionidx = 1:length(sessionData)
            sessionMvTime = sessionData(sessionidx).mvTime;
            sessionLsTime = sessionData(sessionidx).lsTime;
            sessionFilter = (sessionMvTime >= 480.0 & sessionMvTime < 600.0);
            for residx = 2:length(fieldNameList)-2
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter, :);
            end
            sessionFilter2 = (sessionLsTime >= 480.0 & sessionLsTime < 600.0);
            for residx = length(fieldNameList)-1:length(fieldNameList)
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter2, :);
            end
        end
    elseif strcmp(miniSession, "MS6")
        for sessionidx = 1:length(sessionData)
            sessionMvTime = sessionData(sessionidx).mvTime;
            sessionLsTime = sessionData(sessionidx).lsTime;
            sessionFilter = (sessionMvTime >= 600.0 & sessionMvTime < 720.0);
            for residx = 2:length(fieldNameList)-2
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter, :);
            end
            sessionFilter2 = (sessionLsTime >= 600.0 & sessionLsTime < 720.0);
            for residx = length(fieldNameList)-1:length(fieldNameList)
                sessionData(sessionidx).(fieldNameList{residx}) = sessionData(sessionidx).(fieldNameList{residx})(sessionFilter2, :);
            end
        end
    else
        error('Invalid miniSession specified. Please check the input parameter.');
    end

    % Check isMerged boolean to merge session data
    if isMerged
        sessionDataMerged = sessionData(3:3:end); % Placeholder for merged data
        fieldNameList = fieldnames(sessionDataMerged);
        % Iterate through each session data to merge
        for sessionidx = 1:round(length(sessionDataMerged))
            % Make a new merged session name
            singleSession = sessionDataMerged(sessionidx);
            singleSessionName = singleSession.sessionName;
            singleSessionNameParts = strsplit(singleSessionName, '_');
            singleSessionNameMerged = singleSessionNameParts{1} + "_" + singleSessionNameParts{2} + "_" + singleSessionNameParts{3} + "_" + singleSessionNameParts{4} + "_Merged";
            sessionDataMerged(sessionidx).(fieldNameList{1}) = singleSessionNameMerged;
            % Merge session data
            for residx = 2:length(fieldNameList)
                singleSessionData = [sessionData(sessionidx * 3 - 2).(fieldNameList{residx}); sessionData(sessionidx * 3 - 1).(fieldNameList{residx}); sessionData(sessionidx * 3).(fieldNameList{residx})];
                sessionDataMerged(sessionidx).(fieldNameList{residx}) = singleSessionData;
            end
        end
        % Assign merged session data to sessionData
        sessionData = sessionDataMerged;
    end
end