function [centerX, centerY, radius, isConfirmed] = CLOI_GetCircleFromUser(img)

% Initialize output variables to default/empty values
centerX = NaN;
centerY = NaN;
radius = NaN;
isConfirmed = false;

% Create a figure for interaction
fig = figure;
imshow(img);
hold on;
title('Click 3 points on the circle''s edge');

while true
    x = zeros(1, 3);
    y = zeros(1, 3);
    h_points = gobjects(1, 3); % Handles to plotted points
    
    for i = 1:3
        [x(i), y(i)] = ginput(1);
        % Check if ginput was cancelled (e.g., figure closed)
        if isempty(x(i))
            close(fig);
            return; % Exit function
        end
        h_points(i) = plot(x(i), y(i), 'rx', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
        fprintf('Point %d: (%.2f, %.2f)\n', i, x(i), y(i));
    end
    
    x1 = x(1); y1 = y(1);
    x2 = x(2); y2 = y(2);
    x3 = x(3); y3 = y(3);
    D = 2 * (x1*(y2 - y3) + x2*(y3 - y1) + x3*(y1 - y2));
    
    % Check for collinear points
    if abs(D) < 1e-10
        warndlg('Points are collinear. Please select three different points.', 'Input Error');
        cla; % Clear axes to reset
        imshow(img);
        title('Collinear points selected. Try again.');
        continue; % Restart the while loop
    end
    
    ux = ((x1^2 + y1^2)*(y2 - y3) + (x2^2 + y2^2)*(y3 - y1) + (x3^2 + y3^2)*(y1 - y2)) / D;
    uy = ((x1^2 + y1^2)*(x3 - x2) + (x2^2 + y2^2)*(x1 - x3) + (x3^2 + y3^2)*(x2 - x1)) / D;
    r = sqrt((x1 - ux)^2 + (y1 - uy)^2);
    
    fprintf('Circle center: (%.2f, %.2f), Radius: %.2f\n', ux, uy, r);
    
    theta = linspace(0, 2*pi, 100);
    h_circle = plot(ux + r * cos(theta), uy + r * sin(theta), 'r-', 'LineWidth', 1);
    h_center = plot(ux, uy, 'g+', 'MarkerSize', 6, 'LineWidth', 1);
    
    answer = questdlg('Is this circle correct?', 'Confirm Selection', 'Yes', 'No', 'Yes');
    
    switch answer
        case 'Yes'
            isConfirmed = true;
            centerX = ux;
            centerY = uy;
            radius = r;
            close(fig); % Close the figure window
            return; % Exit the function
        case 'No'
            % Clear the drawn circle, center, and points for the next attempt
            delete([h_circle, h_center, h_points]);
            title('Selection rejected. Please try again.');
        otherwise % User closed the dialog or pressed escape
            isConfirmed = false;
            close(fig); % Close the figure window
            return; % Exit the function
    end
end

end