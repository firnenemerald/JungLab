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

clear; close all;

directoryPath = "C:\Users\chanh\Downloads\Doric\";
expName = "PV_20-1_24-09-26-13-43-07_OF";

csvForm = 0;
switch expName
    case "PV_1-5_24-02-08-16-50-14_YM"
        csvForm = 4;
    case "PV_20-1_24-09-26-13-43-07_OF"
        csvForm = 3;
end


if csvForm == 4 % If there are 4 extracted csv files (previous format)
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
elseif csvForm == 3 % If there are 3 extracted csv files (recent format)
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

fig = figure;
hold on

plot(doricTime, doricGCaMP, Color='g');
plot(doricTime, doricRCaMP, Color='r');

% Plot raw data

% Plot difference between channels
%plot(doricTime, doricData3(:, 1) - doricData1(:, 1), Color='k');
%plot(doricTime, doricData2(:, 1) - doricData1(:, 2), Color='r');
