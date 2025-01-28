%% Function to review all mice's syncframe and save the reviewed data
% Reviews the sync frame of all mice and saves the reviewed data to a CSV file

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function ReviewSyncFrame(baseDirectory, videoDirectory)

    baseDir = baseDirectory;
    videoDir = videoDirectory;

    % Search for the last syncframe_reviewed_*.csv files
    reviewedSyncFrameDirs = dir(fullfile(baseDir, 'syncframe_reviewed_*.csv'));

    % If no prior reviewed syncframe file is found, start review
    if isempty(reviewedSyncFrameDirs)
        disp('No prior reviewed syncframe file is found... Starting review');
        ReviewSyncFrameAll(baseDir, videoDir);
    end

    % If prior reviewed syncframe is found, get the last reviewed syncframe file
    reviewedSyncFrameLast = fullfile(reviewedSyncFrameDirs(end).folder, reviewedSyncFrameDirs(end).name);
    disp(['Last reviewed syncframe file found: ' reviewedSyncFrameLast]);

    % Ask user if they want to review again
    doOverwrite = false;
    choice = questdlg('A reviewed syncframe file already exists. Do you want to review again?', ...
        'Review SyncFrame', ...
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
    ReviewSyncFrameAll(baseDir, videoDir);
end

%% Helper function to actually review all mice's syncframe and save the reviewed data
function ReviewSyncFrameAll(baseDir, videoDir)
    % Get all mouse metadata
    allMouseMeta = GetAllMouseMeta(baseDir, false);

    % Initialize variables
    syncFrames = {};

    % Loop through all mice
    for mouseIndex = 5 %1:size(allMouseMeta, 1)
        mouseName = allMouseMeta{mouseIndex, 1};
        mouseDir = allMouseMeta{mouseIndex, 2};
        baselineDLCData = allMouseMeta{mouseIndex, 5};
        parkinsonDLCData = allMouseMeta{mouseIndex, 8};

        % If baseline or parkinson DLC data is missing, skip review
        if ~baselineDLCData || ~parkinsonDLCData
            disp(['Skipping review for ' mouseName '... Missing baseline or parkinson DLC data']);
            continue;
        end

        % Get the video of the specified mouse
        videoFileBase = fullfile(videoDir, [mouseName, '_B_video_raw' '.mp4']);
        videoFilePark = fullfile(videoDir, [mouseName, '_P_video_raw' '.mp4']);

        % If video files do not exist, skip review
        if ~isfile(videoFileBase) || ~isfile(videoFilePark)
            disp(['Skipping review for ' mouseName '... Missing video files']);
            continue;
        end
        
        % Read the video file for baseline
        vb = VideoReader(videoFileBase);
        vb.CurrentTime = 30;
        totalFramesBase = vb.NumFrames;

        % Let the user specify a square region to detect LED blink
        disp('Please specify a square region to detect LED blink');
        framebase = readFrame(vb);
        figure, imshow(framebase);
        h = drawrectangle('Label', 'ROI');
        wait(h);
        position = h.Position;
        close(gcf);

        % Extract the region of interest (ROI)
        roi = round(position);
        roiFrames = zeros(roi(4)+1, roi(3)+1, totalFramesBase, 'uint8');
        vb.CurrentTime = 0;
        frameCount = 0;
        while hasFrame(vb) && frameCount < vb.FrameRate * 60
            frame = readFrame(vb);
            roiFrame = imcrop(frame, roi);
            roiFrames(:, :, frameCount + 1) = rgb2gray(roiFrame);
            frameCount = frameCount + 1;
        end
        
        % Apply contrast filtering to detect LED blinks
        filteredFrames = zeros(size(roiFrames), 'uint8');
        for i = 1:frameCount
            frame = roiFrames(:, :, i);
            minVal = double(min(frame(:)));
            maxVal = double(max(frame(:)));
            filteredFrames(:, :, i) = uint8(255 * (double(frame) - minVal) / (maxVal - minVal));
        end

        % Create a figure with a slider to navigate through the frames
        figure;
        hAx = axes;
        hImg = imshow(frameDiffs(:, :, 1), 'Parent', hAx);
        title('Navigate through ROI frames using the slider');
        hSlider = uicontrol('Style', 'slider', ...
            'Min', 1, 'Max', frameCount, 'Value', 1, ...
            'SliderStep', [1/(frameCount-1) , 10/(frameCount-1)], ...
            'Position', [150, 5, 300, 20]);
        addlistener(hSlider, 'Value', 'PostSet', @(src, event) ...
            set(hImg, 'CData', frameDiffs(:, :, round(get(hSlider, 'Value')))));
        uiwait(gcf);

        % Detect LED blinks
        ledBlinks = false(1, frameCount);
        threshold = 50; % Adjust this threshold as needed
        for i = 1:frameCount
            if max(filteredFrames(:, :, i), [], 'all') > threshold
            ledBlinks(i) = true;
            end
        end

        % Display the detected LED blinks
        disp('Detected LED blinks at frames:');
        disp(find(ledBlinks));

        % Get the syncFrame of the specified mouse and status
        %syncFrameBase = GetSyncFrame(mouseName, 'B', baseDir);
        %syncFramePark = GetSyncFrame(mouseName, 'P', baseDir);

        % Add the syncFrame to the syncFrames cell array
        syncFrames{end + 1, 1} = mouseName;
        syncFrames{end, 2} = syncFrameBase;
        syncFrames{end, 3} = syncFramePark;
    end

    % Create a table from the syncFrames cell array
    syncFramesTable = cell2table(syncFrames, 'VariableNames', {'MouseName', 'SyncFrameBase', 'SyncFramePark'});

    % Save the syncFrames table to a CSV file
    syncFramesFileName = ['syncframe_reviewed_' datestr(now, 'yyyymmdd_HHMMSS') '.csv'];
    syncFramesFile = fullfile(baseDir, syncFramesFileName);
    writetable(syncFramesTable, syncFramesFile);
    disp(['SyncFrame reviewed data saved to ' syncFramesFile]);
end