function [centerMazeTimeMS, centerMazeDistanceMS] = CLOI_CenterMaze_MS(headPosDLC, minisessionIdx, boolDownFrameMS, CENTER, RADIUS, ratio)

headPosMS = headPosDLC(boolDownFrameMS{minisessionIdx}, :);
distanceMS = sqrt((headPosMS(:, 1) - CENTER(1)).^2 + (headPosMS(:, 2) - CENTER(2)).^2); % Calculate distance from center

% Calculate center maze time
centerMazeTimeMS = sum(distanceMS < RADIUS * ratio)/length(distanceMS) * 120; % Convert to seconds
% Calculate center maze travel distance (before smoothing)
% centerMazeDistanceMS = sum(distanceMS(distanceMS < RADIUS * ratio)); % Total distance traveled in center maze area

% Smooth the 2D position
windowSize = 4;  % Adjust window size as needed
smoothedHeadPosMS = zeros(size(headPosMS));
smoothedHeadPosMS(:,1) = movmean(headPosMS(:,1), windowSize, 'omitnan');
smoothedHeadPosMS(:,2) = movmean(headPosMS(:,2), windowSize, 'omitnan');

% Calculate velocity between frames (Euclidean distance)
velocity = sqrt(diff(smoothedHeadPosMS(:,1)).^2 + diff(smoothedHeadPosMS(:,2)).^2);

% Calculate total distance traveled in center maze area
inCenterMaze = distanceMS < RADIUS * ratio;
inCenterMazeVelocity = velocity(1:end) .* inCenterMaze(2:end);  % Only count distance when in center maze
centerMazeDistanceMS = sum(inCenterMazeVelocity, 'omitnan');    % Sum all displacements in center maze

end