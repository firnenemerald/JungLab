function f_plotrg(gmonset,rmonset,vel,ttext,optionn)
% gmonset =GMOt;
% rmonset = RMOt;
x= -1:1/60:1;
x2 = -1:1/30:1;
if optionn == 'sem'
    for i = 1 : size(gmonset,2)
        meangm(1,i) = nanmean(gmonset(:,i));
        semgm(1,i) = nanstd(gmonset(:,i))/size(gmonset,1);
    end

    for i = 1 : size(rmonset,2)
        meanrm(1,i) = nanmean(rmonset(:,i));
        semrm(1,i) = nanstd(rmonset(:,i))/size(rmonset,1);
    end

    for i = 1 : size(vel,2)
        meanvel(1,i) = nanmean(vel(:,i));
        semvel(1,i) = nanstd(vel(:,i))/size(vel,1);
    end
elseif optionn == 'std'
    for i = 1 : size(gmonset,2)
        meangm(1,i) = nanmean(gmonset(:,i));
        semgm(1,i) = nanstd(gmonset(:,i));
    end

    for i = 1 : size(rmonset,2)
        meanrm(1,i) = nanmean(rmonset(:,i));
        semrm(1,i) = nanstd(rmonset(:,i));
    end

    for i = 1 : size(vel,2)
        meanvel(1,i) = nanmean(vel(:,i));
        semvel(1,i) = nanstd(vel(:,i));
    end
end

upper_bound = meangm + semgm;
lower_bound = meangm - semgm;


upper_bound1 = meanrm + semrm;
lower_bound1 = meanrm - semrm;

upper_bound2 = meanvel +semvel;
lower_bound2 = meanvel - semvel;

figure;
hold on;

yyaxis right

fill([x2, fliplr(x2)], [upper_bound2, fliplr(lower_bound2)], 'k', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x2,meanvel,'k-', 'LineWidth', 1.5);

ylabel('velocity')

yyaxis left
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

