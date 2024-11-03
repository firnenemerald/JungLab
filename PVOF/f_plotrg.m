function f_plotrg(gmonset,rmonset,ttext)
x= -2:1/60:2;

for i = 1 : size(gmonset,2)
    meangm(1,i) = nanmean(gmonset(:,i));
    semgm(1,i) = nanstd(gmonset(:,i))/size(gmonset,1);
end

for i = 1 : size(rmonset,2)
    meanrm(1,i) = nanmean(rmonset(:,i));
    semrm(1,i) = nanstd(rmonset(:,i))/size(rmonset,1);
end

upper_bound = meangm + semgm;
lower_bound = meangm - semgm;


upper_bound1 = meanrm + semrm;
lower_bound1 = meanrm - semrm;

figure;
hold on;

fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

fill([x, fliplr(x)], [upper_bound1, fliplr(lower_bound1)], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x, meangm, 'g-', 'LineWidth', 1.5);

plot(x, meanrm, 'r-', 'LineWidth', 1.5);

xline(0, 'k--', 'LineWidth', 1.5)

xlabel('time:second');
ylabel('Ca signal(zscore)');
title(ttext);
grid on;
hold off;

