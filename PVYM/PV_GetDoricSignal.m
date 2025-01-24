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

function [doricTime, doricGCaMPCPTN, doricRCaMPCPTN] = PV_GetDoricSignal(expName)

dirPath = "C:\Users\chanh\Downloads\PV_data\";
expPath = dirPath + expName;

% Count number of csv files in the directory
csvNum = length(dir(dirPath + expName + "\*.csv"));

%% Get raw doric data from csv files and calculate GCaMP, RCaMP signals
if csvNum == 4 % If there are 4 extracted csv files (previous format)
    doricData0 = table2array(readtable(expPath + "\" + expName + "_0000.csv", "VariableNamingRule", "preserve")); % GCaMP baseline signal
    doricData1 = table2array(readtable(expPath + "\" + expName + "_0001.csv", "VariableNamingRule", "preserve")); % GCaMP observed signal
    doricData2 = table2array(readtable(expPath + "\" + expName + "_0002.csv", "VariableNamingRule", "preserve")); % RCaMP baseline signal
    doricData3 = table2array(readtable(expPath + "\" + expName + "_0003.csv", "VariableNamingRule", "preserve")); % RCaMP observed signal
    doricTime = doricData0(:, 1);
    doricGCaMP = doricData1(:, 2) - doricData0(:, 2);
    doricRCaMP = doricData3(:, 2) - doricData2(:, 2);
elseif csvNum == 3 % If there are 3 extracted csv files (recent format)
    doricData0 = table2array(readtable(expPath + "\" + expName + "_0000.csv", "VariableNamingRule", "preserve")); % GCaMP and RCaMP baseline signal
    doricData1 = table2array(readtable(expPath + "\" + expName + "_0001.csv", "VariableNamingRule", "preserve")); % GCaMP observed signal
    doricData2 = table2array(readtable(expPath + "\" + expName + "_0002.csv", "VariableNamingRule", "preserve")); % RCaMP observed signal
    doricTime = doricData0(:, 3);
    doricGCaMP = doricData1(:, 1) - doricData0(:, 1);
    doricRCaMP = doricData2(:, 1) - doricData0(:, 2);
else % If there are no extracted csv files, raise an error
    msg = "There are no adequate csv files";
    error(msg);
end

%% Plot Raw GCaMP, RCaMP signals
fig = figure;
hold on

plot(doricTime, doricGCaMP, Color='g');
plot(doricTime, doricRCaMP, Color='r');

title(expName, "Interpreter", "none")
subtitle("(Raw) GCaMP, RCaMP signals")
xlabel("Doric time (s)")
ylabel("Signal intensity (AU)")

hold off

%% Correct signal artifacts
% windowSize = 300;
% steepZCutoff = 2;
% clusterSize = 60;
% paddingSize = 20;

% doricGCaMPC = PV_CorrectAutomatic(doricGCaMP, windowSize, steepZCutoff, clusterSize, paddingSize);
% doricRCaMPC = PV_CorrectAutomatic(doricRCaMP, windowSize, steepZCutoff, clusterSize, paddingSize);

doricGCaMPC = PV_CorrectManual(doricGCaMP);
doricRCaMPC = PV_CorrectManual(doricRCaMP);

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
doricGCaMPCP = PV_MsacSignal(doricTime, doricGCaMPC, 200, 0.0012);
doricRCaMPCP = PV_MsacSignal(doricTime, doricRCaMPC, 200, 0.0012);

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
doricGCaMPCPT = doricGCaMPCP(doricTime > 10.0);
doricRCaMPCPT = doricRCaMPCP(doricTime > 10.0);
doricGCaMPCPTN = normalize(doricGCaMPCPT);
doricRCaMPCPTN = normalize(doricRCaMPCPT);

%% Plot GCaMPCPTN, RCaMPCPTN signals
figure
hold on

plot(doricTimeT, doricGCaMPCPTN, Color='g');
plot(doricTimeT, doricRCaMPCPTN, Color='r');

title(expName, "Interpreter", "none")
subtitle("GCaMPCPTN, RCaMPCPTN signals")
xlabel("Doric time (s)")
ylabel("Signal intensity (Z-score)")

hold off

end