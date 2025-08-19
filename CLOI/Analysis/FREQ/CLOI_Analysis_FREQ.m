%% CLOI (Closed-Loop Optogenetic Inhibition) - FREQ Analysis

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

% Frequent sessions
% Protocol: 1 min laser OFF, 1 min laser ON x 10
% Designed to assess the cumulative effects of repeated CLOI

clear; close all;

minisessionDuration = 60;
minisessionNum = 10;
baseDir = "H:\FREQ";

%% Load data using CLOI_LoadData_FREQ function
[sessionData, analysisData, miniAnalysisData] = CLOI_LoadData_FREQ(baseDir, minisessionDuration, minisessionNum);

%% Plot velocity peaks for ChAT_946-2 baseline sessions using the generalized function
%CLOI_PlotSessionData(miniAnalysisData, 'ChAT_946-2', 'Baseline', 'totalDistance');

%% Plot total distance for all mice during both types of sessions
CLOI_PlotCollectiveData(miniAnalysisData, 'ALL', 'BOTH', 'totalDistance');