%% CLOI Open Field Analysis Main Script

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

% Clear workspace
clear
close all

% Specify default directory and mouse name cell list
defaultDir = "D:/CLOI_data";
mouseNameCell = {"ChAT_947-2", "ChAT_947-3", "ChAT_946-2", "ChAT_967-2"};

%% Get CLOI data and save to .mat file (Initial data collection)

% % Get struct data of session folders for selected mice
% sessionNameStruct = CLOI_GetSessionNameStruct(defaultDir, mouseNameCell);

% % Get cell list of session names for selected mice
% % - mouseState = "All" for all states, "Baseline" for baseline, "Parkinson" for parkinsonian state
% % - expType = "Both" for both experiments, "CLOI" for CLOI experiment, "Random" for random experiment
% sessionNameCell = CLOI_GetSessionNameCell(defaultDir, sessionNameStruct, "All", "Both");

% % Get struct data of DLC, movement, and laser data for selected mice
% sessionDataStruct = CLOI_GetSessionDataStruct(defaultDir, sessionNameCell);

% % Save session data to a .mat file
% save(defaultDir + "/CLOI_SessionDataStruct.mat", 'sessionDataStruct');

%% Load session data from .mat file (Use this for analysis)
load(defaultDir + "/CLOI_SessionDataStruct.mat", 'sessionDataStruct');

% Get cell list of session data for selected mice
% - mouseState = "All" for all states, "Baseline" for baseline, "Parkinson" for parkinsonian state
% - expType = "Both" for both experiments, "CLOI" for CLOI experiment, "Random" for random experiment
% - miniSession = "All" for all sessions, "OFF" for MS1, 3, 5, "ON" for MS 2, 4, 6, "Rest" for MS2-6, "MS1" ~ "MS6" for specific sessions
% - isMerged = true for merging all session data, false for separating session data

%% Average Stop to Movement Transition Time

% Get CLOI sessions
sessionData_CLOI = CLOI_GetSessionDataCell(sessionDataStruct, "All", "Random", "All", false);
% Analyze stop to movement transition time
CLOI_PlotStopToMovement(sessionData_CLOI, "Stop to Movement Transition Time - CLOI Sessions");

%% Movement Length Analysis

% 

%% Get FREQ data and save to .mat file

% % Specify default directory and mouse names
% defaultDir = "D:/CLOI_data";
% mouseNames = ["ChAT_967-1"];

% % Get the list of session folders for all mice
% sessionNames = cell(length(mouseNames)*3, 2);
% for mouseIdx = 1:length(mouseNames)
%     mouseName = mouseNames(mouseIdx);
%     sessionFolderDir = dir(defaultDir + "/" + mouseName);
%     sessionFolderNames = {sessionFolderDir([sessionFolderDir.isdir] & ~ismember({sessionFolderDir.name}, {'.', '..'})).name};
%     sessionFolderNames = sessionFolderNames(contains(sessionFolderNames, "FREQ")); % Filter for FREQ sessions
%     sessionNames(1+(mouseIdx-1)*3:mouseIdx*3, 1) = {mouseName};
%     sessionNames(1+(mouseIdx-1)*3:mouseIdx*3, 2) = sessionFolderNames;
% end

% % Iterate for each session and get DLC, movement data
% sessionData = cell(length(sessionNames), 62);
% for sessionIdx = 1:length(sessionNames)
%     mouseName = sessionNames{sessionIdx, 1};
%     sessionName = sessionNames{sessionIdx, 2};

%     % Deconstruct mouse data from session name
%     splitParts = split(sessionName, "_");
%     mouseStatus = splitParts{3} + "";
%     expType = splitParts{4} + "";
%     dateTime = splitParts{5} + "_" + splitParts{6};

%     % Load DLC data
%     dlcArray = CLOI_GetDLC(mouseName, mouseStatus, expType, dateTime, "head", defaultDir);
    
%     % Load movement data
%     [mvArrayTime, mvArrayState] = CLOI_GetMv(mouseName, mouseStatus, expType, dateTime, defaultDir);

%     % Get minisession (ms) frames
%     OFFframebool_ms1 = (mvArrayTime > 10.0 & mvArrayTime < 60.0);
%     OFFframebool_ms3 = (mvArrayTime >= 120.0 & mvArrayTime < 180.0);
%     OFFframebool_ms5 = (mvArrayTime >= 240.0 & mvArrayTime < 300.0);
%     OFFframebool_ms7 = (mvArrayTime >= 360.0 & mvArrayTime < 420.0);
%     OFFframebool_ms9 = (mvArrayTime >= 480.0 & mvArrayTime < 540.0);
%     OFFframebool_ms11 = (mvArrayTime >= 600.0 & mvArrayTime < 660.0);
%     OFFframebool_ms13 = (mvArrayTime >= 720.0 & mvArrayTime < 780.0);
%     OFFframebool_ms15 = (mvArrayTime >= 840.0 & mvArrayTime < 900.0);
%     OFFframebool_ms17 = (mvArrayTime >= 960.0 & mvArrayTime < 1020.0);
%     OFFframebool_ms19 = (mvArrayTime >= 1080.0 & mvArrayTime < 1140.0);

%     ONframebool_ms2 = (mvArrayTime >= 60.0 & mvArrayTime < 120.0);
%     ONframebool_ms4 = (mvArrayTime >= 180.0 & mvArrayTime < 240.0);
%     ONframebool_ms6 = (mvArrayTime >= 300.0 & mvArrayTime < 360.0);
%     ONframebool_ms8 = (mvArrayTime >= 420.0 & mvArrayTime < 480.0);
%     ONframebool_ms10 = (mvArrayTime >= 540.0 & mvArrayTime < 600.0);
%     ONframebool_ms12 = (mvArrayTime >= 660.0 & mvArrayTime < 720.0);
%     ONframebool_ms14 = (mvArrayTime >= 780.0 & mvArrayTime < 840.0);
%     ONframebool_ms16 = (mvArrayTime >= 900.0 & mvArrayTime < 960.0);
%     ONframebool_ms18 = (mvArrayTime >= 1020.0 & mvArrayTime < 1080.0);
%     ONframebool_ms20 = (mvArrayTime >= 1140.0 & mvArrayTime < 1200.0);

%     sessionData(sessionIdx, 1) = {mouseName};
%     sessionData(sessionIdx, 2) = {sessionName};
%     sessionData(sessionIdx, 3) = {mvArrayTime(OFFframebool_ms1, :)};
%     sessionData(sessionIdx, 4) = {mvArrayState(OFFframebool_ms1, :)};
%     sessionData(sessionIdx, 5) = {dlcArray(OFFframebool_ms1, :)};
%     sessionData(sessionIdx, 6) = {mvArrayTime(ONframebool_ms2, :)};
%     sessionData(sessionIdx, 7) = {mvArrayState(ONframebool_ms2, :)};
%     sessionData(sessionIdx, 8) = {dlcArray(ONframebool_ms2, :)};
%     sessionData(sessionIdx, 9) = {mvArrayTime(OFFframebool_ms3, :)};
%     sessionData(sessionIdx, 10) = {mvArrayState(OFFframebool_ms3, :)};
%     sessionData(sessionIdx, 11) = {dlcArray(OFFframebool_ms3, :)};
%     sessionData(sessionIdx, 12) = {mvArrayTime(ONframebool_ms4, :)};
%     sessionData(sessionIdx, 13) = {mvArrayState(ONframebool_ms4, :)};
%     sessionData(sessionIdx, 14) = {dlcArray(ONframebool_ms4, :)};
%     sessionData(sessionIdx, 15) = {mvArrayTime(OFFframebool_ms5, :)};
%     sessionData(sessionIdx, 16) = {mvArrayState(OFFframebool_ms5, :)};
%     sessionData(sessionIdx, 17) = {dlcArray(OFFframebool_ms5, :)};
%     sessionData(sessionIdx, 18) = {mvArrayTime(ONframebool_ms6, :)};
%     sessionData(sessionIdx, 19) = {mvArrayState(ONframebool_ms6, :)};
%     sessionData(sessionIdx, 20) = {dlcArray(ONframebool_ms6, :)};
%     sessionData(sessionIdx, 21) = {mvArrayTime(OFFframebool_ms7, :)};
%     sessionData(sessionIdx, 22) = {mvArrayState(OFFframebool_ms7, :)};
%     sessionData(sessionIdx, 23) = {dlcArray(OFFframebool_ms7, :)};
%     sessionData(sessionIdx, 24) = {mvArrayTime(ONframebool_ms8, :)};
%     sessionData(sessionIdx, 25) = {mvArrayState(ONframebool_ms8, :)};
%     sessionData(sessionIdx, 26) = {dlcArray(ONframebool_ms8, :)};
%     sessionData(sessionIdx, 27) = {mvArrayTime(OFFframebool_ms9, :)};
%     sessionData(sessionIdx, 28) = {mvArrayState(OFFframebool_ms9, :)};
%     sessionData(sessionIdx, 29) = {dlcArray(OFFframebool_ms9, :)};
%     sessionData(sessionIdx, 30) = {mvArrayTime(ONframebool_ms10, :)};
%     sessionData(sessionIdx, 31) = {mvArrayState(ONframebool_ms10, :)};
%     sessionData(sessionIdx, 32) = {dlcArray(ONframebool_ms10, :)};
%     sessionData(sessionIdx, 33) = {mvArrayTime(OFFframebool_ms11, :)};
%     sessionData(sessionIdx, 34) = {mvArrayState(OFFframebool_ms11, :)};
%     sessionData(sessionIdx, 35) = {dlcArray(OFFframebool_ms11, :)};
%     sessionData(sessionIdx, 36) = {mvArrayTime(ONframebool_ms12, :)};
%     sessionData(sessionIdx, 37) = {mvArrayState(ONframebool_ms12, :)};
%     sessionData(sessionIdx, 38) = {dlcArray(ONframebool_ms12, :)};
%     sessionData(sessionIdx, 39) = {mvArrayTime(OFFframebool_ms13, :)};
%     sessionData(sessionIdx, 40) = {mvArrayState(OFFframebool_ms13, :)};
%     sessionData(sessionIdx, 41) = {dlcArray(OFFframebool_ms13, :)};
%     sessionData(sessionIdx, 42) = {mvArrayTime(ONframebool_ms14, :)};
%     sessionData(sessionIdx, 43) = {mvArrayState(ONframebool_ms14, :)};
%     sessionData(sessionIdx, 44) = {dlcArray(ONframebool_ms14, :)};
%     sessionData(sessionIdx, 45) = {mvArrayTime(OFFframebool_ms15, :)};
%     sessionData(sessionIdx, 46) = {mvArrayState(OFFframebool_ms15, :)};
%     sessionData(sessionIdx, 47) = {dlcArray(OFFframebool_ms15, :)};
%     sessionData(sessionIdx, 48) = {mvArrayTime(ONframebool_ms16, :)};
%     sessionData(sessionIdx, 49) = {mvArrayState(ONframebool_ms16, :)};
%     sessionData(sessionIdx, 50) = {dlcArray(ONframebool_ms16, :)};
%     sessionData(sessionIdx, 51) = {mvArrayTime(OFFframebool_ms17, :)};
%     sessionData(sessionIdx, 52) = {mvArrayState(OFFframebool_ms17, :)};
%     sessionData(sessionIdx, 53) = {dlcArray(OFFframebool_ms17, :)};
%     sessionData(sessionIdx, 54) = {mvArrayTime(ONframebool_ms18, :)};
%     sessionData(sessionIdx, 55) = {mvArrayState(ONframebool_ms18, :)};
%     sessionData(sessionIdx, 56) = {dlcArray(ONframebool_ms18, :)};
%     sessionData(sessionIdx, 57) = {mvArrayTime(OFFframebool_ms19, :)};
%     sessionData(sessionIdx, 58) = {mvArrayState(OFFframebool_ms19, :)};
%     sessionData(sessionIdx, 59) = {dlcArray(OFFframebool_ms19, :)};
%     sessionData(sessionIdx, 60) = {mvArrayTime(ONframebool_ms20, :)};
%     sessionData(sessionIdx, 61) = {mvArrayState(ONframebool_ms20, :)};
%     sessionData(sessionIdx, 62) = {dlcArray(ONframebool_ms20, :)};

% end

%% Movement Data Analysis

% For CLOI session data
% DLCidx = [5, 8, 11, 14, 17, 20]; % DLC data index for all sessions
% For FREQ session data
% DLCidx = [5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 56, 59, 62]; % DLC data index for all sessions

% sigma = 1.0; % Movement bout cutoff sigma multiplier
% datalength = 2 + 9 * 6;

% movementData = cell(size(sessionData, 1), datalength);
% for sessionIdx = 1:size(sessionData, 1)
%     mouseName = sessionData{sessionIdx, 1};
%     sessionName = sessionData{sessionIdx, 2};

%     movementData(sessionIdx, 1) = {mouseName};
%     movementData(sessionIdx, 2) = {sessionName};
    
%     % Iterate for each mini sessions
%     for idx = 1:length(DLCidx)
%         % Extract OFF session data
%         dlc = sessionData{sessionIdx, DLCidx(idx)};
%         mv = sessionData{sessionIdx, DLCidx(idx)-1};
%         time = sessionData{sessionIdx, DLCidx(idx)-2};
        
%         position = dlc(:, 2:3); % Extract x and y coordinates
%         velocity = diff(position) ./ diff(time); % Calculate velocity
%         speed = sqrt(velocity(:, 1).^2 + velocity(:, 2).^2); % Calculate speed
%         smoothspeed = smoothdata(speed); % Smooth speed data

%         distance = sum(smoothspeed); % Calculate distance traveled
%         meanspeed = mean(smoothspeed); % Calculate mean speed
%         stdspeed = std(smoothspeed); % Calculate standard deviation of speed
%         peakspeed = max(smoothspeed); % Calculate peak velocity

%         speedcutoff = meanspeed + stdspeed; % Set cutoff for speed
%         [peaks, ~] = findpeaks(smoothspeed, 'MinPeakHeight', speedcutoff, 'MinPeakDistance', 10); % Find peaks in speed data
%         validmovnum = length(peaks); % Count valid movement bouts

%         % Calculate movement bouts and movement time
%         movbool = smoothspeed > speedcutoff; % Boolean array for movement
%         timeinterval = diff(time); % Time intervals
%         movetimedlc = timeinterval(movbool); % Extract time intervals for movement
%         stoptimedlc = timeinterval(~movbool); % Extract time intervals for stop
%         movetimesumdlc = sum(movetimedlc); % Total movement time
%         stoptimesumdlc = sum(stoptimedlc); % Total stop time
%         movetimeratiodlc = movetimesumdlc / (movetimesumdlc + stoptimesumdlc); % Ratio of movement time

%         mvbool = strcmp(mv, 'Move'); % Boolean array for movement state
%         mvbool = mvbool(2:end); % Adjust for length
%         movetimecloi = timeinterval(mvbool); % Extract time intervals for movement
%         stoptimecloi = timeinterval(~mvbool); % Extract time intervals for stop
%         movetimesumcloi = sum(movetimecloi); % Total movement time
%         stoptimesumcloi = sum(stoptimecloi); % Total stop time
%         movetimeratiocloi = movetimesumcloi / (movetimesumcloi + stoptimesumcloi); % Ratio of movement time

%         movementsimilarity = sum(~xor(movbool, mvbool))/length(mvbool); % Calculate similarity between movement states

%         % Calculate rotation angles for consecutive points
%         angles = zeros(length(position)-2, 1); % Preallocate for angles
%         for i = 2:length(position)-1
%             A = position(i-1, :); B = position(i, :); C = position(i+1, :);
%             AB = B - A; lenAB = norm(AB);
%             AC = C - A; lenAC = norm(AC);
%             dotProduct = dot(AB, AC);

%             % Calculate the angle using the cosine rule
%             cosTheta = dotProduct / (lenAB * lenAC);
%             cosTheta = max(min(cosTheta, 1), -1); % Clamp to avoid numerical issues
%             theta = acos(cosTheta); % Angle in radians

%             angles(i-1) = theta; % Store the angle
%         end
%         anglesum = sum(abs(angles)); % Calculate mean absolute angle
%         angularvelocity = diff(angles) ./ diff(time(2:end-1)); % Calculate angular velocity
%         angularvelocitysmooth = smoothdata(angularvelocity); % Smooth angular velocity data
%         angularvelocitysum = sum(abs(angularvelocitysmooth)); % Calculate mean absolute angular velocity

%         movementData(sessionIdx, 3+9*(idx-1)) = {distance};
%         movementData(sessionIdx, 4+9*(idx-1)) = {meanspeed};
%         movementData(sessionIdx, 5+9*(idx-1)) = {peakspeed};
%         movementData(sessionIdx, 6+9*(idx-1)) = {validmovnum};
%         movementData(sessionIdx, 7+9*(idx-1)) = {movetimeratiodlc};
%         movementData(sessionIdx, 8+9*(idx-1)) = {movetimeratiocloi};
%         movementData(sessionIdx, 9+9*(idx-1)) = {movementsimilarity};
%         movementData(sessionIdx, 10+9*(idx-1)) = {anglesum};
%         movementData(sessionIdx, 11+9*(idx-1)) = {angularvelocitysum};
%     end
% end

% Save movement data to a .mat file
% save(defaultDir + "/CLOI_MovementData.mat", 'movementData');
% save("FREQ_MovementData.mat", 'movementData');

% % Load movement data from a .mat file
% load("CLOI_MovementData.mat", 'movementData');
% load("FREQ_MovementData.mat", 'movementData');

% %% Plot FREQ OFF sessions

% offIdx = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]; % OFF session indices
% aspectNames = {'Distance', 'MeanSpeed', 'PeakSpeed', 'ValidMoveNum', 'MoveTimeRatioDLC', 'MoveTimeRatioCLOI', 'MovementSimilarity', 'AngleSum', 'AngularVelocitySum'};
% aspectPick = 9;

% figure('WindowState', 'maximized');
% barcolors = {[0.8, 0.8, 0.8], [1, 0.5, 0.5]}; % Colors for the bars
% pointcolors = {[0.5, 0.5, 0.5], [1, 0, 0]}; % Colors for the points

% aspectSearch = 2 + aspectPick + 9 * (offIdx * 2 - 2);
% data = cell2mat(movementData(:, aspectSearch)); % Extract data for the current session type and aspect
% means = mean(data); stds = std(data);
% hold on
% % Plot bar graphs with error bars
% bar_width = 0.6; % Width of the bars
% for i = 1:length(offIdx)
%     if i == 1
%         bar(i, means(i), bar_width, 'FaceColor', barcolors{2});
%     else
%         bar(i, means(i), bar_width, 'FaceColor', barcolors{1});
%     end
% end
% errorbar(1:10, means, stds, 'k', 'LineStyle', 'none', 'LineWidth', 1.5);

% % Plot scatter points
% for i = 1:10
%     if i == 1
%         scatter(i * ones(size(data, 1), 1), data(:, i), 'filled', 'MarkerFaceColor', pointcolors{2}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%     else
%         scatter(i * ones(size(data, 1), 1), data(:, i), 'filled', 'MarkerFaceColor', pointcolors{1}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%     end
% end
% % Graph settings
% set(gca, 'XTick', 1:10, 'XTickLabel', {'ms1', 'ms3', 'ms5', 'ms7', 'ms9', 'ms11', 'ms13', 'ms15', 'ms17', 'ms19'}, 'FontSize', 12, 'FontWeight', 'bold');
% xlabel("Mini Sessions", 'Interpreter', 'none');
% ylabel(aspectNames{aspectPick}, 'Interpreter', 'none');
% hold off

% sgtitle('Movement Data Aspects for Different Session Types');


%% Plot aspects of movement data - 4 session types, 6 minisessions

% sessionTypes = {'Baseline_CLOI', 'Baseline_Random', 'Parkinson_CLOI', 'Parkinson_Random'};
% aspectNames = {'Distance', 'MeanSpeed', 'PeakSpeed', 'ValidMoveNum', 'MoveTimeRatioDLC', 'MoveTimeRatioCLOI', 'MovementSimilarity', 'AngleSum', 'AngularVelocitySum'};
% aspectPick = [8, 9];
% sessionTypeSearchBase = [-2, -1, 0, 10, 11, 12]; % Search for session types in the data
% aspectSearchBase = [0, 1, 2, 3, 4, 5]; % Search for session types in the data

% figure('WindowState', 'maximized');
% barcolors = {[0.8, 0.8, 0.8], [0.5, 1, 0.5]}; % Colors for the bars
% pointcolors = {[0.5, 0.5, 0.5], [0, 1, 0]};
% sessionTypeNum = length(sessionTypes);
% aspectNum = length(aspectPick);
% for sessionTypeIdx = 1:sessionTypeNum
%     sessionType = sessionTypes{sessionTypeIdx};
%     sessionTypeSearch = sessionTypeIdx*3 + sessionTypeSearchBase; % Search for session types in the data
%     for aspectIdx = 1:aspectNum
%         aspectSearch = 2 + aspectPick(aspectIdx) + 9 * aspectSearchBase; % Search for aspects in the data
%         data = cell2mat(movementData(sessionTypeSearch, aspectSearch)); % Extract data for the current session type and aspect
%         means = mean(data);
%         stds = std(data);
%         % Create subplot for each aspect and session type
%         subplot(aspectNum, sessionTypeNum, sessionTypeIdx+sessionTypeNum*(aspectIdx-1));
%         hold on
%         % Plot bar graphs with error bars
%         bar_width = 0.6; % Width of the bars
%         b1 = bar(1, means(1), bar_width, 'FaceColor', barcolors{1});
%         b2 = bar(2, means(2), bar_width, 'FaceColor', barcolors{2});
%         b3 = bar(3, means(3), bar_width, 'FaceColor', barcolors{1});
%         b4 = bar(4, means(4), bar_width, 'FaceColor', barcolors{2});
%         b5 = bar(5, means(5), bar_width, 'FaceColor', barcolors{1});
%         b6 = bar(6, means(6), bar_width, 'FaceColor', barcolors{2});
%         errorbar(1:6, means, stds, 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
%         % Plot scatter points
%         scatter(1*ones(length(data), 1), data(:, 1), 'filled', 'MarkerFaceColor', pointcolors{1}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(2*ones(length(data), 1), data(:, 2), 'filled', 'MarkerFaceColor', pointcolors{2}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(3*ones(length(data), 1), data(:, 3), 'filled', 'MarkerFaceColor', pointcolors{1}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(4*ones(length(data), 1), data(:, 4), 'filled', 'MarkerFaceColor', pointcolors{2}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(5*ones(length(data), 1), data(:, 5), 'filled', 'MarkerFaceColor', pointcolors{1}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(6*ones(length(data), 1), data(:, 6), 'filled', 'MarkerFaceColor', pointcolors{2}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         % Graph settings
%         set(gca, 'XTick', 1:6, 'XTickLabel', {'ms1', 'ms2', 'ms3', 'ms4', 'ms5', 'ms6'}, 'FontSize', 12, 'FontWeight', 'bold');
%         title(sessionTypes{sessionTypeIdx}, 'Interpreter', 'none');
%         xlabel("Mini Sessions", 'Interpreter', 'none');
%         ylabel(aspectNames{aspectPick(aspectIdx)}, 'Interpreter', 'none');
%         hold off
%     end
% end
% sgtitle('Movement Data Aspects for Different Session Types');

%% Plot aspects of movement data - 2 session types, 6 minisessions

% sessionTypes = {'Baseline', 'Parkinson'};
% aspectNames = {'Distance', 'MeanSpeed', 'PeakSpeed', 'ValidMoveNum', 'MoveTimeRatioDLC', 'MoveTimeRatioCLOI', 'MovementSimilarity', 'AngleSum', 'AngularVelocitySum'};
% aspectPick = [8, 9];
% sessionTypeSearchBase = [-5, -4, -3, -2, -1, 0, 7, 8, 9, 10, 11, 12]; % Search for session types in the data
% aspectSearchBase = [0, 1, 2, 3, 4, 5]; % Search for session types in the data

% figure('WindowState', 'maximized');
% barcolors = {[0.8, 0.8, 0.8], [0.5, 1, 0.5]}; % Colors for the bars
% pointcolors = {[0.5, 0.5, 0.5], [0, 1, 0]};
% sessionTypeNum = length(sessionTypes);
% aspectNum = length(aspectPick);
% for sessionTypeIdx = 1:sessionTypeNum
%     sessionType = sessionTypes{sessionTypeIdx};
%     sessionTypeSearch = sessionTypeIdx*6 + sessionTypeSearchBase; % Search for session types in the data
%     for aspectIdx = 1:aspectNum
%         aspectSearch = 2 + aspectPick(aspectIdx) + 9 * aspectSearchBase; % Search for aspects in the data
%         data = cell2mat(movementData(sessionTypeSearch, aspectSearch)); % Extract data for the current session type and aspect
%         means = mean(data);
%         stds = std(data);
%         % Create subplot for each aspect and session type
%         subplot(aspectNum, sessionTypeNum, sessionTypeIdx+sessionTypeNum*(aspectIdx-1));
%         hold on
%         % Plot bar graphs with error bars
%         bar_width = 0.6; % Width of the bars
%         b1 = bar(1, means(1), bar_width, 'FaceColor', barcolors{1});
%         b2 = bar(2, means(2), bar_width, 'FaceColor', barcolors{2});
%         b3 = bar(3, means(3), bar_width, 'FaceColor', barcolors{1});
%         b4 = bar(4, means(4), bar_width, 'FaceColor', barcolors{2});
%         b5 = bar(5, means(5), bar_width, 'FaceColor', barcolors{1});
%         b6 = bar(6, means(6), bar_width, 'FaceColor', barcolors{2});
%         errorbar(1:6, means, stds, 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
%         % Plot scatter points
%         scatter(1*ones(length(data), 1), data(:, 1), 'filled', 'MarkerFaceColor', pointcolors{1}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(2*ones(length(data), 1), data(:, 2), 'filled', 'MarkerFaceColor', pointcolors{2}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(3*ones(length(data), 1), data(:, 3), 'filled', 'MarkerFaceColor', pointcolors{1}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(4*ones(length(data), 1), data(:, 4), 'filled', 'MarkerFaceColor', pointcolors{2}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(5*ones(length(data), 1), data(:, 5), 'filled', 'MarkerFaceColor', pointcolors{1}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(6*ones(length(data), 1), data(:, 6), 'filled', 'MarkerFaceColor', pointcolors{2}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         % Graph settings
%         set(gca, 'XTick', 1:6, 'XTickLabel', {'ms1', 'ms2', 'ms3', 'ms4', 'ms5', 'ms6'}, 'FontSize', 12, 'FontWeight', 'bold');
%         title(sessionTypes{sessionTypeIdx}, 'Interpreter', 'none');
%         xlabel("Mini Sessions", 'Interpreter', 'none');
%         ylabel(aspectNames{aspectPick(aspectIdx)}, 'Interpreter', 'none');
%         hold off
%     end
% end
% sgtitle('Movement Data Aspects for Different Session Types');

%% Plot aspects of movement data - 2 session types, OFF vs ON

% sessionTypes = {'Baseline', 'Parkinson'};
% aspectNames = {'Distance', 'MeanSpeed', 'PeakSpeed', 'ValidMoveNum', 'MoveTimeRatioDLC', 'MoveTimeRatioCLOI', 'MovementSimilarity', 'AngleSum', 'AngularVelocitySum'};
% aspectPick = [8, 9];
% sessionTypeSearchBase = [-5, -4, -3, -2, -1, 0, 7, 8, 9, 10, 11, 12]; % Search for session types in the data
% aspectSearchBase = [0, 1, 2, 3, 4, 5]; % Search for session types in the data

% figure('WindowState', 'maximized');
% barcolors = {[0.8, 0.8, 0.8], [0.5, 1, 0.5]}; % Colors for the bars
% pointcolors = {[0.5, 0.5, 0.5], [0, 1, 0]};
% sessionTypeNum = length(sessionTypes);
% aspectNum = length(aspectPick);
% for sessionTypeIdx = 1:sessionTypeNum
%     sessionType = sessionTypes{sessionTypeIdx};
%     sessionTypeSearch = sessionTypeIdx*6 + sessionTypeSearchBase; % Search for session types in the data
%     for aspectIdx = 1:aspectNum
%         aspectSearch = 2 + aspectPick(aspectIdx) + 9 * aspectSearchBase; % Search for aspects in the data
%         data = cell2mat(movementData(sessionTypeSearch, aspectSearch)); % Extract data for the current session type and aspect
%         dataOFF = sum(data(:, [1, 3, 5]), 2); % Extract OFF session data
%         meansOFF = mean(dataOFF); stdsOFF = std(dataOFF);
%         dataON = sum(data(:, [2, 4, 6]), 2); % Extract ON session data
%         meansON = mean(dataON); stdsON = std(dataON);
%         % Create subplot for each aspect and session type
%         subplot(aspectNum, sessionTypeNum, sessionTypeIdx+sessionTypeNum*(aspectIdx-1));
%         hold on
%         % Plot bar graphs with error bars
%         bar_width = 0.6; % Width of the bars
%         b1 = bar(1, meansOFF, bar_width, 'FaceColor', barcolors{1});
%         b2 = bar(2, meansON, bar_width, 'FaceColor', barcolors{2});
%         errorbar(1:2, [meansOFF, meansON], [stdsOFF, stdsON], 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
%         % Plot scatter points
%         scatter(1*ones(length(dataOFF), 1), dataOFF, 'filled', 'MarkerFaceColor', pointcolors{1}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(2*ones(length(dataON), 1), dataON, 'filled', 'MarkerFaceColor', pointcolors{2}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         % Graph settings
%         set(gca, 'XTick', 1:2, 'XTickLabel', {'OFF', 'ON'}, 'FontSize', 12, 'FontWeight', 'bold');
%         title(sessionTypes{sessionTypeIdx}, 'Interpreter', 'none');
%         xlabel("Mini Sessions", 'Interpreter', 'none');
%         ylabel(aspectNames{aspectPick(aspectIdx)}, 'Interpreter', 'none');
%         hold off
%     end
% end
% sgtitle('Movement Data Aspects for Different Session Types');

%% Plot aspects of movement data - compare OFF sessions

% sessionTypes = {'Baseline_CLOI', 'Baseline_Random', 'Parkinson_CLOI', 'Parkinson_Random'};
% aspectNames = {'Distance', 'MeanSpeed', 'PeakSpeed', 'ValidMoveNum', 'MoveTimeRatioDLC', 'MoveTimeRatioCLOI', 'MovementSimilarity', 'AngleSum', 'AngularVelocitySum'};
% aspectPick = [5, 6];
% sessionTypeSearchBase = [-2, -1, 0, 10, 11, 12]; % Search for session types in the data
% aspectSearchBase = [0, 1, 2, 3, 4, 5]; % Search for session types in the data

% figure('WindowState', 'maximized');
% barcolors = {[0.8, 0.8, 0.8], [0.5, 1, 0.5]}; % Colors for the bars
% pointcolors = {[0.5, 0.5, 0.5], [0, 1, 0]};
% sessionTypeNum = length(sessionTypes);
% aspectNum = length(aspectPick);
% for sessionTypeIdx = 1:sessionTypeNum
%     sessionType = sessionTypes{sessionTypeIdx};
%     sessionTypeSearch = sessionTypeIdx*3 + sessionTypeSearchBase; % Search for session types in the data
%     for aspectIdx = 1:aspectNum
%         aspectSearch = 2 + aspectPick(aspectIdx) + 9 * aspectSearchBase; % Search for aspects in the data
%         data = cell2mat(movementData(sessionTypeSearch, aspectSearch)); % Extract data for the current session type and aspect
%         means = mean(data);
%         stds = std(data);
%         % Create subplot for each aspect and session type
%         subplot(aspectNum, sessionTypeNum, sessionTypeIdx+sessionTypeNum*(aspectIdx-1));
%         hold on
%         % Plot bar graphs with error bars
%         bar_width = 0.6; % Width of the bars
%         b1 = bar(1, means(1), bar_width, 'FaceColor', barcolors{1});
%         b3 = bar(2, means(3), bar_width, 'FaceColor', barcolors{1});
%         b5 = bar(3, means(5), bar_width, 'FaceColor', barcolors{1});
%         errorbar(1:3, means(:, [1, 3, 5]), stds(:, [1, 3, 5]), 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
%         % Plot scatter points
%         scatter(1*ones(length(data), 1), data(:, 1), 'filled', 'MarkerFaceColor', pointcolors{1}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(2*ones(length(data), 1), data(:, 3), 'filled', 'MarkerFaceColor', pointcolors{1}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         scatter(3*ones(length(data), 1), data(:, 5), 'filled', 'MarkerFaceColor', pointcolors{1}, 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
%         % Graph settings
%         set(gca, 'XTick', 1:3, 'XTickLabel', {'ms1', 'ms3', 'ms5'}, 'FontSize', 12, 'FontWeight', 'bold');
%         title(sessionTypes{sessionTypeIdx}, 'Interpreter', 'none');
%         xlabel("Mini Sessions", 'Interpreter', 'none');
%         ylabel(aspectNames{aspectPick(aspectIdx)}, 'Interpreter', 'none');
%         hold off
%     end
% end
% sgtitle('Movement Data Aspects for Different Session Types');