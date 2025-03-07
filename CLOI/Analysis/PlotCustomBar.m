%% PlotCustomBar.m (ver 1.0.240828)
% Plot custom bar graph to visualize data

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

function [] = PlotCustomBar(var1, var2, varargin)
    % PlotCustomBar - Plots a custom bar graph to visualize data
    %
    % Inputs:
    %   var1 - First variable (data for bar 1)
    %   var2 - Second variable (data for bar 2)
    %   varargin - Optional name-value pairs:
    %       'XLabel' - Label for x-axis
    %       'YLabel' - Label for y-axis
    %       'Title' - Plot title

    % Parse optional inputs
    inputParserObj = inputParser; % Create input parser object
    addParameter(inputParserObj, 'XLabel', ''); % Default empty label
    addParameter(inputParserObj, 'YLabel', ''); % Default empty label
    addParameter(inputParserObj, 'Title', ''); % Default empty title
    addParameter(inputParserObj, 'Group1', ''); % Default group 1 to compare
    addParameter(inputParserObj, 'Group2', ''); % Default group 2 to compare
    parse(inputParserObj, varargin{:}); % Parse the input arguments

    figure;
    hold on;

    mean1 = mean(var1); 
    se1 = std(var1) / sqrt(length(var1));
    mean2 = mean(var2); 
    se2 = std(var2) / sqrt(length(var2));

    % Perform paired t-test to compare the two groups
    [~, p] = ttest(var1, var2);

    if ~isempty(inputParserObj.Results.Group1)
        g1 = inputParserObj.Results.Group1;
    end
    if ~isempty(inputParserObj.Results.Group2)
        g2 = inputParserObj.Results.Group2;
    end

    bar_groups = {g1, g2};
    bar_means = [mean1, mean2];
    bar_ses = [se1, se2];

    barX = categorical(bar_groups);
    barX = reordercats(barX, bar_groups);
    bar(barX, bar_means, 'EdgeColor', 'black', 'FaceAlpha', 0.5);
    errorbar(barX, bar_means, bar_ses, 'LineStyle', 'none', 'LineWidth', 2, 'Color', 'black');

    scatter(ones(size(var1)) * find(barX == g1), var1, 15, 'o', 'MarkerEdgeColor', 'blue', 'jitter', 'on', 'jitterAmount', 0.15);
    scatter(ones(size(var2)) * find(barX == g2), var2, 15, 'o', 'MarkerEdgeColor', 'red', 'jitter', 'on', 'jitterAmount', 0.15);

    % Set labels and title if provided
    if ~isempty(inputParserObj.Results.XLabel)
        xlabel(inputParserObj.Results.XLabel, "Interpreter", "none");
    end
    if ~isempty(inputParserObj.Results.YLabel)
        ylabel(inputParserObj.Results.YLabel, "Interpreter", "none");
    end
    if ~isempty(inputParserObj.Results.Title)
        title(inputParserObj.Results.Title, "Interpreter", "none");
    end

    % Display p-value on the plot
    pValueText = sprintf('p = %.3f', p); % Format p-value to 3 decimal places
    text(1.5, max([var1; var2]), pValueText, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontSize', 12, 'Color', 'k');

    grid on;
    hold off;
end