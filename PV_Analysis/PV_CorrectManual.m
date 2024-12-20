%% PV_CorrectManual.m
% Manually correct PV signal artifacts and return the corrected signal

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

function signal_corrected = PV_CorrectManual(signal)
    % Create figure for manual correction
    fig = figure;
    
    % Instructions
    disp('Manual Correction Instructions:');
    disp('1. Use mousewheel to zoom in/out');
    disp('2. Click and drag to create a box around the region to correct');
    disp('3. Press Enter to apply correction');
    disp('4. Press q to finish corrections');
    
    signal_corrected = signal;
    quit_flag = false;
    
    % Enable zoom with mousewheel after figure is ready
    set(fig, 'WindowScrollWheelFcn', @(~,callbackdata) mouseWheelZoom(callbackdata));
    
    while ~quit_flag
        % Plot current state
        clf;
        plot(signal, 'b-', 'DisplayName', 'Original');
        hold on;
        plot(signal_corrected, 'r-', 'DisplayName', 'Corrected');
        legend('show');
        title('Manual Signal Correction');
        xlabel('Time Points');
        ylabel('Signal');
        
        % Wait for mouse click or keyboard input
        [x1, y1, button] = ginput(1);
        
        % Check if keyboard input
        if isempty(x1) || button > 1
            key = get(gcf, 'CurrentCharacter');
            if key == 'q'
                quit_flag = true;
            end
            continue;
        end
        
        % Create rubber band box
        point1 = get(gca, 'CurrentPoint');
        rbbox;
        point2 = get(gca, 'CurrentPoint');
        
        % Get x coordinates from the box
        start_idx = round(min(point1(1,1), point2(1,1)));
        end_idx = round(max(point1(1,1), point2(1,1)));
        
        % Ensure indices are within bounds
        start_idx = max(1, start_idx);
        end_idx = min(length(signal), end_idx);
        
        % Create corrected signal
        y_corrected = signal_corrected;
        value_at_start = signal_corrected(start_idx);
        
        % Flatten the interval [a,b] to f(a)
        y_corrected(start_idx:end_idx) = value_at_start;
        
        % Shift all points after b by f(a) - f(b)
        shift = value_at_start - signal_corrected(end_idx);
        y_corrected(end_idx+1:end) = signal_corrected(end_idx+1:end) + shift;
        
        % Preview the correction
        plot(y_corrected, 'g-', 'LineWidth', 2, 'DisplayName', 'Preview');
        legend('show');
        
        % Wait for confirmation
        k = waitforbuttonpress;
        if k
            key = get(gcf, 'CurrentCharacter');
            if key == 'q'
                quit_flag = true;
            elseif key == char(13)  % Enter key
                % Apply correction
                signal_corrected = y_corrected;
            end
        end
    end
    
    close(fig);
end

function mouseWheelZoom(callbackdata)
    % Get the current axis
    ax = gca;
    
    % Get the current x limits
    xlim = get(ax, 'XLim');
    
    % Get the current cursor point
    point = ax.CurrentPoint(1,1);
    
    % Calculate zoom factor based on scroll direction
    if callbackdata.VerticalScrollCount > 0
        factor = 1.1; % Zoom out
    else
        factor = 0.9; % Zoom in
    end
    
    % Calculate new limits
    range = diff(xlim);
    new_range = range * factor;
    center = point;
    
    new_min = center - new_range/2;
    new_max = center + new_range/2;
    
    % Set new limits
    set(ax, 'XLim', [new_min new_max]);
end