function CLOI_Velocity_Plot(analysisData, sessionIndices, compareType)

    sessionNum = length(sessionIndices);
    colorIndivSession = [0.7, 0.7, 0.7, 0.5];

    switch compareType
        case 'a'
            combinedVar1 = cell(2, 1);
            figure; gca1 = gca; hold on;
            for i = 1:sessionNum
                sessIndex = i;
                centerMazeDistOFF = [analysisData(sessIndex).centerMazeDist{1}; analysisData(sessIndex).centerMazeDist{3}; analysisData(sessIndex).centerMazeDist{5}];
                centerMazeDistON = [analysisData(sessIndex).centerMazeDist{2}; analysisData(sessIndex).centerMazeDist{4}; analysisData(sessIndex).centerMazeDist{6}];
                plot(gca1, 1:2, [mean(centerMazeDistOFF), mean(centerMazeDistON)]/1000, '-o', 'MarkerSize', 5, 'LineWidth', 1.0, 'Color', colorIndivSession);
                hold(gca1, 'on');
                combinedVar1{1} = [combinedVar1{1}; centerMazeDistOFF];
                combinedVar1{2} = [combinedVar1{2}; centerMazeDistON];
            end
            b1 = bar(gca1, 1:2, cellfun(@mean, combinedVar1)/1000, 'FaceColor', [0.5, 0.5, 0.5], 'EdgeColor', 'none');
            b1.FaceAlpha = 0.5;
            e1 = errorbar(gca1, 1:2, cellfun(@mean, combinedVar1), cellfun(@std, combinedVar1)/1000, 'k', 'LineStyle', 'none', 'LineWidth', 1.0);
            
            title(gca1, 'Center Maze Distance');
            xlabel(gca1, 'OFF / ON Session');
            ylabel(gca1, 'Distance (cm)');
            
        case 'c'
            combinedVar1 = cell(6, 1);
            figure; gca1 = gca; hold on;
            for i = 1:sessionNum
                sessIndex = i;
                for j = 1:6
                    centerMazeDistMS = analysisData(sessIndex).centerMazeDist{j};
                    combinedVar1{j} = [combinedVar1{j}; centerMazeDistMS];
                    plot(gca1, j, mean(centerMazeDistMS), 'o', 'MarkerSize', 5, 'LineWidth', 1.0, 'Color', colorIndivSession);
                    hold(gca1, 'on');
                end
                centerMazeDistXPoints = 1:6;
                velocitiesPerSession = arrayfun(@(j) mean(analysisData(sessIndex).centerMazeDist{j}), 1:6);
                plot(gca1, centerMazeDistXPoints, velocitiesPerSession/1000, '-', 'LineWidth', 1.0, 'Color', colorIndivSession);
                hold(gca1, 'on');
            end
            b1 = bar(gca1, 1:6, cellfun(@mean, combinedVar1)/1000, 'FaceColor', [0.5, 0.5, 0.5], 'EdgeColor', 'none');
            b1.FaceAlpha = 0.5;
            e1 = errorbar(gca1, 1:6, cellfun(@mean, combinedVar1), cellfun(@std, combinedVar1)/1000, 'k', 'LineStyle', 'none', 'LineWidth', 1.0);
            title(gca1, 'Center Maze Distance');
            xlabel(gca1, 'Minisession');
            ylabel(gca1, 'Distance (cm)');
    end
end