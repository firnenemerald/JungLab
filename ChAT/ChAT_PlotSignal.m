%% ChAT_PlotSignal.m (ver 1.0.240918)
% Helper function to get experiment session's details
% Input is experiment session's name
% Output is mouse name (name) OR session timestamp (time) OR experiment type (type)

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

function [] = ChAT_PlotSignal(expDir, expName, cellArray, cropIndexStart, cropIndexDuration, saveFlag)

cellNum = size(cellArray, 2) - 1;

cellArrayCrop = cellArray(cropIndexStart:cropIndexStart+cropIndexDuration, :);
maxCellValue = max(cellArrayCrop(:, 2:end), [], 'all');
minCellValue = min(cellArrayCrop(:, 2:end), [], 'all');
ylimitValue = ceil(max(maxCellValue, -minCellValue)/5000)*5000;

% Plot axis off figure
figCellSignal = figure('position', [0, 0, 600, 800]);
hold on
for idx = 1:cellNum
    subplot(cellNum, 1, idx)
    hold on
    plot(cellArrayCrop(:, 1), cellArrayCrop(:, idx+1))
    ylim([-ylimitValue, ylimitValue]);
    axis off
    % Add scale bar
    scalebarX = (cropIndexStart + cropIndexDuration*0.8)/20.0;
    scalebarY = 50000;
    plot([scalebarX, scalebarX, scalebarX + 1.0], [scalebarY, 0, 0], 'k-', 'Linewidth', 2);
    hold off
end
% Optionally save figure as .eps file
if saveFlag == true
    saveas(figCellSignal, strcat(expDir, '\\', GetExpDetail(expName, 'name'), '_cell'), 'eps');
end
hold off

% Plot axis on figure
figCellSignalAxis = figure('position', [600, 0, 600, 800]);
hold on
sgtitle([expName, ' / ', strcat('signalmax = ', int2str(ylimitValue))], 'Interpreter', 'none', 'FontSize', 10);
for idx = 1:cellNum
    subplot(cellNum, 1, idx)
    hold on
    plot(cellArrayCrop(:, 1), cellArrayCrop(:, idx+1))
    ylim([-ylimitValue, ylimitValue]);
    hold off
end
% Optionally save figure as .png file
if saveFlag == true
    saveas(figCellSignalAxis, strcat(expDir, '\\', GetExpDetail(expName, 'name'), '_cell_axis'), 'png');
end
hold off

end