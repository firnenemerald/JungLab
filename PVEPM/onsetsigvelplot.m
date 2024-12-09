function onsetsigvelplot(gca,rca,vel,ttext)

x = -0.5:1/60:1;
x2 = -0.5:1/30:1;

for i = 1 : size(gca,2)
    meangca(1,i) = nanmean(gca(:,i));
    semgca(1,i) = nanstd(gca(:,i))/size(gca,1);
end
upper_bound = meangca + semgca;
lower_bound = meangca - semgca;

for i = 1 : size(rca,2)
    meanrca(1,i) = nanmean(rca(:,i));
    semrca(1,i) = nanstd(rca(:,i))/size(rca,1);
end
upper_bound1 = meanrca + semrca;
lower_bound1 = meanrca - semrca;


for i = 1 : size(vel,2)
    meanvel(1,i) = nanmean(vel(:,i));
    semvel(1,i) = nanstd(vel(:,i))/size(vel,1);
end
upper_bound2 = meanvel + semvel;
lower_bound2 = meanvel - semvel;

figure;
hold on;

yyaxis right
fill([x2, fliplr(x2)], [upper_bound2, fliplr(lower_bound2)], [0,0,0], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x2, meanvel,'-','Color',[0,0,0] ,'LineWidth', 1.5);

ylabel('velocity');

xline(0, 'k--', 'LineWidth', 1.5)

yyaxis left
fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x, meangca, 'g-', 'LineWidth', 1.5);

fill([x, fliplr(x)], [upper_bound1, fliplr(lower_bound1)], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x, meanrca, 'r-', 'LineWidth', 1.5);

ylabel('Ca signal(zscore)');





xlabel('time:second');
grid on;
hold off;
title(ttext);

