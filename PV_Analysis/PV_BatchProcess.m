%% PV_BatchProcess.m
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
% PV_3-2_24-05-30-20-36-26_YM -> failed correction
% PV_3-4_24-05-17-11-52-21_YM
% PV_5-1_24-05-17-12-06-08_YM
% PV_5-2_24-05-13-16-58-46_YM

clearvars
close all

% Define experiment names to process
expNames = {...
    'PV_3-1_24-05-17-11-39-29_YM',...
    'PV_3-2_24-05-30-20-36-26_YM',...
    'PV_3-4_24-05-17-11-52-21_YM',...
    'PV_5-1_24-05-17-12-06-08_YM',...
    'PV_5-2_24-05-13-16-58-46_YM'
    };

% Initialize structure to store results
results = struct();

% Process each experiment
for i = 1:length(expNames)
    expName = expNames{i};
    disp(['Processing ' expName '...']);
    
    try
        % Run your signal processing and capture only normalized outputs
        [doricTime, doricGCaMPCPTN, doricRCaMPCPTN] = PV_GetDoricSignal(expName);
        
        % Replace hyphens with underscores for valid field names
        validFieldName = strrep(expName, '-', '_');
        
        % Store results in structure
        results.(validFieldName).Time = doricTime;
        results.(validFieldName).GCaMP = doricGCaMPCPTN;
        results.(validFieldName).RCaMP = doricRCaMPCPTN;
        
        disp(['Successfully processed ' expName]);
    catch ME
        warning(['Error processing ' expName ': ' ME.message]);
        continue;
    end
end

% Save results
save('C:/Users/chanh/OneDrive/문서/__My Documents__/JungLab/PV_Analysis/PV_processed_results.mat', 'results', 'expNames');
disp('All processing complete. Results saved to PV_processed_results.mat');