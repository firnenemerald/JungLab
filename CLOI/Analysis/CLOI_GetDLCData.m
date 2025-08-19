%% Function to get the DeepLabCut (DLC) data of specified session with data cleaning

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function [dlcTime, dlcCoordX, dlcCoordY, dlcCoordConf, cleaningStats] = CLOI_GetDLCData(DLCDir, mousePart, varargin)
%CLOI_GetDLCData Get and clean DeepLabCut tracking data
%
% Inputs:
%   DLCDir - Path to DLC CSV file
%   mousePart - 'head', 'center', or 'tail'
%   Optional name-value pairs:
%     'MazeCenter' - [x, y] coordinates of maze center (default: auto-detect)
%     'MazeRadius' - Radius of maze in pixels (default: auto-detect)
%     'CleanData' - Boolean to enable data cleaning (default: true)
%     'ConfidenceThreshold' - Minimum confidence threshold (default: 0.5)
%     'RadiusExpansion' - Factor to expand maze radius (default: 1.1)
%     'VelocityPercentile' - Percentile for velocity outlier detection (default: 99)
%
% Outputs:
%   dlcTime - Frame time vector
%   dlcCoordX - Cleaned X coordinates
%   dlcCoordY - Cleaned Y coordinates  
%   dlcCoordConf - Original confidence scores
%   cleaningStats - Structure with cleaning statistics

    % Parse input arguments
    p = inputParser;
    addRequired(p, 'DLCDir', @(x) ischar(x) || isstring(x));
    addRequired(p, 'mousePart', @(x) ischar(x) || isstring(x));
    addParameter(p, 'MazeCenter', [], @(x) isnumeric(x) && length(x) == 2);
    addParameter(p, 'MazeRadius', [], @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'CleanData', true, @islogical);
    addParameter(p, 'ConfidenceThreshold', 0.5, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
    addParameter(p, 'RadiusExpansion', 1.1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'VelocityPercentile', 99, @(x) isnumeric(x) && isscalar(x) && x > 0 && x <= 100);
    
    parse(p, DLCDir, mousePart, varargin{:});
    
    % Convert inputs to character arrays for consistency
    DLCDir = char(p.Results.DLCDir);
    mousePart = char(p.Results.mousePart);
    
    mazeCenter = p.Results.MazeCenter;
    mazeRadius = p.Results.MazeRadius;
    cleanData = p.Results.CleanData;
    confidenceThreshold = p.Results.ConfidenceThreshold;
    radiusExpansion = p.Results.RadiusExpansion;
    velocityPercentile = p.Results.VelocityPercentile;

    % Read the csv file and extract coordinate data
    if ~isfile(DLCDir)
        error('DLC file not found: %s', DLCDir);
    end
    
    dlcArray = table2array(readtable(DLCDir, "VariableNamingRule", "preserve"));
    dlcTime = dlcArray(:, 1); % Time column
    dlcHead = dlcArray(:, 2:4); % Head coordinates
    dlcCent = dlcArray(:, 5:7); % Center coordinates
    dlcTail = dlcArray(:, 8:10); % Tail coordinates

    % Extract the DLC coordinate data for the specified mouse part
    switch mousePart
        case 'head'
            dlcCoordX_raw = dlcHead(:, 1); % X coordinate of head
            dlcCoordY_raw = dlcHead(:, 2); % Y coordinate of head
            dlcCoordConf = dlcHead(:, 3); % Confidence of head coordinates
        case 'center'
            dlcCoordX_raw = dlcCent(:, 1); % X coordinate of center
            dlcCoordY_raw = dlcCent(:, 2); % Y coordinate of center
            dlcCoordConf = dlcCent(:, 3); % Confidence of center coordinates
        case 'tail'
            dlcCoordX_raw = dlcTail(:, 1); % X coordinate of tail
            dlcCoordY_raw = dlcTail(:, 2); % Y coordinate of tail
            dlcCoordConf = dlcTail(:, 3); % Confidence of tail coordinates
        otherwise
            error('Invalid mouse part specified. Please specify either ''head'', ''center'', or ''tail''.');
    end
    
    % Initialize cleaning statistics
    cleaningStats = struct();
    cleaningStats.totalFrames = length(dlcTime);
    cleaningStats.mousePart = mousePart;
    cleaningStats.originalFile = DLCDir;
    
    % If cleaning is disabled, return raw data
    if ~cleanData
        dlcCoordX = dlcCoordX_raw;
        dlcCoordY = dlcCoordY_raw;
        cleaningStats.cleaningApplied = false;
        cleaningStats.problematicFrames = 0;
        cleaningStats.interpolatedFrames = 0;
        cleaningStats.outsideOriginal = 0;
        cleaningStats.outsideCleaned = 0;
        return;
    end
    
    % Auto-detect maze parameters if not provided
    if isempty(mazeCenter) || isempty(mazeRadius)
        [mazeCenter, mazeRadius] = autoDetectMazeParameters(dlcCoordX_raw, dlcCoordY_raw, dlcCoordConf, confidenceThreshold);
    end
    
    % Apply radius expansion for more lenient boundary detection
    mazeRadiusExpanded = mazeRadius * radiusExpansion;
    
    % Perform data cleaning
    [dlcCoordX, dlcCoordY, cleaningStats] = cleanDLCData(dlcTime, dlcCoordX_raw, dlcCoordY_raw, dlcCoordConf, ...
        mazeCenter, mazeRadiusExpanded, confidenceThreshold, velocityPercentile, cleaningStats);
    
end

function [mazeCenter, mazeRadius] = autoDetectMazeParameters(coordX, coordY, confidence, confThreshold)
%AUTODETECTMAZEPARAMETERS Automatically detect maze center and radius from tracking data
    
    % Use high-confidence points for estimation
    validIdx = confidence > confThreshold & ~isnan(coordX) & ~isnan(coordY);
    
    if sum(validIdx) < 10
        % Not enough valid points, use defaults
        mazeCenter = [median(coordX, 'omitnan'), median(coordY, 'omitnan')];
        mazeRadius = 200; % Default radius
        warning('Insufficient valid tracking points for maze detection. Using defaults.');
        return;
    end
    
    validX = coordX(validIdx);
    validY = coordY(validIdx);
    
    % Estimate center as median of valid coordinates
    mazeCenter = [median(validX), median(validY)];
    
    % Estimate radius as distance containing ~95% of points
    distances = sqrt((validX - mazeCenter(1)).^2 + (validY - mazeCenter(2)).^2);
    mazeRadius = prctile(distances, 95) * 1.1; % Add 10% margin
    
end

function [cleanX, cleanY, stats] = cleanDLCData(timeVec, rawX, rawY, confidence, mazeCenter, mazeRadiusExp, confThresh, velPercentile, stats)
%CLEANDLCDATA Apply comprehensive data cleaning to DLC coordinates
    
    % Calculate initial distances from maze center
    distances = sqrt((rawX - mazeCenter(1)).^2 + (rawY - mazeCenter(2)).^2);
    
    % Calculate velocity-based outliers
    velocity = sqrt(diff(rawX).^2 + diff(rawY).^2);
    velocityThreshold = prctile(velocity, velPercentile);
    
    % Identify different types of problematic frames
    distanceOutliers = distances > (mazeRadiusExp * 2); % Very far from maze
    velocityOutliers = [false; velocity > velocityThreshold]; % Large jumps
    lowConfidenceFrames = confidence < confThresh; % Low confidence
    
    % Combined problematic frames
    problematicFrames = distanceOutliers | velocityOutliers | lowConfidenceFrames;
    
    % Create cleaned data copies and mark problematic points as NaN
    cleanX_temp = rawX;
    cleanY_temp = rawY;
    cleanX_temp(problematicFrames) = NaN;
    cleanY_temp(problematicFrames) = NaN;
    
    % Perform spatially-constrained interpolation
    validFrames = ~isnan(cleanX_temp);
    
    if sum(validFrames) > 2
        % Linear interpolation for missing values (no extrapolation)
        cleanX = interp1(timeVec(validFrames), cleanX_temp(validFrames), timeVec, 'linear');
        cleanY = interp1(timeVec(validFrames), cleanY_temp(validFrames), timeVec, 'linear');
        
        % Apply spatial constraints: ensure interpolated points stay within maze
        interpolatedFrames = isnan(cleanX_temp) & ~isnan(cleanX);
        for i = 1:length(timeVec)
            if interpolatedFrames(i)
                interpDist = sqrt((cleanX(i) - mazeCenter(1))^2 + (cleanY(i) - mazeCenter(2))^2);
                
                if interpDist > mazeRadiusExp
                    % Project back onto maze boundary
                    angle = atan2(cleanY(i) - mazeCenter(2), cleanX(i) - mazeCenter(1));
                    cleanX(i) = mazeCenter(1) + mazeRadiusExp * 0.95 * cos(angle);
                    cleanY(i) = mazeCenter(2) + mazeRadiusExp * 0.95 * sin(angle);
                end
            end
        end
        
        % Handle remaining NaN values with nearest neighbor
        nanIndices = isnan(cleanX);
        if any(nanIndices)
            cleanX(nanIndices) = interp1(find(~nanIndices), cleanX(~nanIndices), find(nanIndices), 'nearest', 'extrap');
            cleanY(nanIndices) = interp1(find(~nanIndices), cleanY(~nanIndices), find(nanIndices), 'nearest', 'extrap');
        end
        
    else
        % Too few valid points - return original data with warning
        cleanX = rawX;
        cleanY = rawY;
        warning('Too few valid points for interpolation. Returning original data.');
    end
    
    % Calculate cleaning statistics
    cleanedDistances = sqrt((cleanX - mazeCenter(1)).^2 + (cleanY - mazeCenter(2)).^2);
    
    stats.cleaningApplied = true;
    stats.mazeCenter = mazeCenter;
    stats.mazeRadius = mazeRadiusExp / 1.1; % Original radius
    stats.mazeRadiusExpanded = mazeRadiusExp;
    stats.confidenceThreshold = confThresh;
    stats.velocityThreshold = velocityThreshold;
    
    stats.problematicFrames = sum(problematicFrames);
    stats.distanceOutliers = sum(distanceOutliers);
    stats.velocityOutliers = sum(velocityOutliers);
    stats.lowConfidenceFrames = sum(lowConfidenceFrames);
    stats.interpolatedFrames = sum(isnan(cleanX_temp) & ~isnan(cleanX));
    
    stats.outsideOriginal = sum(distances > mazeRadiusExp);
    stats.outsideCleaned = sum(cleanedDistances > mazeRadiusExp);
    
    stats.outsideOriginalPercent = stats.outsideOriginal / length(distances) * 100;
    stats.outsideCleanedPercent = stats.outsideCleaned / length(cleanedDistances) * 100;
    stats.improvementPercent = (stats.outsideOriginal - stats.outsideCleaned) / length(distances) * 100;
    
end