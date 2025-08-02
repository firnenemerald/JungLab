%% CLOI (Closed-Loop Optogenetic Inhibition) - CLOI Analysis

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

clear; close all;

baseDir = "D:\CLOI_CHJ\CLOI";

%% Get mouse and session names
sessionDir = dir(baseDir);
mouseNames = {};
sessionNames = {};
for i = 1:length(sessionDir)
    if sessionDir(i).isdir && ~ismember(sessionDir(i).name, {'.', '..'})
        sessionName = sessionDir(i).name;
        sessionNames{end+1, 1} = sessionName;
        sessionNameParts = split(sessionName, '_');
        mouseName = strcat(sessionNameParts{1}, '_', sessionNameParts{2});
        if isempty(mouseNames) || ~isequal(mouseName, mouseNames{end})
            mouseNames{end+1, 1} = mouseName;
        end
    end
end
clear sessionDir;
clear sessionName;
clear sessionNameParts;
clear mouseName;

%% Summarize session data
sessionCount = cell(length(mouseNames), 2);
for i = 1:length(mouseNames)
    sessionCount{i, 1} = 0; % Initialize CLOI count for each mouse
    sessionCount{i, 2} = 0; % Initialize RAND count for each mouse
    for j = 1:length(sessionNames)
        if contains(sessionNames{j}, mouseNames{i}) && contains(sessionNames{j}, 'CLOI')
            sessionCount{i, 1} = sessionCount{i, 1} + 1;
        elseif contains(sessionNames{j}, mouseNames{i}) && contains(sessionNames{j}, 'Random')
            sessionCount{i, 2} = sessionCount{i, 2} + 1;
        end
    end
    % fprintf('Mouse %s: %d CLOI sessions, %d Random sessions\n', mouseNames{i}, sessionCount{i, 1}, sessionCount{i, 2});
end

%% Get session data
sessionData_CLOI_Base = struct('mouseName', {}, 'sessionName', {}, 'mazeGeometry', {});
sessionData_CLOI_DLC = struct('dlcTime', {}, 'dlcHead', {}, 'dlcBody', {}, 'dlcTail', {});
sessionData_CLOI_OCV = struct('mvTime', {}, 'mvState', {}, 'mvCent', {}, 'lsTime', {}, 'lsState', {});
for sIdx = 1:length(sessionNames)
    sessionName = sessionNames{sIdx};
    sessionNameParts = split(sessionName, '_');
    mouseName = strcat(sessionNameParts{1}, '_', sessionNameParts{2});
    sessionDir = fullfile(baseDir, sessionName);
    fprintf('Processing session: %s\n', sessionName);

    sessionData_CLOI_Base(sIdx).mouseName = mouseName;
    sessionData_CLOI_Base(sIdx).sessionName = sessionName;

    % Get the maze geometry (center and radius)
    sessionVid = fullfile(sessionDir, 'output_video.mp4');
    if ~exist(sessionVid, 'file')
        error('Session video file does not exist: %s\n', sessionVid);
    end
    sessionVidObj = VideoReader(sessionVid);
    middleFrameIdx = round(sessionVidObj.NumFrames / 2);
    middleFrame = read(sessionVidObj, middleFrameIdx);
    blueMask = (middleFrame(:, :, 3) > 220);
    img = ones(size(middleFrame, 1), size(middleFrame, 2))*255;
    img(blueMask) = 0;
    img = uint8(img);
    [centerX, centerY, radius, ~] = CLOI_GetCircleFromUser(img);
    sessionData_CLOI_Base(sIdx).mazeGeometry.center = [centerX, centerY];
    sessionData_CLOI_Base(sIdx).mazeGeometry.radius = radius;

end