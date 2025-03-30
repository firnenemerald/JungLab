%% Main script for CLOI OF analysis
% This script is the main script for the analysis of CLOI OF data.

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

% Clear the workspace
clear
close all

% Specify default directory and session name
baseDir = "D:\CLOI_data\ChAT_CLOI_rawdata";
defaultDir = "D:\CLOI_data\ChAT_CLOI_rawdata\ChAT_947-2";

% Get the list of session folders in the default directory
contents = dir(defaultDir);
folderNames = {contents([contents.isdir] & ~ismember({contents.name}, {'.', '..'})).name};

%% Iterate through each session folder to make totarray

% Initialize totarray to store session data
totarray = {};
for session = 1:length(folderNames)
    sessionName = char(folderNames(session));
    
    % Deconstruct mouse data from session name
    splitParts = split(sessionName, "_");
    mouseName = splitParts{1} + "_" + splitParts{2};
    mouseStatus = splitParts{3} + "";
    expType = splitParts{4} + "";
    dateTime = splitParts{5} + "_" + splitParts{6};
    
    % Load and plot DLC data
    dlcArray = CLOI_GetDLC(mouseName, mouseStatus, expType, dateTime, "head", baseDir);
    % CLOI_PlotDLC(mouseName, mouseStatus, expType, dateTime, "head", defaultDir);
    
    % Load movement data
    [mvArrayTime, mvArrayState] = CLOI_GetMv(mouseName, mouseStatus, expType, dateTime, baseDir);
    
    % Get minisession OFF/ON frames
    msOFFframebool = (mvArrayTime > 10.0 & mvArrayTime < 120.0) | (mvArrayTime > 240.0 & mvArrayTime < 360.0) | (mvArrayTime > 480.0 & mvArrayTime < 600.0);
    msONframebool = (mvArrayTime > 120.0 & mvArrayTime < 240.0) | (mvArrayTime > 360.0 & mvArrayTime < 480.0) | (mvArrayTime > 600.0 & mvArrayTime < 720.0);
    
    % Plot minisession OFF/ON DLC data
    % CLOI_PlotDLC(mouseName, mouseStatus, expType, dateTime, "head", defaultDir, msOFFframebool);
    % CLOI_PlotDLC(mouseName, mouseStatus, expType, dateTime, "head", defaultDir, msONframebool);
    % CLOI_PlotDLC(mouseName, mouseStatus, expType, dateTime, "head", defaultDir, msOFFframebool, msONframebool);
    
    % Extract the DLC data for OFF and ON frames
    OFFdlc = dlcArray(msOFFframebool,:); % OFFtime = mvArrayTime(msOFFframebool,:);
    ONdlc = dlcArray(msONframebool,:); % ONtime = mvArrayTime(msframebool,:);
    
    totarray(session, 1) = {sessionName};
    totarray(session, 2) = {OFFdlc};
    totarray(session, 3) = {ONdlc};
end

%% Get peak velocity to make totvdat

% Initialize totvdat to store velocity data
totvdat = {};
for session = 1:length(totarray)
    % OFF data
    tempdata = totarray{session, 2};

    % Separate OFF session data with time gaps
    tind = diff(tempdata(:, 1));
    block = find(tind > 1000);

    % Get 3 blocks of OFF session DLC coordinate data
    ttempdata{1} = tempdata(1:block(1), 2:3);
    ttempdata{2} = tempdata(block(1)+1:block(2), 2:3);
    ttempdata{3} = tempdata(block(2)+1:end, 2:3);
    
    % Iterate for each block of OFF session data
    for blockk = 1:3
        % Calculate velocity and distance for each block
        vecvel = diff(ttempdata{blockk});
        absvel = sqrt(sum(vecvel.^2, 2));
        svel = smoothdata(absvel);
        dist = sum(svel); meanvel = mean(svel); stdvel = std(svel);
        
        % Find peaks in the smoothed velocity data
        cutoff = meanvel + stdvel;
        [pks, locs] = findpeaks(svel);
        validpeaks = length(pks(pks > cutoff));
        
        % Store the results in totarray2
        totarray2(blockk, 1:3) = [dist meanvel validpeaks];
    end
    
    % Clear temporary variables
    tempdata = []; ttempdata = [];

    % ON data
    tempdata = totarray{session, 3};

    % Separate ON session data with time gaps
    tind = diff(tempdata(:, 1));
    block = find(tind > 1000);
    ttempdata{1} = tempdata(1:block(1), 2:3);
    ttempdata{2} = tempdata(block(1)+1:block(2), 2:3);
    ttempdata{3} = tempdata(block(2)+1:end, 2:3);
    
    % Iterate for each block of ON session data
    for blockk = 1:3
        % Calculate velocity and distance for each block
        vecvel = diff(ttempdata{blockk});
        absvel = sqrt(sum(vecvel.^2, 2));
        svel = smoothdata(absvel);
        dist = sum(svel); meanvel = mean(svel); stdvel = std(svel);
        
        % Find peaks in the smoothed velocity data
        cutoff = meanvel + stdvel;
        [pks, locs] = findpeaks(svel);
        validpeaks = length(pks(pks > cutoff));
        
        % Store the results in totarray2
        totarray2(blockk, 4:6) = [dist meanvel validpeaks];
    end
    
    totvdat(session, 1) = {totarray2};

    % Clear temporary variables
    tempdata = []; ttempdata = [];
    totarray2 = [];
end
