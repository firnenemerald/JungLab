%% Main script for CLOI OF analysis
% This script is the main script for the analysis of CLOI OF data.

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

% Clear the workspace
clear
close all

% Specify default directory and session name
defaultDir = "D:\CLOI_data";
sessionNames = ["ChAT_947-3_Baseline_CLOI_250109_145438", ...
                "ChAT_947-3_Baseline_CLOI_250113_164620", ...
                "ChAT_947-3_Baseline_CLOI_250115_121328", ...
                "ChAT_947-3_Baseline_Random_250110_133139", ...
                "ChAT_947-3_Baseline_Random_250114_151132", ...
                "ChAT_947-3_Baseline_Random_250116_111052", ...
                "ChAT_947-3_Parkinson_CLOI_250213_164005", ...
                "ChAT_947-3_Parkinson_CLOI_250217_162220", ...
                "ChAT_947-3_Parkinson_CLOI_250221_140140", ...
                "ChAT_947-3_Parkinson_Random_250214_144329", ...
                "ChAT_947-3_Parkinson_Random_250220_133147", ...
                "ChAT_947-3_Parkinson_Random_250224_154946"];

% Loop over session names
for i = 1:length(sessionNames)
    sessionName = sessionNames(i);
    CLOI_AnalyzeSession(sessionName, defaultDir);
end

% Function to analyze a single session
function CLOI_AnalyzeSession(sessionName, defaultDir)
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
end
