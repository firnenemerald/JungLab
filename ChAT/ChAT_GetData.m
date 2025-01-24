%% ChAT_GetData.m (ver 1.0.240918)
% Video, Inscopix, Deeplabcut data importing and processing
% Processed data loading

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

%% Data spec
% ChAT_514-2-3_24-02-05-16-42-21_OF
% ChAT_514-2-4_24-01-29-16-04-16_OF
% ChAT_853-3_24-04-15-15-24-32_OF
% ChAT_853-1_24-04-18-15-24-09_OF
% ChAT_515-1_24-02-06-13-37-15_OF (B)
% ChAT_515-1_24-04-08-15-45-00_OF (P)

%% Import raw data
baseDir = 'C:\\Users\\chanh\\Downloads\\chat_data';
expName = 'ChAT_515-1_24-04-08-15-45-00_OF';
expDir = strcat(baseDir, '\\', expName);

% Inscopix PCAICA, PCAICA-props
cellCsvDir = fullfile(expDir, strcat(expName, '_PCAICA.csv'));
cellArray = table2array(readtable(cellCsvDir, "VariableNamingRule", "preserve"));
metaCsvDir = fullfile(expDir, strcat(expName, '_PCAICA-props.csv'));
metaTable = readtable(metaCsvDir, "VariableNamingRule", "preserve");
cellArray = cellArray(:, [1; find(string(metaTable.Status) == 'accepted') + 1]');

% Inscopix GPIO
gpioCsvDir = fullfile(expDir, strcat(expName, '_GPIO.csv'));
gpioTable = readtable(gpioCsvDir, "VariableNamingRule", "preserve");
gpioTable = gpioTable(string(gpioTable.("Channel Name")) == 'GPIO-1', [1, 3]);
gpioArray = table2array(gpioTable);

% DeepLabCut .csv
dlcCsvDir = fullfile(expDir, strcat(expName, 'DLC_resnet50*.csv'));
dlcCsvList = dir(dlcCsvDir);
dlcCsvPath = fullfile(expDir, dlcCsvList(1).name);
dlcArray = table2array(readtable(dlcCsvPath, "VariableNamingRule", "preserve"));

% DeepLabCut .mp4
dlcMp4Dir = fullfile(expDir, strcat(expName, 'DLC_resnet50*.mp4'));
dlcMp4List = dir(dlcMp4Dir);
dlcMP4Path = fullfile(expDir, dlcMp4List(1).name);
dlcVideo = VideoReader(dlcMP4Path);

%% startFrame, endFrame, syncFrame info
switch expName
    case 'ChAT_515-1_24-02-06-13-37-15_OF'
        syncFrame = 185;
        startFrame = 300;
        endFrame = 18000;
    case 'ChAT_515-1_24-04-08-15-45-00_OF'
        syncFrame = 681;
        startFrame = 300;
        endFrame = 18000;
end

%% Synchronize data
INSCOPIXDPS = 20.015322894;
LOGITECHFPS = 29.99;
cellNum = size(cellArray, 2) - 1;
syncTime = GetSyncTime(gpioArray);

startTime = syncTime + (startFrame - syncFrame) / LOGITECHFPS;
startIndex = find(cellArray(:,1) > startTime, 1);
endTime = syncTime + (endFrame - syncFrame) / LOGITECHFPS;
if (cellArray(end, 1) < endTime)
    fprintf("Inscopix is shorter than video.\n")
    endIndex = length(cellArray(:, 1));
    endTime = cellArray(end, 1);
    endFrame = syncFrame + (endTime - syncTime) * LOGITECHFPS;
else
    fprintf("Video is shorter than Inscopix.\n")
    endIndex = find(cellArray(:, 1) > endTime, 1);
end

dlcArray = dlcArray(startFrame:endFrame, :);
dlcArrayCenter = dlcArray(:, [1, 5, 6]);

dlcWidth = dlcVideo.Width;
dlcHeight = dlcVideo.Height;

fig = figure;
xlim([400 800])
ylim([100 500])
hold on
index = size(dlcArrayCenter, 1);
for frame = 1:index-30
    if (mod(frame, 30) == 0)
        vertex1 = [dlcArrayCenter(frame, 2), dlcArrayCenter(frame, 3)];
        vertex2 = [dlcArrayCenter(frame+30, 2), dlcArrayCenter(frame+30, 3)];
        plot([vertex1(1); vertex2(1)], [vertex1(2); vertex2(2)], 'k');
    end
end
pbaspect([1 1 1]);
hold off

%% Display and save example cell signal
% ChAT_PlotSignal(expDir, expName, cellArray, 101, 200, true)

%% Display center position every 30 frames (1s)




