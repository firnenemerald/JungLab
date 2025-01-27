%% Main script for ChAT OF analysis
% This script is the main script for the analysis of ChAT OF data.

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

%% Data summary
% Level 3: ChAT_514-2-3 (2), ChAT_515-1 (2), ChAT_925-2 (2), ChAT_925-3 (2)
% Level 2: ChAT_514-2-4 (x), ChAT_853-1 (21, P_gpio x), ChAT_853-3 (7), PV_15-4 (x)

% Clear the workspace
clear
close all

% Load the data
MOUSENAME = 'ChAT_853-3';

[cellNamesPaired, signalArrayBase, signalArrayPark] = GetPairSignals(MOUSENAME);
%syncTimeBase = GetSyncTime(MOUSENAME, 'B');
%syncTimePark = GetSyncTime(MOUSENAME, 'P');

GetSyncTime('PV_15-4', 'B');