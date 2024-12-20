%% PV_SyncData.m
% Script to collect and synchronize data from DLC and video files

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
% PV_3-2_24-05-30-20-36-26_YM -> failed correction
% PV_3-4_24-05-17-11-52-21_YM
% PV_5-1_24-05-17-12-06-08_YM
% PV_5-2_24-05-13-16-58-46_YM

function [doricTime, doricGCaMP, doricRCaMP, dlcFrame, dlcHead, dlcBody, dlcTail, startFrame, endFrame] = PV_SyncData(expName)

cutFrame = 0;
syncFrame = 0;

switch expName
    case "PV_3-1_24-05-17-11-39-29_YM"
        cutFrame = 199;
        syncFrame = 20;
    case "PV_3-2_24-05-30-20-36-26_YM"
        cutFrame = 163;
        syncFrame = -8;
    case "PV_3-4_24-05-17-11-52-21_YM"
        cutFrame = 123;
        syncFrame = -1;
    case "PV_5-1_24-05-17-12-06-08_YM"
        cutFrame = 188;
        syncFrame = 53;
    case "PV_5-2_24-05-13-16-58-46_YM"
        cutFrame = 130;
        syncFrame = 40;
end

% Get flattened expName
expName_ = strrep(expName, '-', '_');

% Get doric data
doricData = load('PV_processed_results.mat');
doricTime = doricData.results.(expName_).Time;
doricGCaMP = doricData.results.(expName_).GCaMP;
doricRCaMP = doricData.results.(expName_).RCaMP;

% Trim doricTime
doricTime = doricTime(doricTime > 10.0);

% Get DLC data
[dlcFrame, dlcHead, dlcBody, dlcTail] = PV_GetDLCData(expName);

% Trim starting part of DLC (doric signal is cut until t = 10.0sec)
startFrame = 300 - (cutFrame - syncFrame);
frameMask = dlcFrame > startFrame - 1;
dlcFrame = dlcFrame(frameMask);
dlcHead = dlcHead(frameMask, :);
dlcBody = dlcBody(frameMask, :);
dlcTail = dlcTail(frameMask, :);

endFrame = dlcFrame(end);

% Trim ending part of DLC or doric
if size(doricTime, 1) > size(dlcFrame, 1) * 2 % Trim doric if doric is longer
    disp("doric is longer... trimming end of doric")
    doricTime = doricTime(1:size(dlcFrame, 1) * 2);
    doricGCaMP = doricGCaMP(1:size(dlcFrame, 1) * 2);
    doricRCaMP = doricRCaMP(1:size(dlcFrame, 1) * 2);
elseif size(doricTime, 1) < size(dlcFrame, 1) * 2 % Trim dlc if dlc is longer
    disp("DLC is longer... trimming end of DLC")
    if rem(size(doricTime, 1), 2) == 0
        dlcFrame = dlcFrame(1:size(doricTime, 1)/2);
        dlcHead = dlcHead(1:size(doricTime, 1)/2, :);
        dlcBody = dlcBody(1:size(doricTime, 1)/2, :);
        dlcTail = dlcTail(1:size(doricTime, 1)/2, :);
        endFrame = startFrame + size(dlcFrame, 1);
    else
        doricTime = doricTime(1:end-1);
        doricGCaMP = doricGCaMP(1:end-1);
        doricRCaMP = doricRCaMP(1:end-1);
        dlcFrame = dlcFrame(1:size(doricTime, 1)/2);
        dlcHead = dlcHead(1:size(doricTime, 1)/2, :);
        dlcBody = dlcBody(1:size(doricTime, 1)/2, :);
        dlcTail = dlcTail(1:size(doricTime, 1)/2, :);
        endFrame = startFrame + size(dlcFrame, 1);
    end
end