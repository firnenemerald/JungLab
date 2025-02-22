%% Main script for CLOI OF analysis
% This script is the main script for the analysis of CLOI OF data.

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

% Clear the workspace
clear
close all

% Load the data
dlcArray = CLOI_GetDLC('ChAT_947-3', 'Baseline', 'CLOI', '250109_145438', 'head', 'C:\Users\chanh\Downloads\ChAT_947-3');
dlcFrameNum = size(dlcArray, 1);
[mvArrayTime, mvArrayState] = CLOI_GetMv('ChAT_947-3', 'Baseline', 'CLOI', '250109_145438', 'C:\Users\chanh\Downloads\ChAT_947-3');

plot(mvArrayTime, mvArrayState, 'b-')