
function barplot1(pre_goa05,post_goa05,ttext)
[~, p_value] = ttest(pre_goa05, post_goa05);
figure;
bar([1,2],[mean(pre_goa05),mean(post_goa05)]);
hold on
x1 = ones(size(pre_goa05)) * 1; 
x2 = ones(size(post_goa05)) * 2; 

for i = 1:length(pre_goa05)
    plot([1, 2], [pre_goa05(i), post_goa05(i)], 'ko-', 'MarkerFaceColor', 'k'); 
end

if p_value < 0.001
    significance = '***';
elseif p_value < 0.01
    significance = '**';
elseif p_value < 0.05
    significance = '*';
else
    significance = 'n.s.'; 
end

y_max = max([mean(pre_goa05), mean(post_goa05)]) + 0.5; 
plot([1, 2], [y_max, y_max], 'k-', 'LineWidth', 1.5);
text(1.5, y_max + 0.3, sprintf('%s\np = %.3f', significance, p_value), ...
    'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'blue');
hold off;
title(ttext);
end