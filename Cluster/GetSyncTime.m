%% Function to get syncTime of specified mouse and status
% Returns syncTime (double)

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function syncTime = GetSyncTime(mouseName, mouseStatus)
    % Set default base directory
    baseDir = './data';
    
    % Construct file paths
    gpioDir = fullfile(baseDir, [mouseName '_' mouseStatus '_gpio.csv']);

    % Read the CSV file
    gpioTable = readtable(gpioDir, "VariableNamingRule", "preserve");
    gpioTableTime = table2array(gpioTable(:, 1));
    gpioTableValue = table2array(gpioTable(:, 3));
    
    % Get GPIO-1 time and value data
    gpioTime = gpioTableTime(strcmp(gpioTable.("Channel Name"), 'GPIO-1'), :);
    gpioValue = gpioTableValue(strcmp(gpioTable.("Channel Name"), 'GPIO-1'), :);

    % GPIO value threshold
    gpioThreshold = (max(gpioValue) + min(gpioValue)) / 2;

    % Find the sync time
    incValueTime = gpioTime(diff(gpioValue) > gpioThreshold);
    incValueTimeGap = diff(incValueTime);
    incValueTimeGapIndex = find((incValueTimeGap < 2.1) & (incValueTimeGap > 1.9), 1); % Find the first time gap around 2s
    syncTime = incValueTime(incValueTimeGapIndex);

    % Plot the GPIO-1 signal (debugging)
    figure
    plot(gpioTime, gpioValue)
    xlim([syncTime - 10, syncTime + 20])
    hold on
    yline(gpioThreshold, 'r--', 'threshold')
    xline(syncTime, 'r-')
    title('GPIO-1 Signal')
    xlabel('Time (s)')
    ylabel('Value')
    hold off
end