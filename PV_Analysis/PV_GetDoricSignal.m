%% PV_GetDoricSignal.m
% Get Doric signal from .doric file

% Copyright (C) 2024 Chanhee Jeong

clear; close all;

filePath = "C:\Users\chanh\Downloads\Doric\";
fileName = "PV_20-1_24-09-26-13-43-07_OF";

% Read .doric file
doricData1 = table2array(readtable(filePath + fileName + "_0000.csv", "VariableNamingRule", "preserve"));
doricData2 = table2array(readtable(filePath + fileName + "_0001.csv", "VariableNamingRule", "preserve"));
doricData3 = table2array(readtable(filePath + fileName + "_0002.csv", "VariableNamingRule", "preserve"));
doricTime = doricData1(:, 3);

fig = figure;
hold on

% Plot raw data
%plot(doricTime, doricData1(:, 1), Color='b');
%plot(doricTime, doricData1(:, 2), Color='m');
%plot(doricTime, doricData2(:, 1), Color='r');
%plot(doricTime, doricData3(:, 1), Color='k');

% Plot difference between channels
plot(doricTime, doricData3(:, 1) - doricData1(:, 1), Color='k');
plot(doricTime, doricData2(:, 1) - doricData1(:, 2), Color='r');
