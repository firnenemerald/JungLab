%% PV_CorrectSignal.m
% Correct PV signal artifacts and return the corrected signal

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

function signal_corrected = PV_CorrectSignal(signal, windowSize, steepZCutoff, clusterSize, paddingSize)

    % clusterSize should be larger than 2 x paddingSize to avoid merger of clusters - if not, raise an error
    if (clusterSize <= 2 * paddingSize)
        msg = "clusterSize should be larger than 2 x paddingSize to avoid merger of clusters";
        error(msg);
    end
    
    %% Calculate rolling max and min and detect indices of steep change
    % Note: movmax, movmin conserves array size
    rolling_max = movmax(signal, windowSize);
    rolling_min = movmin(signal, windowSize);
    
    % Calculate and plot the steepness
    steepness = (rolling_max - rolling_min)/windowSize;
    steepnessZ = normalize(steepness);
    
    figure;
    plot(steepnessZ, 'b-', 'DisplayName', 'Steepness');
    hold on;
    yline(steepZCutoff, 'r--', 'DisplayName', 'Cutoff');
    xlabel('Time Point');
    ylabel('Steepness (Change/Window)');
    title('Signal Steepness Analysis');
    legend('show');
    grid on;

    steep_idx = find(steepnessZ > steepZCutoff);

    %% If no steep changes are found, just return the original signal
    if isempty(steep_idx)
        signal_corrected = signal;
        return
    end

    %% If only one steep change is found, there is only one cluster
    if isscalar(steep_idx)
        start_idx = max(1, steep_idx - paddingSize);
        end_idx = min(length(signal), steep_idx + paddingSize);
        correction = signal(start_idx) - signal(end_idx);
        signal(start_idx:end_idx) = signal(start_idx);
        signal(end_idx+1:end) = signal(end_idx+1:end) + correction;
    end

    %% If two or more steep changes are found, collect clusters of steep changes
    clusters = {};
    current_cluster = steep_idx(1);
    for i = 2:length(steep_idx)
        % If indices are close together, append index to current cluster
        if steep_idx(i) - current_cluster(end) <= clusterSize
            current_cluster(end + 1) = steep_idx(i);
        % If indices are far apart, append current cluster to clusters and make new current cluster
        else
            clusters{end + 1} = current_cluster;
            current_cluster = steep_idx(i);
        end
    end
    % Append last current cluster to clusters
    clusters{end + 1} = current_cluster;

    %% Get intervals to correct by adding paddings to each cluster
    correct_intervals = cell(size(clusters));
    for j = 1:length(clusters)
        cluster = clusters{j};
        start_idx = max(1, cluster(1) - paddingSize);
        end_idx = min(length(signal), cluster(end) + paddingSize);
        correct_intervals{j} = [start_idx, end_idx];
    end

    %% Correct signals by flattening within intervals to correct
    signal_corrected = signal;
    for k = 1:length(correct_intervals)
        interval = correct_intervals{k};
        start_idx = interval(1);
        end_idx = interval(2);
        % If interval to correct is close to end of signal, just flatten
        if (abs(length(signal)-end_idx) < clusterSize)
            signal_corrected(start_idx:end) = signal_corrected(start_idx);
        else % Flatten signal and parallel displacement of rest of signal
            signal_corrected(start_idx:end_idx) = signal_corrected(start_idx);
            signal_corrected(end_idx+1:end) = signal_corrected(end_idx+1:end) + (signal(start_idx) - signal(end_idx));
        end
    end
    sprintf("A total of %d intervals corrected", length(correct_intervals));
end