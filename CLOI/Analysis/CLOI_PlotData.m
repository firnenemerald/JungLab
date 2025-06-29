function CLOI_PlotData(analysisData, plotIndices, plotVar, plotType)
    switch plotType
        case 'onoff'
            plotOnOffComparison(analysisData, plotIndices, plotVar);
        case 'bargraph'
            plotBarGraph(analysisData, plotIndices, plotVar);
    end
end

function plotOnOffComparison(analysisData, plotIndices, plotVar)
    % Constants
    NUM_MICE = 4;
    COLORS = {'b', 'g', 'm', 'c'};
    SESSION_NAMES = ["ChAT 946-2", "ChAT 947-2", "ChAT 947-3", "ChAT 967-2"];
    GROUP_LABELS = {'Base CLOI', 'Base RAND', 'Park CLOI', 'Park RAND'};
    
    numGroups = size(plotIndices, 2);
    
    % Initialize figure
    figure; 
    hold on;
    
    % Extract and combine data for all groups
    combinedData = extractCombinedData(analysisData, plotIndices, plotVar, numGroups);
    
    % Plot data points and error bars
    plotDataWithErrorBars(combinedData, numGroups, NUM_MICE, COLORS);
    
    % Connect ON/OFF points with lines
    plotConnectingLines(combinedData, numGroups, NUM_MICE, COLORS);
    
    % Create and display legend
    createLegend(COLORS, SESSION_NAMES);
    
    % Set plot properties
    setPlotProperties(plotVar, numGroups, GROUP_LABELS);
    
    hold off;
end

function combinedData = extractCombinedData(analysisData, plotIndices, plotVar, numGroups)
    combinedData = cell(numGroups, 2); % Column 1: OFF data, Column 2: ON data
    
    for i = 1:numGroups
        for j = 1:length(plotIndices{i})
            idx = plotIndices{i}(j);
            
            % Extract OFF data (indices 1, 3, 5)
            offData = [analysisData(idx).(plotVar){1}; 
                      analysisData(idx).(plotVar){3}; 
                      analysisData(idx).(plotVar){5}];
            
            % Extract ON data (indices 2, 4, 6)
            onData = [analysisData(idx).(plotVar){2}; 
                     analysisData(idx).(plotVar){4}; 
                     analysisData(idx).(plotVar){6}];
            
            combinedData{i, 1} = [combinedData{i, 1}; offData];
            combinedData{i, 2} = [combinedData{i, 2}; onData];
        end
    end
end

function plotDataWithErrorBars(combinedData, numGroups, numMice, colors)
    X_OFFSET = 0.2;
    
    for groupIdx = 1:numGroups
        offData = combinedData{groupIdx, 1};
        onData = combinedData{groupIdx, 2};
        
        for mouseIdx = 1:numMice
            % Extract data for specific mouse
            [mouseOffData, mouseOnData] = extractMouseData(offData, onData, mouseIdx, numMice);
            
            % Calculate statistics
            [meanOff, meanOn, semOff, semOn] = calculateStatistics(mouseOffData, mouseOnData);
            
            % Plot scatter points
            scatter(groupIdx - X_OFFSET, meanOff, 10, 'filled', 'MarkerFaceColor', colors{mouseIdx});
            scatter(groupIdx + X_OFFSET, meanOn, 10, 'filled', 'MarkerFaceColor', colors{mouseIdx});
            
            % Plot error bars
            errorbar(groupIdx - X_OFFSET, meanOff, semOff, 'k', 'LineStyle', 'none', 'LineWidth', 1.0);
            errorbar(groupIdx + X_OFFSET, meanOn, semOn, 'k', 'LineStyle', 'none', 'LineWidth', 1.0);
        end
    end
end

function plotConnectingLines(combinedData, numGroups, numMice, colors)
    X_OFFSET = 0.2;
    
    for groupIdx = 1:numGroups
        offData = combinedData{groupIdx, 1};
        onData = combinedData{groupIdx, 2};
        
        for mouseIdx = 1:numMice
            % Extract data for specific mouse
            [mouseOffData, mouseOnData] = extractMouseData(offData, onData, mouseIdx, numMice);
            
            % Calculate means
            meanOff = mean(mouseOffData);
            meanOn = mean(mouseOnData);
            
            % Draw connecting line
            plot([groupIdx - X_OFFSET, groupIdx + X_OFFSET], [meanOff, meanOn], ...
                 '-', 'Color', colors{mouseIdx}, 'LineWidth', 1.5);
        end
    end
end

function [mouseOffData, mouseOnData] = extractMouseData(offData, onData, mouseIdx, numMice)
    dataLength = length(offData);
    startIdx = 1 + (dataLength / numMice) * (mouseIdx - 1);
    endIdx = (dataLength / numMice) * mouseIdx;
    
    mouseOffData = offData(startIdx:endIdx);
    mouseOnData = onData(startIdx:endIdx);
end

function [meanOff, meanOn, semOff, semOn] = calculateStatistics(mouseOffData, mouseOnData)
    meanOff = mean(mouseOffData);
    meanOn = mean(mouseOnData);
    semOff = std(mouseOffData) / sqrt(length(mouseOffData));  % Standard error of mean
    semOn = std(mouseOnData) / sqrt(length(mouseOnData));
end

function createLegend(colors, sessionNames)
    % Create legend handles for mouse identifiers
    legendHandles = gobjects(1, length(colors));
    for i = 1:length(colors)
        legendHandles(i) = plot(NaN, NaN, '-', 'Color', colors{i}, 'LineWidth', 1.5);
    end
    
    % Create OFF/ON legend items
    offLegend = plot(NaN, NaN, 'ko', 'MarkerFaceColor', 'none', 'MarkerSize', 6);
    onLegend = plot(NaN, NaN, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6);
    
    % Combine legend entries
    allHandles = [legendHandles, offLegend, onLegend];
    allLabels = [sessionNames, "OFF", "ON"];
    
    legend(allHandles, allLabels, 'Location', 'Best');
end

function setPlotProperties(plotVar, numGroups, groupLabels)
    title('Comparison of 4 Types ON/OFF Data');
    subtitle(plotVar, "Interpreter", 'none');
    xlabel('Group');
    ylabel('Data Value');
    xticks(1:numGroups);
    xticklabels(groupLabels);
end

function plotBarGraph(analysisData, plotIndices, plotVar)
    % Constants
    GROUP_LABELS = {'Base CLOI', 'Base RAND', 'Park CLOI', 'Park RAND'};
    numGroups = size(plotIndices, 2);
    
    % Extract and combine data for all groups
    combinedData = extractCombinedData(analysisData, plotIndices, plotVar, numGroups);
    
    % Calculate mean and SEM for combined ON and OFF data
    meanOff = zeros(1, numGroups);
    meanOn = zeros(1, numGroups);
    semOff = zeros(1, numGroups);
    semOn = zeros(1, numGroups);
    
    % Store individual data for statistical tests
    offDataGroups = cell(1, numGroups);
    onDataGroups = cell(1, numGroups);
    
    for groupIdx = 1:numGroups
        offData = combinedData{groupIdx, 1};
        onData = combinedData{groupIdx, 2};
        
        meanOff(groupIdx) = mean(offData);
        meanOn(groupIdx) = mean(onData);
        semOff(groupIdx) = std(offData) / sqrt(length(offData));
        semOn(groupIdx) = std(onData) / sqrt(length(onData));
        
        % Store data for statistical tests
        offDataGroups{groupIdx} = offData;
        onDataGroups{groupIdx} = onData;
    end
    
    % Plot bar graph
    figure;
    hold on;
    
    % Bar positions
    x = 1:numGroups;
    barWidth = 0.4;
    
    % Plot OFF bars
    bar(x - barWidth / 2, meanOff, barWidth, 'FaceColor', 'b', 'DisplayName', 'OFF');
    
    % Plot ON bars
    bar(x + barWidth / 2, meanOn, barWidth, 'FaceColor', 'g', 'DisplayName', 'ON');
    
    % Add error bars
    errorbar(x - barWidth / 2, meanOff, semOff, 'k', 'LineStyle', 'none', 'LineWidth', 1.0);
    errorbar(x + barWidth / 2, meanOn, semOn, 'k', 'LineStyle', 'none', 'LineWidth', 1.0);
    
    % Perform statistical tests and annotate significance
    for groupIdx = 1:numGroups
        % Compare ON and OFF data within the same group
        [~, pValue] = ttest2(offDataGroups{groupIdx}, onDataGroups{groupIdx});
        
        % Add asterisks for significance
        if pValue < 0.05
            yMax = max(meanOff(groupIdx), meanOn(groupIdx)) + max(semOff(groupIdx), semOn(groupIdx));
            text(groupIdx, yMax + 0.1, '*', 'FontSize', 14, 'HorizontalAlignment', 'center');
        end
    end
    
    % Set plot properties
    title('Bar Graph of Combined ON/OFF Data with Statistical Significance');
    xlabel('Group');
    ylabel('Data Value');
    xticks(x);
    xticklabels(GROUP_LABELS);
    legend('Location', 'Best');
    
    hold off;
end