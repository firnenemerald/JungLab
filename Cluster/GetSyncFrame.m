%% Function to get syncFrame of specified mouse and status
% Returns syncFrame (int)

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function syncFrame = GetSyncFrame(mouseName, mouseStatus, baseDirectory)
    % Set default base directory
    baseDir = baseDirectory;
    
    % Search for the last syncframe_reviewed_*.csv files
    reviewedSyncFrameDirs = dir(fullfile(baseDir, 'syncframe_reviewed_*.csv'));

    % If no prior reviewed syncframe files found, raise an error
    if isempty(reviewedSyncFrameDirs)
        error('No prior reviewed syncframe files found... Please review the data first');
    end

    % Else, get the syncFrame from the last reviewed syncframe file
    syncFrame = GetSyncFrameFromReviewed(mouseName, mouseStatus, reviewedSyncFrameDirs);
end

%% Helper function to actually get syncFrame if there is a reviewed syncframe file
function syncFrame = GetSyncFrameFromReviewed(mouseName, mouseStatus, reviewedSyncFrameDirs)

    % Get the last reviewed syncframe file
    reviewedSyncFrameLast = fullfile(reviewedSyncFrameDirs(end).folder, reviewedSyncFrameDirs(end).name);
    disp(['Last reviewed syncframe file found: ' reviewedSyncFrameLast]);

    % Read the last reviewed syncframe file
    reviewedSyncFrame = readtable(reviewedSyncFrameLast);

    % Get the syncFrame of the specified mouse and status
    if strcmp(mouseStatus, 'B')
        syncFrame = reviewedSyncFrame{strcmp(reviewedSyncFrame.MouseName, mouseName), 'SyncFrameBaseReviewed'};
    elseif strcmp(mouseStatus, 'P')
        syncFrame = reviewedSyncFrame{strcmp(reviewedSyncFrame.MouseName, mouseName), 'SyncFrameParkReviewed'};
    end
end