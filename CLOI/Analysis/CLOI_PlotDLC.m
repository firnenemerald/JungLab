% Function to plot the trajectory of the mouse in the arena using DLC data

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function CLOI_PlotDLC(mouseName, mouseStatus, expType, dateTime, mousePart, defaultDir, frameBool, frameBool2)

    % Load the data while checking if frameBool is provided
    if nargin == 6
        dlcArray = CLOI_GetDLC(mouseName, mouseStatus, expType, dateTime, mousePart, defaultDir);
        
        % Plot DLC XY data
        figure;
        if strcmp(mouseStatus, 'Parkinson')
            plot(dlcArray(:, 2), dlcArray(:, 3), 'r-');
        else
            plot(dlcArray(:, 2), dlcArray(:, 3), 'b-');
        end
        xlabel('X');
        ylabel('Y');
        xlim([600 1300])
        ylim([200 800])
        title(strcat(mouseName, " mouse trajectory"), "Interpreter", "none");
        subtitle(strcat(mouseStatus, " ", expType, " ", dateTime), "Interpreter", "none");
        grid on;

    elseif nargin == 7
        dlcArray = CLOI_GetDLC(mouseName, mouseStatus, expType, dateTime, mousePart, defaultDir);
        dlcArray = dlcArray(frameBool, :);

        % Plot DLC XY data
        figure;
        if strcmp(mouseStatus, 'Parkinson')
            plot(dlcArray(:, 2), dlcArray(:, 3), 'r-');
        else
            plot(dlcArray(:, 2), dlcArray(:, 3), 'b-');
        end
        xlabel('X');
        ylabel('Y');
        xlim([600 1300])
        ylim([200 800])
        title(strcat(mouseName, " mouse trajectory"), "Interpreter", "none");
        subtitle(strcat(mouseStatus, " ", expType, " ", dateTime), "Interpreter", "none");
        grid on;

    elseif nargin == 8
        dlcArray = CLOI_GetDLC(mouseName, mouseStatus, expType, dateTime, mousePart, defaultDir);
        dlcArray1 = dlcArray(frameBool, :);
        dlcArray2 = dlcArray(frameBool2, :);

        % Find the indices where frameBool changes from 1 to 0 or 0 to 1
        changes1 = find(diff([0; frameBool; 0]));
        segments1 = reshape(changes1, 2, [])';

        % Separate dlcArray1 into segments
        dlcArray11 = dlcArray(segments1(1, 1):segments1(1, 2)-1, :);
        dlcArray12 = dlcArray(segments1(2, 1):segments1(2, 2)-1, :);
        dlcArray13 = dlcArray(segments1(3, 1):segments1(3, 2)-1, :);

        % Calculate movement distance
        dist11 = sqrt(diff(dlcArray11(:, 2)).^2 + diff(dlcArray11(:, 3)).^2);
        dist12 = sqrt(diff(dlcArray12(:, 2)).^2 + diff(dlcArray12(:, 3)).^2);
        dist13 = sqrt(diff(dlcArray13(:, 2)).^2 + diff(dlcArray13(:, 3)).^2);

        % Find the indices where frameBool2 changes from 1 to 0 or 0 to 1
        changes2 = find(diff([0; frameBool2; 0]));
        segments2 = reshape(changes2, 2, [])';

        % Separate dlcArray2 into segments
        dlcArray21 = dlcArray(segments2(1, 1):segments2(1, 2)-1, :);
        dlcArray22 = dlcArray(segments2(2, 1):segments2(2, 2)-1, :);
        dlcArray23 = dlcArray(segments2(3, 1):segments2(3, 2)-1, :);

        % Calculate movement distance
        dist21 = sqrt(diff(dlcArray21(:, 2)).^2 + diff(dlcArray21(:, 3)).^2);
        dist22 = sqrt(diff(dlcArray22(:, 2)).^2 + diff(dlcArray22(:, 3)).^2);
        dist23 = sqrt(diff(dlcArray23(:, 2)).^2 + diff(dlcArray23(:, 3)).^2);

        % Print the movement distance
        fprintf('%.2f,%.2f,%.2f,%.2f,%.2f,%.2f', sum(dist11), sum(dist21), sum(dist12), sum(dist22), sum(dist13), sum(dist23));

        % Plot DLC XY data
        figure;
        hold on;
        plt11 = plot(dlcArray11(:, 2), dlcArray11(:, 3), 'Color', '#211C84');
        plt12 = plot(dlcArray12(:, 2), dlcArray12(:, 3), 'Color', '#4D55CC');
        plt13 = plot(dlcArray13(:, 2), dlcArray13(:, 3), 'Color', '#B5A8D5');
        plt21 = plot(dlcArray21(:, 2), dlcArray21(:, 3), 'Color', '#AC1754');
        plt22 = plot(dlcArray22(:, 2), dlcArray22(:, 3), 'Color', '#E53888');
        plt23 = plot(dlcArray23(:, 2), dlcArray23(:, 3), 'Color', '#F7A8C4');
        % Only show the plt23 trajectory
        % plt11 = plot(dlcArray11(:, 2), dlcArray11(:, 3), 'Color', '#FFFFFF');
        % plt12 = plot(dlcArray12(:, 2), dlcArray12(:, 3), 'Color', '#FFFFFF');
        % plt13 = plot(dlcArray13(:, 2), dlcArray13(:, 3), 'Color', '#FFFFFF');
        % plt21 = plot(dlcArray21(:, 2), dlcArray21(:, 3), 'Color', '#FFFFFF');
        % plt22 = plot(dlcArray22(:, 2), dlcArray22(:, 3), 'Color', '#FFFFFF');
        % plt23 = plot(dlcArray23(:, 2), dlcArray23(:, 3), 'Color', '#F7A8C4');
        xlabel('X');
        ylabel('Y');
        xlim([600 1300])
        ylim([200 800])
        title(strcat(mouseName, " mouse trajectory, OFF vs ON"), "Interpreter", "none");
        subtitle(strcat(mouseStatus, " ", expType, " ", dateTime), "Interpreter", "none");
        legend([plt11, plt12, plt13, plt21, plt22, plt23], {'OFF1', 'OFF2', 'OFF3', 'ON1', 'ON2', 'ON3'}, 'Location', 'best');
        grid on;
        axis equal;
        hold off;

    else
        error("Invalid number of arguments. Provide 6, 7, or 8 arguments.");
    end

    
end