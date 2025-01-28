%% Function to get syncTime of specified mouse and status
% Returns syncTime (double)

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function syncTime = GetSyncTime(mouseName, mouseStatus, baseDirectory)

    % Set default base directory
    baseDir = baseDirectory;
    
    % Search for the last synctime_reviewed_*.csv files
    reviewedSyncTimeDirs = dir(fullfile(baseDir, 'synctime_reviewed_*.csv'));

    % If no prior reviewed synctime files found, raise an error
    if isempty(reviewedSyncTimeDirs)
        error('No prior reviewed synctime files found... Please review the data first');
    end

    % Else, get the syncTime from the last reviewed synctime file
    syncTime = GetSyncTimeFromReviewed(mouseName, mouseStatus, reviewedSyncTimeDirs);
end

%% Helper function to actually get syncTime if there is a reviewed synctime file
function syncTime = GetSyncTimeFromReviewed(mouseName, mouseStatus, reviewedSyncTimeDirs)

    % Get the last reviewed synctime file
    reviewedSyncTimeLast = fullfile(reviewedSyncTimeDirs(end).folder, reviewedSyncTimeDirs(end).name);
    disp(['Last reviewed synctime file found: ' reviewedSyncTimeLast]);

    % Read the last reviewed synctime file
    reviewedSyncTime = readtable(reviewedSyncTimeLast);

    % Get the syncTime of the specified mouse and status
    if strcmp(mouseStatus, 'B')
        syncTime = reviewedSyncTime{strcmp(reviewedSyncTime.MouseName, mouseName), 'SyncTimeBaseReviewed'};
    elseif strcmp(mouseStatus, 'P')
        syncTime = reviewedSyncTime{strcmp(reviewedSyncTime.MouseName, mouseName), 'SyncTimeParkReviewed'};
    end
end