%% CLOI (Closed-Loop Optogenetic Inhibition) - CLOI Analysis

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

clear; close all;

baseDir = "H:\CLOI"; % Base directory, change as needed
if ~isfolder(baseDir)
    error('Base directory does not exist: %s\n', baseDir);
end

%% Get mouse and session names
sessionDir = dir(baseDir);
mouseNames = {};
sessionNames = {};
for i = 1:length(sessionDir)
    if sessionDir(i).isdir && ~ismember(sessionDir(i).name, {'.', '..'})
        sessionNameTemp = sessionDir(i).name;
        sessionNames{end+1, 1} = sessionNameTemp;
        sessionNamePartTemp = split(sessionNameTemp, '_');
        mouseNameTemp = strcat(sessionNamePartTemp{1}, '_', sessionNamePartTemp{2});
        if isempty(mouseNames) || ~isequal(mouseNameTemp, mouseNames{end})
            mouseNames{end+1, 1} = mouseNameTemp;
        end
    end
end

%% Summarize session data
mouseNum = length(mouseNames);
sessionNum = length(sessionNames);
fprintf('Total mice #: %d, Total session #: %d\n', mouseNum, sessionNum);

% Count sessions for individual mouse
sessionCount = cell(mouseNum, 2);
for i = 1:mouseNum
    sessionCount{i, 1} = 0; % Initialize CLOI count for each mouse
    sessionCount{i, 2} = 0; % Initialize RAND count for each mouse
    for j = 1:sessionNum
        if contains(sessionNames{j}, mouseNames{i}) && contains(sessionNames{j}, 'CLOI')
            sessionCount{i, 1} = sessionCount{i, 1} + 1;
        elseif contains(sessionNames{j}, mouseNames{i}) && contains(sessionNames{j}, 'Random')
            sessionCount{i, 2} = sessionCount{i, 2} + 1;
        end
    end
    fprintf('Mouse %s: %d CLOI sessions, %d Random sessions\n', mouseNames{i}, sessionCount{i, 1}, sessionCount{i, 2});
end

%% Get session data
sessionData_CLOI = struct('mouseName', {}, 'sessionName', {}, 'mazeGeometry', {}, 'dlcTime', {}, 'dlcHead', {}, 'dlcBody', {}, 'dlcTail', {}, 'mvTime', {}, 'mvState', {}, 'mvCenter', {}, 'lsTime', {}, 'lsState', {});

% Iterate through each session and extract data
for sIdx = 1:sessionNum
    sessionName = sessionNames{sIdx};
    sessionNamePart = split(sessionName, '_');
    mouseName = strcat(sessionNamePart{1}, '_', sessionNamePart{2});
    sessionDir = fullfile(baseDir, sessionName);
    fprintf('Processing session: %s\n', sessionName);

    sessionData_CLOI(sIdx).mouseName = mouseName;
    sessionData_CLOI(sIdx).sessionName = sessionName;

    % Get maze geometry (center and radius)
    sessionVid = fullfile(sessionDir, 'output_video.mp4');
    if ~exist(sessionVid, 'file')
        error('Session video file does not exist: %s\n', sessionVid);
    end
    sessionVidObj = VideoReader(sessionVid);
    middleFrameIdx = round(sessionVidObj.NumFrames / 2);
    middleFrame = read(sessionVidObj, middleFrameIdx);
    img = ones(size(middleFrame, 1), size(middleFrame, 2))*255;
    img(middleFrame(:, :, 3) > 220) = 0;
    img = uint8(img);
    [centerX, centerY, radius, ~] = CLOI_GetCircleFromUser(img);
    if isempty(centerX) || isempty(centerY) || isempty(radius)
        error('Failed to get maze geometry from video: %s\n', sessionVid);
    end
    sessionData_CLOI(sIdx).mazeGeometry = struct('center', [centerX, centerY], 'radius', radius);

    % Get DLC data
    [dlcTime, dlcHeadX, dlcHeadY, dlcHeadConf] = CLOI_GetDLCData(defaultDir, sessionName, mousePart);
    sessionData_CLOI(sIdx).dlcTime = dlcTime;
    sessionData_CLOI(sIdx).dlcHead = [dlcCoordX, dlcCoordY, dlcCoordConf];
end