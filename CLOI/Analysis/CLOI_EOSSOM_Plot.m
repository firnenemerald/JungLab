function CLOI_EOSSOM_Plot(analysisData, sessionIndices, compareType)

colorIndivSession = [0.7, 0.7, 0.7, 0.5];

sessionNum = length(sessionIndices);

switch compareType
    case 'a'
        combinedVar1 = cell(2, 1);

        figure; gca1 = gca; hold on;
        for i = 1:sessionNum
            sessIndex = i;
            eossomTimesOFF = [analysisData(sessIndex).eossomTimes{1}; analysisData(sessIndex).eossomTimes{3}; analysisData(sessIndex).eossomTimes{5}];
            eossomTimesON = [analysisData(sessIndex).eossomTimes{2}; analysisData(sessIndex).eossomTimes{4}; analysisData(sessIndex).eossomTimes{6}];
            plot(gca1, 1:2, [mean(eossomTimesOFF), mean(eossomTimesON)], '-o', 'MarkerSize', 5, 'LineWidth', 1.0, 'Color', colorIndivSession);
            hold(gca1, 'on');
            combinedVar1{1} = [combinedVar1{1}; eossomTimesOFF];
            combinedVar1{2} = [combinedVar1{2}; eossomTimesON];
        end
        % Plot bar and errorbar graphs for combined EOSSOM times and numbers
        b1 = bar(gca1, 1:2, cellfun(@mean, combinedVar1), 'FaceColor', [0.5, 0.5, 0.5], 'EdgeColor', 'none');
        b1.FaceAlpha = 0.5;
        e1 = errorbar(gca1, 1:2, cellfun(@mean, combinedVar1), cellfun(@std, combinedVar1), 'k', 'LineStyle', 'none', 'LineWidth', 1.0);
        
        % Set axis labels and titles
        title(gca1, 'EOSSOM Time');
        xlabel(gca1, 'OFF / ON Session');
        ylabel(gca1, 'EOSSOM Time (s)');

        % Calculate mean value of OFF and ON EOSSOM times
        meanEossomTimeOFF = mean(combinedVar1{1});
        meanEossomTimeON = mean(combinedVar1{2});
        fprintf('Mean EOSSOM time OFF across all minisessions: %.4f seconds\n', meanEossomTimeOFF);
        fprintf('Mean EOSSOM time ON across all minisessions: %.4f seconds\n', meanEossomTimeON);
        
    case 'c'
        sessionNum = length(sessionIndices);
        combinedVar1 = cell(6, 1);

        figure; gca1 = gca; hold on;
        for i = 1:sessionNum
            sessIndex = i;
            for j = 1:6
                eossomTimeMS = analysisData(sessIndex).eossomTimes{j};
                combinedVar1{j} = [combinedVar1{j}; eossomTimeMS];
                plot(gca1, j, mean(eossomTimeMS), 'o', 'MarkerSize', 5, 'LineWidth', 1.0, 'Color', colorIndivSession);
                hold(gca1, 'on');
            end
            eossomXPoints = 1:6;
            eossomTimesPerSession = arrayfun(@(j) mean(analysisData(sessIndex).eossomTimes{j}), 1:6);
            plot(gca1, eossomXPoints, eossomTimesPerSession, '-', 'LineWidth', 1.0, 'Color', colorIndivSession);
            hold(gca1, 'on');
        end
        % Plot bar and errorbar graphs for combined EOSSOM times and numbers
        b1 = bar(gca1, 1:6, cellfun(@mean, combinedVar1), 'FaceColor', [0.5, 0.5, 0.5], 'EdgeColor', 'none');
        b1.FaceAlpha = 0.5;
        e1 = errorbar(gca1, 1:6, cellfun(@mean, combinedVar1), cellfun(@std, combinedVar1), 'k', 'LineStyle', 'none', 'LineWidth', 1.0);
        
        % Set axis labels and titles
        title(gca1, 'EOSSOM Time - Park RAND Sessions');
        xlabel(gca1, 'Mini Session');
        ylabel(gca1, 'EOSSOM Time (s)');
        
        % Calculate mean value of all EOSSOM times
        allVar1 = [];
        for i = 1:length(combinedVar1)
            allVar1 = [allVar1; combinedVar1{i}];
        end
        meanEossomTime = mean(allVar1);
        fprintf('Mean EOSSOM time across all minisessions: %.4f seconds\n', meanEossomTime);
end

end