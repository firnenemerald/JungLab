%% Function to review video of a specific mice and state and return the reviewed data
% Reviews the sync frame of all mice and saves the reviewed data to a CSV file

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function reviewedVideo = ReviewRawVideo(mouseName, mouseStatus, videoDirectory, isVisualized)
    % REVIEWRAWVIDEO displays a specific frame (at 10 seconds) of a raw 
    % video for a given mouse and status, and asks the user to select 3 points 
    % that define a unique circle through them (the circumcircle).

    % Build the video file path
    videoDir = fullfile(videoDirectory, [mouseName '_' mouseStatus '_video_raw.mp4']);
    
    % Check that the file exists
    if ~isfile(videoDir)
        error('Video file not found... Please check the video directory');
    end

    % Read the video file
    video = VideoReader(videoDir);
    
    % Initialize the reviewed video variable
    reviewedVideo = {};

    %% Part 1: Display a video frame and ask user to specify a circle to calibrate length

    % Go to time = 10 seconds in the video
    video.CurrentTime = 10;
    frame = readFrame(video);

    % Keep asking until the user confirms the circle
    confirmCircle = false;
    while ~confirmCircle
        % Display the frame
        imshow(frame);
        hold on;
        title('Please click 3 non-collinear points to define a circle', 'Color', 'r');
        
        % Get 3 points from user
        x = zeros(1,3);
        y = zeros(1,3);
        for i = 1:3
            [xi, yi] = ginput(1);
            x(i) = xi;
            y(i) = yi;
            plot(xi, yi, 'bx', 'MarkerSize', 3, 'LineWidth', 10);
        end

        % Basic validation
        if numel(x) < 3 || numel(y) < 3
            error('Please pick exactly 3 points.');
        end

        % Calculate center (cx,cy) and radius of circumcircle
        [cx, cy, radius, isValid] = calcCircumcircle(x(1), y(1), x(2), y(2), x(3), y(3));
        
        if ~isValid
            % The points are collinear or something went wrong
            warning('Selected points are collinear or invalid. Please try again.');
            hold off;
            continue;
        end
        
        % Display the circumcircle and text regarding radius
        hCircle = viscircles([cx, cy], radius, 'EdgeColor', 'r');
        hCenter = plot(cx, cy, 'ro', 'MarkerSize', 4, 'LineWidth', 2);
        hLine = plot([cx, x(1)], [cy, y(1)], 'r--', 'LineWidth', 1);
        midX = (cx + x(1)) / 2;
        midY = (cy + y(1)) / 2;
        hText = text(midX, midY, sprintf('r = %d(px)', round(radius)), 'Color', 'r', 'FontSize', 12, 'HorizontalAlignment', 'center');
        hold off;

        % Prompt user to confirm
        choice = questdlg('Is the circle correct?', 'Confirm Circle', 'Yes', 'No', 'Cancel', 'Yes');

        switch choice
            case 'Yes'
                confirmCircle = true;
                close(gcf);
            case 'No'
                delete(hCircle);
                delete(hText);
            otherwise
                disp('User canceled. Exiting function.');
                return;
        end
    end

    %% Part 2-1: Display a video frame and ask user to specify the LED blink region
    timeWindow = 2000;
    
    pixelHalfWindow = 20;
    pixelWindow = 2 * pixelHalfWindow + 1;
    
    video.CurrentTime = 5;
    frame = readFrame(video);

    % Display the frame
    imshow(frame);
    hold on;
    title('Please click on the LED blink position', 'Color', 'r');

    % Get the LED blink position from the user
    [ledX, ledY] = ginput(1);
    % Round to nearest integer
    ledX = round(ledX); ledY = round(ledY);
    plot(ledX, ledY, 'yo', 'MarkerSize', 4, 'LineWidth', 2);

    % Get pixelWindow x pixelWindow pixel region around the LED blink position
    ledRegion = [ledX - pixelHalfWindow, ledY - pixelHalfWindow, pixelWindow, pixelWindow];
    rectangle('Position', ledRegion, 'EdgeColor', 'y');
    hold off;

    % Collect initial timeWindow frames of region around LED blink
    video.CurrentTime = 0;
    ledFrames = zeros(pixelWindow+1, pixelWindow+1, timeWindow, 'uint8');
    for i = 1:timeWindow
        if hasFrame(video)
            frame = readFrame(video);
            ledFrames(:, :, i) = imcrop(frame(:, :, 2), ledRegion);
        else
            warning('Video has fewer than specified frames. Stopping early.');
            break;
        end
    end

    % Apply contrast filtering to detect LED blinks
    video.CurrentTime = 0;
    filteredFrames = zeros(pixelWindow+1, pixelWindow+1, timeWindow, 'uint8');
    for i = 1:timeWindow
        frame = ledFrames(:, :, i);
        minVal = double(min(frame(:)));
        maxVal = double(max(frame(:)));
        filteredFrames(:, :, i) = uint8(255 * (double(frame) - minVal) / (maxVal - minVal));
    end
    
    % Define the medium and small sub-regions for ratio calculation
    timeWindow = size(filteredFrames, 3);

    centerRow = pixelHalfWindow + 1;
    centerCol = pixelHalfWindow + 1;

    kernel11_half = floor(pixelHalfWindow/4);
    kernel21_half = floor(pixelHalfWindow/2);

    % Compute the ratio of the sum values of two sub-regions
    ratioValues = zeros(1, timeWindow);
    for i = 1:timeWindow
        frameROI = filteredFrames(:,:,i);
        
        % Smaller sub-region
        r1 = centerRow - kernel11_half : centerRow + kernel11_half;
        c1 = centerCol - kernel11_half : centerCol + kernel11_half;
        sub11 = frameROI(r1, c1);
        mean11 = sum(sub11(:));
        
        % Medium sub-region
        r2 = centerRow - kernel21_half : centerRow + kernel21_half;
        c2 = centerCol - kernel21_half : centerCol + kernel21_half;
        sub21 = frameROI(r2, c2);
        mean21 = sum(sub21(:)) - mean11;
        
        ratioValues(i) = mean11 / mean21;
    end

    if isVisualized
        ShowLedFramesAndRatio(filteredFrames, ratioValues);
    end

    %% Part 2-2: Dynamically Choose the frame with large ratio as the LED blink frame

    % Plot the ratio difference
    figure;
    plot(ratioValues, 'LineWidth', 1.5);
    hold on;
    xlabel('Frame #');
    ylabel('Ratio difference');
    title('Please click on the ratio value threshold for LED blink frame selection', 'Color', 'r');

    % Dynamically set threshold for LED blink frame selection
    disp('Click on the ratio value threshold for LED blink frame selection');
    [~, yThres] = ginput(1);
    yline(yThres, 'r--', 'Threshold');

    % Calculate frames with ratio above threshold
    ledOnLogical = ratioValues > yThres;
    ledOnFrames = find(diff(ledOnLogical) == 1);
    
    % Display the detected LED blink frames
    for i = 1:length(ledOnFrames)
        xline(ledOnFrames(i), 'g--');
    end

    % Dynamically choose the frame with the largest ratio as the LED blink frame
    disp('Click on the plot to select the LED blink frame');
    [xLed, ~] = ginput(1);
    [~, idxLed] = min(abs(ledOnFrames - xLed));
    syncFrame = ledOnFrames(idxLed);
    xline(syncFrame, 'b-', 'LED Blink Frame');
    
    %% Part 3: Save the reviewed data to a CSV file
    reviewedVideo{1, 1} = mouseName;
    reviewedVideo{1, 2} = mouseStatus;
    reviewedVideo{1, 3} = round(radius);
    reviewedVideo{1, 4} = syncFrame;

end

%% Helper function to compute the circumcircle (circle through 3 points).
function [cx, cy, R, isValid] = calcCircumcircle(x1, y1, x2, y2, x3, y3)
    % Calculate the denominator (2*determinant of the triangle)
    d = 2 * ( x1*(y2 - y3) + x2*(y3 - y1) + x3*(y1 - y2) );

    if abs(d) < 1e-12
        % Points are collinear or extremely close to collinear
        cx = NaN; cy = NaN; R = NaN; 
        isValid = false;
        return;
    end

    % Precompute squares
    x1_sq = x1^2 + y1^2;
    x2_sq = x2^2 + y2^2;
    x3_sq = x3^2 + y3^2;

    % Circumcenter (cx, cy)
    cx = ( x1_sq*(y2 - y3) + x2_sq*(y3 - y1) + x3_sq*(y1 - y2) ) / d;
    cy = ( x1_sq*(x3 - x2) + x2_sq*(x1 - x3) + x3_sq*(x2 - x1) ) / d;

    % Radius (distance from center to any of the 3 points)
    R = sqrt( (x1 - cx)^2 + (y1 - cy)^2 );

    isValid = true;
end

%% Helper function to display LED frames and ratio plot
function ShowLedFramesAndRatio(ledFrames, ratioValues)
    
    magnification = 10;

    nFrames = size(ledFrames, 3);
    fig = figure('Name', 'LED Frames & Ratio', 'NumberTitle', 'off', 'Units','Normalized', 'Position', [0.25 0.1 0.5 0.8]);

    % Subplot 1 for visualization of LED frames
    ax1 = subplot(2,1,1, 'Parent', fig);
    firstFrame = ledFrames(:,:,1);
    imgHandle = imshow(imresize(firstFrame, magnification, 'nearest'), 'Parent', ax1);
    title(ax1, 'Frame 1');
    
    % Subplot 2 for visualization of ratio values
    ax2 = subplot(2,1,2, 'Parent', fig);
    plot(ax2, ratioValues, 'LineWidth', 1.5);
    hold(ax2, 'on');
    xlineHandle = xline(ax2, 1, 'r--', 'Label', 'Frame = 1', 'LabelOrientation','horizontal');
    hold(ax2, 'off');
    xlabel(ax2, 'Frame #');
    ylabel(ax2, 'Ratio (11x11 / 21x21)');
    xlim(ax2, [1 nFrames]);
    
    % Create slider below (or you can place it elsewhere)
    sliderHandle = uicontrol('Parent', fig, 'Style', 'slider',...
                                'Min', 1, 'Max', nFrames, 'Value', 1,...
                                'SliderStep', [1/(nFrames-1), 10/(nFrames-1)],...
                                'Units', 'Normalized',...
                                'Position', [0.1 0.02 0.8 0.03]);
    
    % Ensure integer frames as you move the slider
    addlistener(sliderHandle, 'Value', 'PostSet', @(src,evnt) sliderCallback());
    
    % Nested callback to update image and xline
    function sliderCallback()
        currentFrame = round(get(sliderHandle, 'Value'));
        
        % Update the displayed image
        newImg = ledFrames(:,:,currentFrame);
        set(imgHandle, 'CData', imresize(newImg, magnification, 'nearest'));
        
        % Update xline in ratio plot
        xlineHandle.Value = currentFrame;
        xlineHandle.Label = sprintf('Frame = %d', currentFrame);
        
        % Update title in top subplot
        title(ax1, sprintf('Frame %d', currentFrame));
    end
end