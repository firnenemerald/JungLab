%% Behavior analysis.m
% Code for behavior analysis

% Data
Group1 = [];
Group2 = [];
Group3 = [];

nGroup1 = length(Group1);
nGroup2 = length(Group2);
nGroup = length(Group3);

data = [mean(Group1), mean(Group2, 'omitnan'), mean(Group3, 'omitnan')];
errors = [std(Group1)/sqrt(nGroup1), std(Group2, 'omitnan')/sqrt(sum(~isnan(Group2))), std(Group3, 'omitnan')/sqrt(sum(~isnan(Group3)))];

figure;

b = bar(data, 'FaceColor', 'flat');
b.CData(1, :) = [0.5 0.2 0.2]; 
b.CData(2, :) = [0.2 0.2 0.5]; 
b.CData(3, :) = [0.2 0.5 0.2]; 
hold on;

errorbar(1, data(1), errors(1), 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
errorbar(2, data(2), errors(2), 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
errorbar(3, data(3), errors(3), 'k', 'LineStyle', 'none', 'LineWidth', 1.5);

for i = 1:nGroup1
    if i <= nGroup2
        plot([1, 2], [Group1(i), Group2(i)], 'k-', 'LineWidth', 1);
    end
    if i <= nGroup2 && i <= nGroup3
        plot([2, 3], [Group2(i), Group3(i)], 'k-', 'LineWidth', 1);
    end
end

scatter(ones(1, nGroup1), Group1, 'filled', 'r', 'DisplayName', 'Group1 Data');
scatter(2 * ones(1, nGroup2), Group2, 'filled', 'b', 'DisplayName', 'Group2 Data');
scatter(3 * ones(1, nGroup3), Group3, 'filled', 'g', 'DisplayName', 'Group3 Data');

set(gca, 'XTick', [1 2 3], 'XTickLabel', {'Group1', 'Group2', 'Group3'});
ylabel('Time (s)');
title('Behavior Test'); 

[p1, h1] = signrank(Group1, Group2);
[p2, h2] = signrank(Group1, Group3);
[p3, h3] = signrank(Group2, Group3);

fprintf('Group1 vs Group2: h = %d, p-value = %.2f\n', h1, p1);
fprintf('Group1 vs Group3: h = %d, p-value = %.2f\n', h2, p2);
fprintf('Group2 vs Group3: h = %d, p-value = %.2f\n', h3, p3);

p_threshold = 0.001;

if p1 < p_threshold
    p1 = sprintf('p < %.2f', p_threshold);
else
    p1 = sprintf('%.2f', p1);
end

if p2 < p_threshold
    p2 = sprintf('p < %.2f', p_threshold);
else
    p2 = sprintf('%.2f', p2);
end

if p3 < p_threshold
    p3 = sprintf('p < %.2f', p_threshold);
else
    p3 = sprintf('%.2f', p3);
end

text(2.8, max(data) + max(errors) * 4, sprintf('p-value (Group1 vs Group2) = %s', p1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
text(2.8, max(data) + max(errors) * 5, sprintf('p-value (Group1 vs Group3) = %s', p2), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
text(2.8, max(data) + max(errors) * 6, sprintf('p-value (Group2 vs Group3) = %s', p3), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');

hold off;