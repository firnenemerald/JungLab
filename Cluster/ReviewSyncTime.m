%% Function to review all mice's synctime and save the reviewed data
% Reviews the sync time of all mice and saves the reviewed data to a CSV file

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function ReviewSyncTime(baseDirectory)

    baseDir = baseDirectory;

    % Search for the last synctime_reviewed_*.csv files
    reviewedSyncTimeDirs = dir(fullfile(baseDir, 'synctime_reviewed_*.csv'));

    % If no prior reviewed synctime file is found, start review
    if isempty(reviewedSyncTimeDirs)
        disp('No prior reviewed synctime file is found... Starting review');
        ReviewSyncTimeAll(baseDir);
    end

    % If prior reviewed synctime is found, get the last reviewed synctime file
    reviewedSyncTimeLast = fullfile(reviewedSyncTimeDirs(end).folder, reviewedSyncTimeDirs(end).name);
    disp(['Last reviewed synctime file found: ' reviewedSyncTimeLast]);

    % Ask user if they want to review again
    doOverwrite = false;
    choice = questdlg('A reviewed synctime file already exists. Do you want to review again?', ...
        'Review SyncTime', ...
        'Yes', 'No', 'No');
    if strcmp(choice, 'Yes')
        doOverwrite = true;
    end

    % If user response is not 'y', end review
    if ~doOverwrite
        disp('User response is ''No''... Ending review');
        return;
    end

    % If user response is 'y', start review
    disp('User response is ''Yes''... Starting review');
    ReviewSyncTimeAll(baseDir);
end

%% Helper function to actually review all mice's synctime and save the reviewed data
function ReviewSyncTimeAll(baseDir)
    % Get all mouse metadata
    allMouseMeta = GetAllMouseMeta(baseDir, false);

    % Initialize variables
    syncTimes = {};

    % Loop through all mice
    for mouseIndex = 1:size(allMouseMeta, 1)
        mouseName = allMouseMeta{mouseIndex, 1};
        mouseDir = allMouseMeta{mouseIndex, 2};
        baselineGpioSignal = allMouseMeta{mouseIndex, 4};
        parkinsonGpioSignal = allMouseMeta{mouseIndex, 7};

        % If baseline or parkinson GPIO signal is missing, skip review
        if ~baselineGpioSignal || ~parkinsonGpioSignal
            disp(['Skipping review for ' mouseName ' due to missing GPIO signal']);
            syncTimes = [syncTimes; {mouseName, NaN, NaN}];
            continue;
        end
        
        % Get the baseline and parkinson GPIO signals
        baselineGpioTable = readtable(fullfile(mouseDir, [mouseName '_B_gpio.csv']), "VariableNamingRule", "preserve");
        parkinsonGpioTable = readtable(fullfile(mouseDir, [mouseName '_P_gpio.csv']), "VariableNamingRule", "preserve");

        % Get the baseline and parkinson GPIO time and value data
        baselineGpioTableTime = table2array(baselineGpioTable(:, 1));
        baselineGpioTableValue = table2array(baselineGpioTable(:, 3));
        parkinsonGpioTableTime = table2array(parkinsonGpioTable(:, 1));
        parkinsonGpioTableValue = table2array(parkinsonGpioTable(:, 3));

        % Get the GPIO value threshold
        baselineGpioThreshold = (max(baselineGpioTableValue) + min(baselineGpioTableValue)) / 2;
        parkinsonGpioThreshold = (max(parkinsonGpioTableValue) + min(parkinsonGpioTableValue)) / 2;

        % Find the possible sync times
        baselineIncValueTime = baselineGpioTableTime(diff(baselineGpioTableValue) > baselineGpioThreshold);
        parkinsonIncValueTime = parkinsonGpioTableTime(diff(parkinsonGpioTableValue) > parkinsonGpioThreshold);
        
        % Plot the baseline and parkinson GPIO signals (review)
        figure
        
        subplot(2, 1, 1)
        plot(baselineGpioTableTime, baselineGpioTableValue)
        xlim([baselineIncValueTime(1) - 50, baselineIncValueTime(1) + 100])
        hold on
        yline(baselineGpioThreshold, 'r--', 'threshold')
        for i = 1:length(baselineIncValueTime)
            xline(baselineIncValueTime(i), 'g--');
        end
        title([string(mouseName) ' Baseline GPIO Signal'], "Interpreter", "none")
        xlabel('Time (s)')
        ylabel('Value')
        hold off

        subplot(2, 1, 2)
        plot(parkinsonGpioTableTime, parkinsonGpioTableValue)
        xlim([parkinsonIncValueTime(1) - 50, parkinsonIncValueTime(1) + 100])
        hold on
        yline(parkinsonGpioThreshold, 'r--', 'threshold')
        for i = 1:length(parkinsonIncValueTime)
            xline(parkinsonIncValueTime(i), 'g--');
        end
        title([string(mouseName) ' Parkinson GPIO Signal'], "Interpreter", "none")
        xlabel('Time (s)')
        ylabel('Value')
        hold off

        % Show figure as fullscreen
        set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);

        % Get user input for baseline sync time
        disp('Click on the plot to select the baseline sync time');
        [xBase, ~] = ginput(1);
        [~, idxBase] = min(abs(baselineIncValueTime - xBase));
        syncTimeBaseReviewed = baselineIncValueTime(idxBase);
        xline(syncTimeBaseReviewed, 'b-', 'Reviewed Sync Time');

        % Get user input for parkinson sync time
        disp('Click on the plot to select the parkinson sync time');
        [xPark, ~] = ginput(1);
        [~, idxPark] = min(abs(parkinsonIncValueTime - xPark));
        syncTimeParkReviewed = parkinsonIncValueTime(idxPark);
        xline(syncTimeParkReviewed, 'b-', 'Reviewed Sync Time');
        
        % Save the reviewed sync times
        syncTimes = [syncTimes; {mouseName, syncTimeBaseReviewed, syncTimeParkReviewed}];

        % Close the figure
        close(gcf);
    end

    % Convert the reviewed sync times to a table
    syncTimesTable = cell2table(syncTimes, 'VariableNames', {'MouseName', 'SyncTimeBaseReviewed', 'SyncTimeParkReviewed'});

    % Save the reviewed sync times to a CSV file
    currentTime = datetime('now', 'Format', 'yyyyMMdd-HHmmss');
    reviewedSyncTimeFile = fullfile(baseDir, ['synctime_reviewed_' char(currentTime) '.csv']);
    writetable(syncTimesTable, reviewedSyncTimeFile);

    disp(['Reviewed sync times saved to ' reviewedSyncTimeFile]);
end