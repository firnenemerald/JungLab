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
baseDir = './data';
videoDir = 'C:/Users/chanh/Downloads/ChAT_video';
MOUSENAME = 'ChAT_514-2-3';
MOUSESTATUS = 'B';

% cellSignalPark = GetCellSignal(MOUSENAME, MOUSESTATUS, baseDir);
% [cellNamesPaired, signalPairedBase, signalPairedPark] = GetPairSignals(MOUSENAME, baseDir);

% syncTimePark = GetSyncTime(MOUSENAME, MOUSESTATUS, baseDir);
% ReviewSyncTime(baseDir);

% GetAllMouseMeta(baseDir, true);

% dlcCenter = GetDLCCoord(MOUSENAME, MOUSESTATUS, 'center', baseDir);

reviewedVideo = ReviewRawVideo(MOUSENAME, MOUSESTATUS, videoDir, false)

%ReviewSyncFrame(baseDir, videoDir);

% {'ChAT_514-2-3'}    {'B'}    {[179]}    {[1251]}
% {'ChAT_853-1'}    {'B'}    {[148]}    {[294]}
% {'ChAT_853-3'}    {'P'}    {[237]}    {[758]}
% {'ChAT_853-3'}    {'B'}    {[145]}    {[236]}
% {'PV_15-4'}    {'B'}    {[226]}    {[166]}
% {'PV_15-4'}    {'P'}    {[152]}    {[632]}