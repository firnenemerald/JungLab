%% PV_YM_MainAnalysis.m
% Main analysis of PV dual recording Y-maze experiment data

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

% heatmap
% center arm
% event
% intocenter outofcenter
% regression - arm vs center, intocenter vs outofcenter
% svm decoding - arm vs center
% velocity

clearvars
close all

%% Data Loading and Synchronization
dirPath = "C:\Users\chanh\Downloads\PV_data\";
expName = "PV_3-1_24-05-17-11-39-29_YM";
expPath = fullfile(dirPath, expName, "DLC");

[doricTime, doricGCaMP, doricRCaMP, dlcFrame, dlcHead, dlcBody, dlcTail, startFrame, endFrame] = PV_SyncData(expName);

disp(['doricTime # = ' num2str(size(doricTime, 1))])
disp(['doricGCaMP # = ' num2str(size(doricGCaMP, 1))])
disp(['doricRCaMP # = ' num2str(size(doricRCaMP, 1))])
disp(['dlcFrame # = ' num2str(size(dlcFrame, 1))])
disp(['dlcHead # = ' num2str(size(dlcHead, 1))])
disp(['dlcBody # = ' num2str(size(dlcBody, 1))])
disp(['dlcTail # = ' num2str(size(dlcTail, 1))])

%% Video Loading
mp4Files = dir(fullfile(expPath, '*.mp4'));
if isempty(mp4Files)
    error('No .mp4 files found in the specified directory.');
end
uniqueMp4File = mp4Files(1).name; % Assuming there's only one .mp4 file
videoPath = fullfile(expPath, uniqueMp4File);
videoObj = VideoReader(videoPath);

% Estimate total number of frames
frameRate = videoObj.FrameRate;
videoDuration = videoObj.Duration; % in seconds
totalFrames = floor(frameRate * videoDuration);
disp(['Estimated Total Video Frames: ', num2str(totalFrames)]);

middleFrameIndex = round(totalFrames / 2);
% Calculate time for the middle frame
middleFrameTime = (middleFrameIndex - 1) / frameRate;
videoObj.CurrentTime = middleFrameTime;
middleFrame = readFrame(videoObj);

%% Get Center Vertex via Manual Clicks
triangleCenter = getTriangleCenter(middleFrame);

%% Create Interactive GUI
createInteractiveGUI(videoObj, doricTime, doricGCaMP, doricRCaMP, dlcFrame, dlcHead, dlcBody, dlcTail, triangleCenter, frameRate, totalFrames);

%% Nested Function to Select Triangle Center
    function triangleCenter = getTriangleCenter(frame)
        centerfig = figure('Name', 'Select Triangle Vertices', 'NumberTitle', 'off');
        imshow(frame);
        hold on;
        title('Select 3 vertices for the triangle center');
        
        selectedPoints = zeros(3, 2);
        for i = 1:3
            [x, y] = ginput(1); % Get 1 point from user input
            selectedPoints(i, :) = [x, y]; % Store the selected point
            scatter(x, y, 'r', 'filled');
        end
        
        % Calculate and plot the center of the triangle
        triangleCenter = mean(selectedPoints, 1);
        scatter(triangleCenter(1), triangleCenter(2), 'b', 'filled', 'Marker', 'o');
        
        title('Press Enter to confirm or "q" to quit');
        
        % Wait for confirmation
        while true
            waitforbuttonpress;
            key = get(gcf, 'CurrentCharacter');
            if key == 'q'
                close(centerfig);
                error('User quit the selection.');
            elseif key == char(13)  % Enter key
                scatter(triangleCenter(1), triangleCenter(2), 'g', 'filled', 'Marker', 'o');
                pause(1.0);
                break;
            end
        end
        
        close(centerfig);
        disp(['Triangle Center Vertex Position: (', num2str(triangleCenter(1)), ', ', num2str(triangleCenter(2)), ')']);
    end

%% Nested Function to Create Interactive GUI
    function createInteractiveGUI(videoObj, doricTime, doricGCaMP, doricRCaMP, dlcFrame, dlcHead, dlcBody, dlcTail, triangleCenter, frameRate, totalFrames)
        % Initialize figure
        fig = figure('Name', 'Interactive Image Player', 'NumberTitle', 'off', 'WindowStyle', 'normal', 'Position', [100, 100, 1200, 800]);
        
        % Create axes for displaying the image and signals
        axImage = subplot(2, 2, 1); % Top left for image frame
        axGCaMP = subplot(2, 2, 3); % Bottom left for GCaMP signal
        axRCaMP = subplot(2, 2, 4); % Bottom right for RCaMP signal
        
        % Initialize image display
        imageHandle = imshow(middleFrame, 'Parent', axImage);
        hold(axImage, 'on');
        headScatter = scatter(axImage, dlcHead(middleFrameIndex,1), dlcHead(middleFrameIndex,2), 50, 'r', 'filled');
        bodyScatter = scatter(axImage, dlcBody(middleFrameIndex,1), dlcBody(middleFrameIndex,2), 50, 'g', 'filled');
        tailScatter = scatter(axImage, dlcTail(middleFrameIndex,1), dlcTail(middleFrameIndex,2), 50, 'b', 'filled');
        arrowHandle = quiver(axImage, triangleCenter(1), triangleCenter(2), ...
            dlcBody(middleFrameIndex,1) - triangleCenter(1), dlcBody(middleFrameIndex,2) - triangleCenter(2), ...
            0, 'k', 'LineWidth', 1.5, 'MaxHeadSize', 2);
        hold(axImage, 'off');
        title(axImage, ['Frame: ', num2str(middleFrameIndex)]);
        
        % Initialize GCaMP plot
        plot(axGCaMP, doricTime, doricGCaMP, 'g');
        hold(axGCaMP, 'on');
        currentGCaMP = plot(axGCaMP, doricTime(middleFrameIndex), doricGCaMP(middleFrameIndex), 'k.', 'MarkerSize', 15);
        xlabel(axGCaMP, 'Time (s)');
        ylabel(axGCaMP, 'GCaMP Signal');
        title(axGCaMP, 'GCaMP Signal');
        xlim(axGCaMP, [min(doricTime), max(doricTime)]);
        ylim(axGCaMP, [min(doricGCaMP), max(doricGCaMP)]);
        hold(axGCaMP, 'off');
        
        % Initialize RCaMP plot
        plot(axRCaMP, doricTime, doricRCaMP, 'r');
        hold(axRCaMP, 'on');
        currentRCaMP = plot(axRCaMP, doricTime(middleFrameIndex), doricRCaMP(middleFrameIndex), 'k.', 'MarkerSize', 15);
        xlabel(axRCaMP, 'Time (s)');
        ylabel(axRCaMP, 'RCaMP Signal');
        title(axRCaMP, 'RCaMP Signal');
        xlim(axRCaMP, [min(doricTime), max(doricTime)]);
        ylim(axRCaMP, [min(doricRCaMP), max(doricRCaMP)]);
        hold(axRCaMP, 'off');
        
        % Create a slider for frame selection
        slider = uicontrol('Style', 'slider', ...
            'Min', 1, ...
            'Max', totalFrames, ...
            'Value', middleFrameIndex, ...
            'Position', [150, 30, 800, 20], ...
            'SliderStep', [1/(totalFrames-1), 10/(totalFrames-1)]);
        
        % Add listener for slider
        addlistener(slider, 'Value', 'PostSet', @(src, event) sliderCallback(src, event));
        
        % Create buttons for frame control
        btnWidth = 100;
        btnHeight = 30;
        uicontrol('Style', 'pushbutton', 'String', '-10 Frames', 'Position', [50, 30, btnWidth, btnHeight], ...
            'Callback', @(src, event) buttonCallback(-10));
        uicontrol('Style', 'pushbutton', 'String', '-1 Frame', 'Position', [160, 30, btnWidth, btnHeight], ...
            'Callback', @(src, event) buttonCallback(-1));
        uicontrol('Style', 'pushbutton', 'String', '+1 Frame', 'Position', [270, 30, btnWidth, btnHeight], ...
            'Callback', @(src, event) buttonCallback(1));
        uicontrol('Style', 'pushbutton', 'String', '+10 Frames', 'Position', [380, 30, btnWidth, btnHeight], ...
            'Callback', @(src, event) buttonCallback(10));
        
        % Store initial frame index
        currentFrameIndex = middleFrameIndex;
        
        % Store plot handles and data in guidata
        guiData.imageHandle = imageHandle;
        guiData.headScatter = headScatter;
        guiData.bodyScatter = bodyScatter;
        guiData.tailScatter = tailScatter;
        guiData.arrowHandle = arrowHandle;
        guiData.currentGCaMP = currentGCaMP;
        guiData.currentRCaMP = currentRCaMP;
        guiData.videoObj = videoObj;
        guiData.doricTime = doricTime;
        guiData.doricGCaMP = doricGCaMP;
        guiData.doricRCaMP = doricRCaMP;
        guiData.dlcHead = dlcHead;
        guiData.dlcBody = dlcBody;
        guiData.dlcTail = dlcTail;
        guiData.triangleCenter = triangleCenter;
        guiData.slider = slider;
        guiData.axImage = axImage;
        guiData.axGCaMP = axGCaMP;
        guiData.axRCaMP = axRCaMP;
        guiData.frameRate = frameRate;
        guiData.totalFrames = totalFrames;
        guiData.currentFrameIndex = currentFrameIndex;
        guidata(fig, guiData);
        
        % Initial frame display
        updateFrame(currentFrameIndex);
        
        %% Nested Callback Function for Slider
        function sliderCallback(~, ~)
            guiData = guidata(fig);
            newFrameIndex = round(guiData.slider.Value);
            updateFrame(newFrameIndex);
        end
        
        %% Nested Callback Function for Buttons
        function buttonCallback(delta)
            guiData = guidata(fig);
            newFrameIndex = guiData.currentFrameIndex + delta;
            newFrameIndex = max(1, min(newFrameIndex, guiData.totalFrames)); % Ensure within bounds
            guiData.slider.Value = newFrameIndex;
            updateFrame(newFrameIndex);
        end
        
        %% Nested Function to Update Frame and Plots
        function updateFrame(frameIndex)
            guiData = guidata(fig);
            if frameIndex == guiData.currentFrameIndex
                return; % No change
            end
            
            % Calculate the time for the desired frame
            frameTime = (frameIndex - 1) / guiData.frameRate;
            videoObj = guiData.videoObj;
            videoObj.CurrentTime = frameTime;
            
            % Read the frame
            try
                currentFrame = readFrame(videoObj);
            catch ME
                disp(['Error reading frame ' num2str(frameIndex) ': ', ME.message]);
                return;
            end
            
            % Update Image
            set(guiData.imageHandle, 'CData', currentFrame);
            set(guiData.headScatter, 'XData', guiData.dlcHead(frameIndex, 1), 'YData', guiData.dlcHead(frameIndex, 2));
            set(guiData.bodyScatter, 'XData', guiData.dlcBody(frameIndex, 1), 'YData', guiData.dlcBody(frameIndex, 2));
            set(guiData.tailScatter, 'XData', guiData.dlcTail(frameIndex, 1), 'YData', guiData.dlcTail(frameIndex, 2));
            set(guiData.arrowHandle, 'XData', guiData.triangleCenter(1), 'YData', guiData.triangleCenter(2), ...
                'UData', guiData.dlcBody(frameIndex, 1) - guiData.triangleCenter(1), ...
                'VData', guiData.dlcBody(frameIndex, 2) - guiData.triangleCenter(2));
            title(guiData.axImage, ['Frame: ', num2str(frameIndex)]);
            
            % Update GCaMP Signal Indicator
            currentTime = guiData.doricTime(frameIndex);
            currentGCaMPValue = guiData.doricGCaMP(frameIndex);
            set(guiData.currentGCaMP, 'XData', currentTime, 'YData', currentGCaMPValue);
            
            % Update RCaMP Signal Indicator
            currentRCaMPValue = guiData.doricRCaMP(frameIndex);
            set(guiData.currentRCaMP, 'XData', currentTime, 'YData', currentRCaMPValue);
            
            % Update current frame index
            guiData.currentFrameIndex = frameIndex;
            guidata(fig, guiData);
            
            drawnow; % Ensure the GUI updates
        end
    end
end
