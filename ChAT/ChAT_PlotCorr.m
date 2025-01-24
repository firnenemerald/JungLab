%% ChAT_PlotCorr.m (ver 1.0.241014)
% Plot correlation between ChAT scores and retinal parameters

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

% Import Inscopix PCAICA and PCAICA-props data
cellArray = table2array(readtable("C:\Users\chanh\Downloads\ChAT_514-2-4_24-01-29-16-04-16_OF_PCAICA.csv", "VariableNamingRule", "preserve"));
metaTable = readtable("C:\Users\chanh\Downloads\ChAT_514-2-4_24-01-29-16-04-16_OF_PCAICA-props.csv", "VariableNamingRule", "preserve");
cellArray = cellArray(:, [1; find(string(metaTable.Status) == 'accepted') + 1]');

cellNum = size(cellArray, 2) - 1;
xCoor = metaTable.CentroidX(string(metaTable.Status) == 'accepted');
yCoor = metaTable.CentroidY(string(metaTable.Status) == 'accepted');

corrMat = zeros(cellNum, cellNum);
for i = 1:cellNum
    for j = i+1:cellNum
        corrcoefMat = corrcoef(cellArray(:, i+1), cellArray(:, j+1));
        corrMat(i, j) = corrcoefMat(1, 2);
    end
end

corrMat = corrMat;

% Create jet colormap
numColors = 256;
jetMap = jet(numColors);

% Get min and max correlation values
minCorr = min(corrMat(:));
maxCorr = max(corrMat(:));

figure
set(gca, 'YDir','reverse')
hold on

% Plot segments
for i = 1:cellNum
    for j = i+1:cellNum
        x = [xCoor(i), xCoor(j)];
        y = [yCoor(i), yCoor(j)];
        % Normalize correlation value to [0, 1] range
        normCorr = (corrMat(i,j) - minCorr) / (maxCorr - minCorr);
        colorIndex = round(normCorr * (numColors-1)) + 1;
        line(x, y, 'Color', jetMap(colorIndex,:), 'LineWidth', 1);
    end
end

% Plot scatter points on top
scatter(xCoor, yCoor, 50, 'filled', 'MarkerFaceColor', 'k')

colormap(jet)
c = colorbar;
c.Label.String = 'Correlation';
% Set colorbar limits to match the actual correlation range
caxis([minCorr, maxCorr])

title('Cell Correlation Network')
xlabel('X Coordinate')
ylabel('Y Coordinate')

hold off
