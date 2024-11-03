function [smoothed_x, smoothed_y] = fn_KalmanFilter(positions, confidences, dt, q, r_base, R_min)
    % applies a Kalman filter to 2D position data
    % with hybrid measurement noise covariance based on confidence scores.
    %
    % Inputs:
    % - positions: Nx2 matrix of observed positions [x, y]
    % - confidences: Nx1 vector of confidence scores (between 0 and 1)
    % - dt: time step between measurements
    % - q: process noise covariance scalar
    % - r_base: base measurement noise covariance scalar
    % - R_min: minimum measurement noise covariance scalar
    %
    % Outputs:
    % - smoothed_x: Nx1 vector of smoothed x positions
    % - smoothed_y: Nx1 vector of smoothed y positions

    % Number of measurements
    numPoints = size(positions, 1);
    
    % State Transition Matrix (Assuming constant velocity model)
    A = [1 dt 0  0;
         0  1 0  0;
         0  0 1 dt;
         0  0 0  1];

    % Observation Matrix (We only observe positions)
    H = [1 0 0 0;
         0 0 1 0];

    % Process Noise Covariance
    Q = q * eye(4);

    % Allocate space for state estimates
    x_estimates = zeros(4, numPoints);

    % Initial State Estimate (Starting from the first observed position)
    x_est = [positions(1, 1); 0; positions(1, 2); 0];

    % Initial Covariance Estimate
    P_est = eye(4);

    x_estimates(:, 1) = x_est;

    for k = 2:numPoints
        % Prediction Step
        x_pred = A * x_est;
        P_pred = A * P_est * A' + Q;

        % Measurement
        z = [positions(k, 1); positions(k, 2)];

        % Confidence Score for the current frame (ensure it's between 0 and 1)
        conf = confidences(k);
        conf = min(max(conf, 0), 1); % Clamp between 0 and 1

        % Dynamic Measurement Noise Covariance with Minimum R
        R_current = max((1 - conf) * r_base, R_min) * eye(2);

        % Kalman Gain
        K = P_pred * H' / (H * P_pred * H' + R_current);

        % Update Step
        x_est = x_pred + K * (z - H * x_pred);
        P_est = (eye(4) - K * H) * P_pred;

        % Save the estimate
        x_estimates(:, k) = x_est;
    end

    % Extract the smoothed coordinates
    smoothed_x = x_estimates(1, :)';
    smoothed_y = x_estimates(3, :)';
end