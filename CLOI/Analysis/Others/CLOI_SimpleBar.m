% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

% Clear the workspace
clear
close all

% Specify default directory and session name
defaultDir = "D:\CLOI_data";
fileName = "CLOI_Statistics.xlsx";

% Load the data
data = readtable(fullfile(defaultDir, fileName));

% Extract the relevant columns
MS2_ON = data.MS2_ON;
MS4_ON = data.MS4_ON;
MS6_ON = data.MS6_ON;
MS1_Dist = data.MS1_Dist;
MS2_Dist = data.MS2_Dist;
MS3_Dist = data.MS3_Dist;
MS4_Dist = data.MS4_Dist;
MS5_Dist = data.MS5_Dist;
MS6_Dist = data.MS6_Dist;

%% Optogenetic stimulation OFF vs ON

% ChAT_947-2 Baseline
Dist_9472_B_OFF = [MS1_Dist(1:6, :); MS3_Dist(1:6, :); MS5_Dist(1:6, :)];
Dist_9472_B_ON = [MS2_Dist(1:6, :); MS4_Dist(1:6, :); MS6_Dist(1:6, :)];

% ChAT_947-2 Parkinson
Dist_9472_P_OFF = [MS1_Dist(7:12, :); MS3_Dist(7:12, :); MS5_Dist(7:12, :)];
Dist_9472_P_ON = [MS2_Dist(7:12, :); MS4_Dist(7:12, :); MS6_Dist(7:12, :)];

% ChAT_947-2 Total
Dist_9472_T_OFF = [MS1_Dist(1:12, :); MS3_Dist(1:12, :); MS5_Dist(1:12, :)];
Dist_9472_T_ON = [MS2_Dist(1:12, :); MS4_Dist(1:12, :); MS6_Dist(1:12, :)];

% ChAT_947-3 Baseline
Dist_9473_B_OFF = [MS1_Dist(13:18, :); MS3_Dist(13:18, :); MS5_Dist(13:18, :)];
Dist_9473_B_ON = [MS2_Dist(13:18, :); MS4_Dist(13:18, :); MS6_Dist(13:18, :)];

% ChAT_947-3 Parkinson
Dist_9473_P_OFF = [MS1_Dist(19:24, :); MS3_Dist(19:24, :); MS5_Dist(19:24, :)];
Dist_9473_P_ON = [MS2_Dist(19:24, :); MS4_Dist(19:24, :); MS6_Dist(19:24, :)];

% ChAT_947-3 Total
Dist_9473_T_OFF = [MS1_Dist(13:24, :); MS3_Dist(13:24, :); MS5_Dist(13:24, :)];
Dist_9473_T_ON = [MS2_Dist(13:24, :); MS4_Dist(13:24, :); MS6_Dist(13:24, :)];

% ChAT_947-3 Selected
Dist_9473_S_OFF = [MS1_Dist(19:21, :); MS3_Dist(19:21, :); MS5_Dist(19:21, :)];
Dist_9473_S_ON = [MS2_Dist(19:21, :); MS4_Dist(19:21, :); MS6_Dist(19:21, :)];

% Plot box graphs
% PlotCustomBar(Dist_9472_B_OFF, Dist_9472_B_ON, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-2 Baseline OFF vs ON', 'Group1', 'OFF', 'Group2', 'ON');
% PlotCustomBar(Dist_9472_P_OFF, Dist_9472_P_ON, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-2 Parkinson OFF vs ON', 'Group1', 'OFF', 'Group2', 'ON');
% PlotCustomBar(Dist_9472_T_OFF, Dist_9472_T_ON, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-2 Total OFF vs ON', 'Group1', 'OFF', 'Group2', 'ON');

% PlotCustomBar(Dist_9473_B_OFF, Dist_9473_B_ON, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-3 Baseline OFF vs ON', 'Group1', 'OFF', 'Group2', 'ON');
% PlotCustomBar(Dist_9473_P_OFF, Dist_9473_P_ON, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-3 Parkinson OFF vs ON', 'Group1', 'OFF', 'Group2', 'ON');
% PlotCustomBar(Dist_9473_T_OFF, Dist_9473_T_ON, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-3 Total OFF vs ON', 'Group1', 'OFF', 'Group2', 'ON');
% PlotCustomBar(Dist_9473_S_OFF, Dist_9473_S_ON, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-3 Selected OFF vs ON', 'Group1', 'OFF', 'Group2', 'ON');

%% Closed loop optogenetic stimulation vs Random optogenetic stimulation

% ChAT_947-2 Baseline
Dist_9472_B_CL = [MS2_Dist([1, 3, 5], :); MS4_Dist([1, 3, 5], :); MS6_Dist([1, 3, 5], :)];
Dist_9472_B_R = [MS2_Dist([2, 4, 6], :); MS4_Dist([2, 4, 6], :); MS6_Dist([2, 4, 6], :)];

% ChAT_947-2 Parkinson
Dist_9472_P_CL = [MS2_Dist([7, 9, 11], :); MS4_Dist([7, 9, 11], :); MS6_Dist([7, 9, 11], :)];
Dist_9472_P_R = [MS2_Dist([8, 10, 12], :); MS4_Dist([8, 10, 12], :); MS6_Dist([8, 10, 12], :)];

% ChAT_947-2 Total
Dist_9472_T_CL = [MS2_Dist([1, 3, 5, 7, 9, 11], :); MS4_Dist([1, 3, 5, 7, 9, 11], :); MS6_Dist([1, 3, 5, 7, 9, 11], :)];
Dist_9472_T_R = [MS2_Dist([2, 4, 6, 8, 10, 12], :); MS4_Dist([2, 4, 6, 8, 10, 12], :); MS6_Dist([2, 4, 6, 8, 10, 12], :)];

% ChAT_947-3 Baseline
Dist_9473_B_CL = [MS2_Dist([13, 15, 17], :); MS4_Dist([13, 15, 17], :); MS6_Dist([13, 15, 17], :)];
Dist_9473_B_R = [MS2_Dist([14, 16, 18], :); MS4_Dist([14, 16, 18], :); MS6_Dist([14, 16, 18], :)];

% ChAT_947-3 Parkinson
Dist_9473_P_CL = [MS2_Dist([19, 21, 23], :); MS4_Dist([19, 21, 23], :); MS6_Dist([19, 21, 23], :)];
Dist_9473_P_R = [MS2_Dist([20, 22, 24], :); MS4_Dist([20, 22, 24], :); MS6_Dist([20, 22, 24], :)];

% ChAT_947-3 Total
Dist_9473_T_CL = [MS2_Dist([13, 15, 17, 19, 21, 23], :); MS4_Dist([13, 15, 17, 19, 21, 23], :); MS6_Dist([13, 15, 17, 19, 21, 23], :)];
Dist_9473_T_R = [MS2_Dist([14, 16, 18, 20, 22, 24], :); MS4_Dist([14, 16, 18, 20, 22, 24], :); MS6_Dist([14, 16, 18, 20, 22, 24], :)];

% Plot box graphs
% PlotCustomBar(Dist_9472_B_CL, Dist_9472_B_R, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-2 Baseline CL vs R', 'Group1', 'CL', 'Group2', 'R');
% PlotCustomBar(Dist_9472_P_CL, Dist_9472_P_R, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-2 Parkinson CL vs R', 'Group1', 'CL', 'Group2', 'R');
% PlotCustomBar(Dist_9472_T_CL, Dist_9472_T_R, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-2 Total CL vs R', 'Group1', 'CL', 'Group2', 'R');

% PlotCustomBar(Dist_9473_B_CL, Dist_9473_B_R, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-3 Baseline CL vs R', 'Group1', 'CL', 'Group2', 'R');
% PlotCustomBar(Dist_9473_P_CL, Dist_9473_P_R, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-3 Parkinson CL vs R', 'Group1', 'CL', 'Group2', 'R');
% PlotCustomBar(Dist_9473_T_CL, Dist_9473_T_R, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Distance (px)', 'Title', 'ChAT_947-3 Total CL vs R', 'Group1', 'CL', 'Group2', 'R');

%% Baseline vs Parkinson Closed Loop Optogenetic Stimulation

% ChAT_947-2
N_9472_B = [MS2_ON([1, 3, 5], :); MS4_ON([1, 3, 5], :); MS6_ON([1, 3, 5], :)];
N_9472_P = [MS2_ON([7, 9, 11], :); MS4_ON([7, 9, 11], :); MS6_ON([7, 9, 11], :)];

% ChAT_947-3
N_9473_B = [MS2_ON([13, 15, 17], :); MS4_ON([13, 15, 17], :); MS6_ON([13, 15, 17], :)];
N_9473_P = [MS2_ON([19, 21, 23], :); MS4_ON([19, 21, 23], :); MS6_ON([19, 21, 23], :)];

% Plot box graphs
% PlotCustomBar(N_9472_B, N_9472_P, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Number of Stimulation', 'Title', 'ChAT_947-2 Baseline vs Parkinson', 'Group1', 'Baseline', 'Group2', 'Parkinson');
PlotCustomBar(N_9473_B, N_9473_P, 'XLabel', 'Optogenetic Stimulation', 'YLabel', 'Number of Stimulation', 'Title', 'ChAT_947-3 Baseline vs Parkinson', 'Group1', 'Baseline', 'Group2', 'Parkinson');