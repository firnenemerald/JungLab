clear all;
load('hmapmidsave.mat')


gcaedge = cell(size(result01,1),1);
rcaedge = cell(size(result01,1),1);
goaedge = cell(size(result01,1),1);
roaedge = cell(size(result01,1),1);
for i = 1 : size(result01,1)
    for x = 1 : size(result01{i}.gcamp_raw,1)
        for y = 1 : size(result01{i}.gcamp_raw,2)
            if y>=1 && y<=300
                if ~isempty(result01{i}.gcamp_raw{x,y})
                    gcaedge{i,1} = [gcaedge{i,1};result01{i}.gcamp_raw{x,y}];
                end
                if ~isempty(result01{i}.rcamp_raw{x,y})
                    rcaedge{i,1} = [rcaedge{i,1};result01{i}.rcamp_raw{x,y}];
                end
            elseif y >= 300 && y <= 500 
                if  x<=340 | x >= 430
                    if ~isempty(result01{i}.gcamp_raw{x,y})
                        goaedge{i,1} = [goaedge{i,1};result01{i}.gcamp_raw{x,y}];
                    end
                    if ~isempty(result01{i}.rcamp_raw{x,y})
                        roaedge{i,1} = [roaedge{i,1};result01{i}.rcamp_raw{x,y}];
                    end
                end
            elseif y >=500 && y <= 800
                if ~isempty(result01{i}.gcamp_raw{x,y})
                    gcaedge{i,1} = [gcaedge{i,1};result01{i}.gcamp_raw{x,y}];
                end
                if ~isempty(result01{i}.rcamp_raw{x,y})
                    rcaedge{i,1} = [rcaedge{i,1};result01{i}.rcamp_raw{x,y}];
                end
            end
        end
    end
end

for i = 1 : size(gcaedge,1)
    gcmean(i,1) = nanmean(gcaedge{i,1});
    rcmean(i,1) = nanmean(rcaedge{i,1});
    gomean(i,1) = nanmean(goaedge{i,1});
    romean(i,1) = nanmean(roaedge{i,1});
end

save('SVMdata.mat','gcaedge','rcaedge','goaedge','roaedge');

gocdiff = gomean - gcmean;
rocdiff = romean - gomean;

for i = 1 : size(gcaedge,1)
    gvalues(i,1)=(gomean(i,1)-gcmean(i,1))/abs(gomean(i,1)+gcmean(i,1));
    rvalues(i,1)=(romean(i,1)-rcmean(i,1))/abs(romean(i,1)-rcmean(i,1));
end

gocdiff =gocdiff([2,4,5,6,7,9],1);
rocdiff =rocdiff([2,4,5,6,7,9],1);

figure;
b = bar([1, 2], [mean(gocdiff), mean(rocdiff)], 'FaceColor', 'flat');
b.CData(1, :) = [0.4, 0.8, 0.9];
b.CData(2, :) = [1.0, 0.6, 0.6];

ylabel('(OA-CA)/(OA+CA)');

hold on
for i = 1:size(gocdiff, 1)
    plot([1, 2], [gocdiff(i,1), rocdiff(i,1)], '-o', 'Color', [0.6, 0.6, 0.6]);
end


[~, p] = ttest(gocdiff- rocdiff);

if p < 0.001
    stars = '***';
elseif p < 0.01
    stars = '**';
elseif p < 0.05
    stars = '*';
else
    stars = 'n.s.'; 
end

yMax = max([mean(gocdiff), mean(rocdiff)]) * 1.1;  
line([1, 2], [yMax, yMax], 'Color', 'k', 'LineWidth', 1.5);

p_text = sprintf('p = %.3f %s', p, stars);
text(1.5, yMax * 1.05, p_text, 'HorizontalAlignment', 'center', 'FontSize', 12);

hold off

xticks([1, 2]);
xticklabels({'non-PV', 'PV'});