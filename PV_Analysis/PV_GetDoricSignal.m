%% PV_GetDoricSignal.m
% Get Doric signals from .doric files

% Copyright (C) 2024 Chanhee Jeong

% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.

% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.

%% PV YM Experiment List
% PV_3-1_24-05-17-11-39-29_YM
% PV_3-2_24-05-30-20-36-26_YM -> fail
% PV_3-4_24-05-17-11-52-21_YM
% PV_5-1_24-05-17-12-06-08_YM
% PV_5-2_24-05-13-16-58-46_YM

clear; close all;

directoryPath = "C:\Users\chanh\Downloads\PV_data\";
expName = "PV_3-4_24-05-17-11-52-21_YM";

% Count number of csv files in the directory
csvNum = length(dir(directoryPath + expName + "\*.csv"));

%% Get raw doric data from csv files and calculate GCaMP, RCaMP signals
if csvNum == 4 % If there are 4 extracted csv files (previous format)
    % GCaMP baseline signal
    doricData0 = table2array(readtable(directoryPath + expName + "\" + expName + "_0000.csv", "VariableNamingRule", "preserve"));
    % GCaMP observed signal
    doricData1 = table2array(readtable(directoryPath + expName + "\" + expName + "_0001.csv", "VariableNamingRule", "preserve"));
    % RCaMP baseline signal
    doricData2 = table2array(readtable(directoryPath + expName + "\" + expName + "_0002.csv", "VariableNamingRule", "preserve"));
    % RCaMP observed signal
    doricData3 = table2array(readtable(directoryPath + expName + "\" + expName + "_0003.csv", "VariableNamingRule", "preserve"));
    doricTime = doricData0(:, 1);
    doricGCaMP = doricData1(:, 2) - doricData0(:, 2);
    doricRCaMP = doricData3(:, 2) - doricData2(:, 2);
elseif csvNum == 3 % If there are 3 extracted csv files (recent format)
    % GCaMP and RCaMP baseline signal
    doricData0 = table2array(readtable(directoryPath + expName + "\" + expName + "_0000.csv", "VariableNamingRule", "preserve"));
    % GCaMP observed signal
    doricData1 = table2array(readtable(directoryPath + expName + "\" + expName + "_0001.csv", "VariableNamingRule", "preserve"));
    % RCaMP observed signal
    doricData2 = table2array(readtable(directoryPath + expName + "\" + expName + "_0002.csv", "VariableNamingRule", "preserve"));
    doricTime = doricData0(:, 3);
    doricGCaMP = doricData1(:, 1) - doricData0(:, 1);
    doricRCaMP = doricData2(:, 1) - doricData0(:, 2);
else % If there are no extracted csv files, raise an error
    msg = "There are no adequate csv files";
    error(msg);
end

%% Plot GCaMP, RCaMP signals
fig = figure;
hold on

plot(doricTime, doricGCaMP, Color='g');
plot(doricTime, doricRCaMP, Color='r');

title(expName, "Interpreter", "none")
subtitle("GCaMP, RCaMP signals")
xlabel("Doric time (s)")
ylabel("Signal intensity (AU)")

hold off

% fig1 = figure;
% hold on

% plot(doricTime, doricData2(:, 1) - doricData0(:, 1), Color='k');
% plot(doricTime, doricData1(:, 1) - doricData0(:, 2), Color='r');

%% Correct signal artifacts
windowSize = 300;
steepZCutoff = 2;
clusterSize = 60;
paddingSize = 20;

doricGCaMPC = PV_CorrectSignal(doricGCaMP, windowSize, steepZCutoff, clusterSize, paddingSize);
doricRCaMPC = PV_CorrectSignal(doricRCaMP, windowSize, steepZCutoff, clusterSize, paddingSize);

%% Plot GCaMPC, RCaMPC signals
figure
hold on

plot(doricTime, doricGCaMPC, Color='g');
plot(doricTime, doricRCaMPC, Color='r');

title(expName, "Interpreter", "none")
subtitle("GCaMPC, RCaMPC signals")
xlabel("Doric time (s)")
ylabel("Signal intensity (AU)")

hold off

%% Correct photobleaching
doricGCaMPCP = PV_MsacSignal(doricTime, doricGCaMPC, 200, 0.001);
doricRCaMPCP = PV_MsacSignal(doricTime, doricRCaMPC, 200, 0.001);

%% Plot GCaMPCP, RCaMPCP signals
% figure
% hold on

% plot(doricTime, doricGCaMPCP, Color='g');
% plot(doricTime, doricRCaMPCP, Color='r');

% title(expName, "Interpreter", "none")
% subtitle("GCaMPCP, RCaMPCP signals")
% xlabel("Doric time (s)")
% ylabel("Signal intensity (AU)")

% hold off

%% Trim first 10 sec of data and normalize data
doricTimeT = doricTime(doricTime > 10.0);
doricGCaMPCPT = normalize(doricGCaMPCP(doricTime > 10.0));
doricRCaMPCPT = normalize(doricRCaMPCP(doricTime > 10.0));

%% Plot GCaMPCPN, RCaMPCPN signals
figure
hold on

plot(doricTimeT, doricGCaMPCPT, Color='g');
plot(doricTimeT, doricRCaMPCPT, Color='r');

title(expName, "Interpreter", "none")
subtitle("GCaMPCPT, RCaMPCPT signals")
xlabel("Doric time (s)")
ylabel("Signal intensity (Z-score)")