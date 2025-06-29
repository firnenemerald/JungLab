function [centerMazeTimeMS, centerMazeDistanceMS] = CLOI_CenterMaze_MS(bodyPosDLC, minisessionIdx, boolDownFrameMS, CENTER, RADIUS, ratio)

bodyPosMS = bodyPosDLC(boolDownFrameMS{minisessionIdx}, :);
distanceMS = sqrt((bodyPosMS(:, 1) - CENTER(1)).^2 + (bodyPosMS(:, 2) - CENTER(2)).^2); % Calculate distance from center

% Calculate center maze time
centerMazeTimeMS = sum(distanceMS < RADIUS * ratio)/length(distanceMS) * 120; % Convert to seconds
% Calculate center maze travel distance
centerMazeDistanceMS = sum(distanceMS(distanceMS < RADIUS * ratio)); % Total distance traveled in center maze area

end