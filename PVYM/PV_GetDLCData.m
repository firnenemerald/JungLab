%% PV_GetDLCData.m
% Get DLC data from DLC result .csv files

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

function [dlcFrame, dlcHead, dlcBody, dlcTail] = PV_GetDLCData(expName)

    dirPath = "C:\Users\chanh\Downloads\PV_data\";
    expPath = dirPath + expName + "\DLC";
    
    % Get the unique .csv file in the directory
    csvFiles = dir(fullfile(expPath, '*.csv'));
    if isempty(csvFiles)
        error('No .csv files found in the specified directory.');
    end
    CsvFile = csvFiles(1).name; % Assuming there's only one .csv file

    % Read data from the unique .csv file
    dlcData = table2array(readtable(fullfile(expPath, CsvFile), "VariableNamingRule", "preserve"));
    dlcFrame = dlcData(:, 1);
    dlcHead = dlcData(:, [2, 3]);
    dlcBody = dlcData(:, [5, 6]);
    dlcTail = dlcData(:, [8, 9]);

end