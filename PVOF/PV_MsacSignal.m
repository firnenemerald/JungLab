%% PV_MsacSignal.m
% Detect photobleaching trend by M-estimator sample consensus (MSAC) method
% Correct by regression data and return corrected signal

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

function signal_corrected = PV_MsacSignal(time, signal, sampleSize, maxDistance)
    % Prepare data for fitting
    x = time(:);
    y = signal(:);
    useind = ~isnan(x) & ~isnan(y);
    ux = x(useind);
    uy = y(useind);
    
    % Add scaling factor to make the log curve more linear
    a = 0.02;  % Smaller value = more linear. Try values between 0.01 to 1s
    
    %% Define the fitting function
    fitLogFcn = @(points) fitLog(points, a);
    % Define the distance function
    distLineFcn = @(model, points) distLog(model, points, a);
    
    %% Fit using MSAC
    [modelMSAC, inliers] = ransac([ux, uy], fitLogFcn, distLineFcn, sampleSize, maxDistance);
    
    %% Get fitted curve
    y_fit = modelMSAC(1)*log(a*ux + 1) + modelMSAC(2);
    ty_fit = NaN(size(signal));
    ty_fit(useind) = y_fit;
    
    % Plot results
    % figure;
    % plot(x, y, 'b.', 'DisplayName', 'Original Data');
    % hold on;
    % plot(x(inliers), y(inliers), 'g.', 'DisplayName', 'Inliers');
    % plot(x, y_fit, 'r-', 'LineWidth', 2, 'DisplayName', 'Log Fit');
    % legend('show');
    % xlabel('Time');
    % ylabel('Signal');
    % title(['MSAC Fitting (y = a*log(' num2str(a) '*x+1) + b)']);
    % grid on;
    
    % Correct signal
    signal_corrected = signal - ty_fit;
end

function model = fitLog(points, a)
    x = points(:,1);
    y = points(:,2);
    A = [log(a*x + 1), ones(size(x))];
    model = A \ y;
end

function model = fitlin(points, a)
    x = points(:,1);
    y = points(:,2);
    A = [log(a*x + 1), ones(size(x))];
    model = A \ y;
end

function distances = distLog(model, points, a)
    x = points(:,1);
    y = points(:,2);
    y_fit = model(1)*log(a*x + 1) + model(2);
    distances = abs(y - y_fit);
end