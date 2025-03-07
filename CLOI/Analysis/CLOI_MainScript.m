%% Main script for CLOI OF analysis
% This script is the main script for the analysis of CLOI OF data.

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

% Clear the workspace
clear
close all

% Specify default directory and session name
defaultDir = "D:\CLOI_data";
sessionName = "ChAT_947-3_Parkinson_CLOI_250217_162220";

% Deconstruct mouse data from session name
splitParts = split(sessionName, "_");
mouseName = splitParts{1} + "_" + splitParts{2};
mouseStatus = splitParts{3} + "";
expType = splitParts{4} + "";
dateTime = splitParts{5} + "_" + splitParts{6};

% Load and plot DLC data
dlcArray = CLOI_GetDLC(mouseName, mouseStatus, expType, dateTime, "head", defaultDir);
% CLOI_PlotDLC(mouseName, mouseStatus, expType, dateTime, "head", defaultDir);

% Load movement data
[mvArrayTime, mvArrayState] = CLOI_GetMv(mouseName, mouseStatus, expType, dateTime, defaultDir);

% Get minisession OFF/ON frames
msOFFframebool = (mvArrayTime > 10.0 & mvArrayTime < 120.0) | (mvArrayTime > 240.0 & mvArrayTime < 360.0) | (mvArrayTime > 480.0 & mvArrayTime < 600.0);
msONframebool = (mvArrayTime > 120.0 & mvArrayTime < 240.0) | (mvArrayTime > 360.0 & mvArrayTime < 480.0) | (mvArrayTime > 600.0 & mvArrayTime < 720.0);

% Plot minisession OFF/ON DLC data
% CLOI_PlotDLC(mouseName, mouseStatus, expType, dateTime, "head", defaultDir, msOFFframebool);
% CLOI_PlotDLC(mouseName, mouseStatus, expType, dateTime, "head", defaultDir, msONframebool);
CLOI_PlotDLC(mouseName, mouseStatus, expType, dateTime, "head", defaultDir, msOFFframebool, msONframebool);

% Convert mvArrayState to numerical values for plotting
% stateNumeric = zeros(size(mvArrayState));
% stateNumeric(strcmp(mvArrayState, 'Move')) = 1;
% stateNumeric(strcmp(mvArrayState, 'Stop')) = 0;

% % Plot state vs time
% figure;
% plot(mvArrayTime, stateNumeric, 'o-');
% xlabel('Time');
% ylabel('State');
% title('State vs Time');
% grid on;