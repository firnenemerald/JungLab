video_path = "D:\CLOI_data\ChAT_946-1\ChAT_946-1_Baseline_CLOI_250228_133749\ChAT_946-1_Baseline_CLOI_250228_133749_cropped.mp4";
v = VideoReader(video_path);
frameNumber = 100;
v.CurrentTime = (frameNumber - 1) / v.FrameRate;
img = readFrame(v);
figure;
imshow(img);
title(sprintf('Frame %d', frameNumber));

% Let user pick three points on the image
disp('Please select three points on the image to define a circle.');
[x, y] = ginput(3);

% Calculate the circle passing through the three points
% The points are (x1,y1), (x2,y2), (x3,y3)
x1 = x(1); y1 = y(1);
x2 = x(2); y2 = y(2);
x3 = x(3); y3 = y(3);

% Calculate the perpendicular bisectors of (x1,y1)-(x2,y2) and (x2,y2)-(x3,y3)
A = [2*(x2-x1), 2*(y2-y1); 2*(x3-x2), 2*(y3-y2)];
b = [(x2^2 + y2^2) - (x1^2 + y1^2); (x3^2 + y3^2) - (x2^2 + y2^2)];

center = A\b;
xc = center(1);
yc = center(2);

% Calculate radius and diameter
r = sqrt((xc-x1)^2 + (yc-y1)^2);
diameter = 2*r;

% Plot the circle and points
hold on;
plot(x, y, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
theta = linspace(0, 2*pi, 200);
plot(xc + r*cos(theta), yc + r*sin(theta), 'g-', 'LineWidth', 2);
plot(xc, yc, 'bx', 'MarkerSize', 12, 'LineWidth', 2);
hold off;

% Display the diameter
disp(['Diameter of the circle: ', num2str(diameter)]);
title(sprintf('Frame %d (Diameter: %.2f px)', frameNumber, diameter));