clear all
load("Arearange.mat")
load('dlcsmooth.mat');
load("errorfixed.mat")

mergeall;

data = struct2cell(combined);
dataname = fieldnames(combined);

path = uigetdir;
path2 = fullfile(path,'onsetplot');
mkdir(path2);

%saveall(path,'onsetplot')

for i = 1 : size(data,1)
    cD = data{i};
    dname = dataname{i};
    results.(dname) = asdf(cD);
    saveall(path2,dname)
end

save('onsetresults.mat','results');
clear all
%%
load('onsetresults.mat')

result = struct2cell(results);
resultname = fieldnames(results);

for i = 1: size(result,1)
    gvalues(i,1) = result{i,1}.gvalue;
    rvalues(i,1) = result{i,1}.rvalue;
end

figure;
b = bar([1, 2], [mean(gvalues), mean(rvalues)], 'FaceColor', 'flat');
b.CData(1, :) = [0.4, 0.8, 0.9];
b.CData(2, :) = [1.0, 0.6, 0.6];

ylabel('(OA-CA)/(OA+CA)');

hold on
for i = 1:size(gvalues, 1)
    plot([1, 2], [gvalues(i,1), rvalues(i,1)], '-o', 'Color', [0.6, 0.6, 0.6]);
    text(2, rvalues(i,1) * 1.05, strrep(resultname{i},'_','-'), 'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', 'k');
end


[~, p] = ttest(gvalues, rvalues);

if p < 0.001
    stars = '***';
elseif p < 0.01
    stars = '**';
elseif p < 0.05
    stars = '*';
else
    stars = 'n.s.'; 
end

yMax = max([mean(gvalues), mean(rvalues)]) * 1.1;  
line([1, 2], [yMax, yMax], 'Color', 'k', 'LineWidth', 1.5);

p_text = sprintf('p = %.3f %s', p, stars);
text(1.5, yMax * 1.05, p_text, 'HorizontalAlignment', 'center', 'FontSize', 12);

hold off

xticks([1, 2]);
xticklabels({'gcamp', 'rcamp'});

gca = [];goa = [];rca = [];roa = [];
for i = 1 : size(result,1)
    gca=[gca;result{i,1}.GCaMP_CAonsetsig];goa=[goa;result{i,1}.GCaMP_OAonsetsig];rca=[rca;result{i,1}.RCaMP_CAonsetsig];roa=[roa;result{i,1}.RCaMP_OAonsetsig];
end

for i = 1 : size(gca,2)
    meangca(1,i) = nanmean(gca(:,i));
    semgca(1,i) = nanstd(gca(:,i))/size(gca,1);
end

x = -1:1/60:1;
upper_bound = meangca + semgca;
lower_bound = meangca - semgca;

figure;
hold on;

fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x, meangca, 'g-', 'LineWidth', 1.5);


for i = 1 : size(rca,2)
    meanrca(1,i) = nanmean(rca(:,i));
    semrca(1,i) = nanstd(rca(:,i))/size(rca,1);
end

upper_bound1 = meanrca + semrca;
lower_bound1 = meanrca - semrca;


fill([x, fliplr(x)], [upper_bound1, fliplr(lower_bound1)], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x, meanrca, 'r-', 'LineWidth', 1.5);

xline(0, 'k--', 'LineWidth', 1.5)


xlabel('time:second');
ylabel('Ca signal(zscore)');
title('closed arm onset:GCaMP vs RCaMP');
grid on;
hold off;

for i = 1 : size(goa,2)
    meangoa(1,i) = nanmean(goa(:,i));
    semgoa(1,i) = nanstd(goa(:,i))/size(goa,1);
end

upper_bound = meangoa + semgoa;
lower_bound = meangoa - semgoa;

figure;
hold on;

fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x, meangoa, 'g-', 'LineWidth', 1.5);

xline(0, 'k--', 'LineWidth', 1.5)

xlabel('time:second');
ylabel('Ca signal(zscore)');
title('open arm onset:GCaMP vs RCaMP');
grid on;


for i = 1 : size(roa,2)
    meanroa(1,i) = nanmean(roa(:,i));
    semroa(1,i) = nanstd(roa(:,i))/size(roa,1);
end

upper_bound1 = meanroa + semroa;
lower_bound1 = meanroa - semroa;

hold on;

fill([x, fliplr(x)], [upper_bound1, fliplr(lower_bound1)], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x, meanroa, 'r-', 'LineWidth', 1.5);


for i = 1 : size(result,1)
    roa_pre05 = [];
    roa_post05 = [];
    roa_pre1 = [];
    roa_post1 = [];
    for j = 1 : size(result{i}.RCaMP_OAonsetsig,1)
        roa_pre05 = [roa_pre05,mean(result{i}.RCaMP_OAonsetsig(j,31:60))];
        roa_post05 = [roa_post05,mean(result{i}.RCaMP_OAonsetsig(j,62:91))];
        roa_pre1 = [roa_pre1,mean(result{i}.RCaMP_OAonsetsig(j,1:60))];
        roa_post1 = [roa_post1,mean(result{i}.RCaMP_OAonsetsig(j,62:121))];
    end
    pre_roa05(i,1) = nanmean(roa_pre05);
    post_roa05(i,1) = nanmean(roa_post05);
    pre_roa1(i,1) = nanmean(roa_pre1);
    post_roa1(i,1) = nanmean(roa_post1);
end

for i = 1 : size(result,1)
    goa_pre05 = [];
    goa_post05 = [];
    goa_pre1 = [];
    goa_post1 = [];
    for j = 1 : size(result{i}.GCaMP_OAonsetsig,1)
        goa_pre05 = [goa_pre05,mean(result{i}.GCaMP_OAonsetsig(j,31:60))];
        goa_post05 = [goa_post05,mean(result{i}.GCaMP_OAonsetsig(j,62:91))];
        goa_pre1 = [goa_pre1,mean(result{i}.GCaMP_OAonsetsig(j,1:60))];
        goa_post1 = [goa_post1,mean(result{i}.GCaMP_OAonsetsig(j,62:121))];
    end
    pre_goa05(i,1) = nanmean(goa_pre05);
    post_goa05(i,1) = nanmean(goa_post05);
    pre_goa1(i,1) = nanmean(goa_pre1);
    post_goa1(i,1) = nanmean(goa_post1);
end

for i = 1 : size(result,1)
    gca_pre05 = [];
    gca_post05 = [];
    gca_pre1 = [];
    gca_post1 = [];
    for j = 1 : size(result{i}.GCaMP_CAonsetsig,1)
        gca_pre05 = [gca_pre05,mean(result{i}.GCaMP_CAonsetsig(j,31:60))];
        gca_post05 = [gca_post05,mean(result{i}.GCaMP_CAonsetsig(j,62:91))];
        gca_pre1 = [gca_pre1,mean(result{i}.GCaMP_CAonsetsig(j,1:60))];
        gca_post1 = [gca_post1,mean(result{i}.GCaMP_CAonsetsig(j,62:121))];
    end
    pre_gca05(i,1) = nanmean(gca_pre05);
    post_gca05(i,1) = nanmean(gca_post05);
    pre_gca1(i,1) = nanmean(gca_pre1);
    post_gca1(i,1) = nanmean(gca_post1);
end

for i = 1 : size(result,1)
    rca_pre05 = [];
    rca_post05 = [];
    rca_pre1 = [];
    rca_post1 = [];
    for j = 1 : size(result{i}.RCaMP_CAonsetsig,1)
        rca_pre05 = [rca_pre05,mean(result{i}.RCaMP_CAonsetsig(j,31:60))];
        rca_post05 = [rca_post05,mean(result{i}.RCaMP_CAonsetsig(j,62:91))];
        rca_pre1 = [rca_pre1,mean(result{i}.RCaMP_CAonsetsig(j,1:60))];
        rca_post1 = [rca_post1,mean(result{i}.RCaMP_CAonsetsig(j,62:121))];
    end
    pre_rca05(i,1) = nanmean(rca_pre05);
    post_rca05(i,1) = nanmean(rca_post05);
    pre_rca1(i,1) = nanmean(rca_pre1);
    post_rca1(i,1) = nanmean(rca_post1);
end


brca_pre05 = [];
brca_post05 = [];
brca_pre1 = [];
brca_post1 = [];
for i = 1 : size(result,1)
    for j = 1 : size(result{i}.RCaMP_CAonsetsig,1)
        brca_pre05 = [brca_pre05,nanmean(result{i}.RCaMP_CAonsetsig(j,31:60))];
        brca_post05 = [brca_post05,nanmean(result{i}.RCaMP_CAonsetsig(j,62:91))];
        brca_pre1 = [brca_pre1,nanmean(result{i}.RCaMP_CAonsetsig(j,1:60))];
        brca_post1 = [brca_post1,nanmean(result{i}.RCaMP_CAonsetsig(j,62:121))];
    end
end

bgoa_pre05 = [];
bgoa_post05 = [];
bgoa_pre1 = [];
bgoa_post1 = [];
for i = 1 : size(result,1)
    for j = 1 : size(result{i}.GCaMP_OAonsetsig,1)
        bgoa_pre05 = [bgoa_pre05,nanmean(result{i}.GCaMP_OAonsetsig(j,31:60))];
        bgoa_post05 = [bgoa_post05,nanmean(result{i}.GCaMP_OAonsetsig(j,62:91))];
        bgoa_pre1 = [bgoa_pre1,nanmean(result{i}.GCaMP_OAonsetsig(j,1:60))];
        bgoa_post1 = [bgoa_post1,nanmean(result{i}.GCaMP_OAonsetsig(j,62:121))];
    end
end

broa_pre05 = [];
broa_post05 = [];
broa_pre1 = [];
broa_post1 = [];
for i = 1 : size(result,1)
    for j = 1 : size(result{i}.RCaMP_OAonsetsig,1)
        broa_pre05 = [broa_pre05,nanmean(result{i}.RCaMP_OAonsetsig(j,31:60))];
        broa_post05 = [broa_post05,nanmean(result{i}.RCaMP_OAonsetsig(j,62:91))];
        broa_pre1 = [broa_pre1,nanmean(result{i}.RCaMP_OAonsetsig(j,1:60))];
        broa_post1 = [broa_post1,nanmean(result{i}.RCaMP_OAonsetsig(j,62:121))];
    end
end

bgca_pre05 = [];
bgca_post05 = [];
bgca_pre1 = [];
bgca_post1 = [];
for i = 1 : size(result,1)
    for j = 1 : size(result{i}.GCaMP_CAonsetsig,1)
        bgca_pre05 = [bgca_pre05,nanmean(result{i}.GCaMP_CAonsetsig(j,31:60))];
        bgca_post05 = [bgca_post05,nanmean(result{i}.GCaMP_CAonsetsig(j,62:91))];
        bgca_pre1 = [bgca_pre1,nanmean(result{i}.GCaMP_CAonsetsig(j,1:60))];
        bgca_post1 = [bgca_post1,nanmean(result{i}.GCaMP_CAonsetsig(j,62:121))];
    end
end
%%
barplot1(pre_goa05,post_goa05,'go05')
barplot1(pre_goa1,post_goa1,'go1')
barplot1(pre_roa05,post_roa05,'ro05')
barplot1(pre_roa1,post_roa1,'ro1')
barplot1(pre_gca05,post_gca05,'gc05')
barplot1(pre_gca1,post_gca1,'gc1')
barplot1(pre_rca05,post_rca05,'rc05')
barplot1(pre_rca1,post_rca1,'rc1')
%%
barplot1(bgoa_pre05,bgoa_post05,'go05');
barplot1(bgoa_pre1,bgoa_post1,'go1');
barplot1(bgca_pre05,bgca_post05,'gc05');
barplot1(bgca_pre1,bgca_post1,'gc1');
barplot1(broa_pre05,broa_post05,'ro05');
barplot1(broa_pre1,broa_post1,'ro1');
barplot1(brca_pre05,brca_post05,'rc05');
barplot1(brca_pre1,brca_post1,'rc1');

%%


function result = asdf(cD)
dlc = cD.DLC(2:end,:);
gcamp = cD.GCaMP;
rcamp = cD.RCaMP;
time = [0:1/60.241:(1/60.241)*size(rcamp,1)]';

stime=(dlc(1,1)-cD.syncframe)*(1/29.99);

[~,sind]=min(abs(time-stime));
gcamp = gcamp(sind:end,1);
rcamp = rcamp(sind:end,1);

dorictime = [0:1/60.241:(1/60.241)*size(rcamp,1)]';
dlctime = [0:1/29.99:(1/29.99)*size(dlc,1)]';

oarange =cD.OArange;
carange = cD.CArange;

oatime=(oarange-cD.syncframe)*(1/29.99); catime =(carange-cD.syncframe)*(1/29.99);
for i = 1 : size(oatime,1)
    temp = [];
    for j = 1 : size(oatime,2)
        [~,mind]=min(abs(time-oatime(i,j)));
        temp = [temp,mind];
    end
    oasyncdoric(i,:) = temp;
    clear temp
end

for i = 1 : size(catime,1)
    temp = [];
    for j = 1 : size(catime,2)
        [~,mind]=min(abs(time-catime(i,j)));
        temp = [temp,mind];
    end
    casyncdoric(i,:) = temp;
    clear temp
end

zgcamp = (gcamp - nanmean(gcamp))/nanstd(gcamp);
zrcamp = (rcamp - nanmean(rcamp))/nanstd(rcamp);

cdat = repmat(1,1,size(zgcamp,1));
for i = 1 : size(oasyncdoric,1)
    cdat(1,oasyncdoric(i,1):oasyncdoric(i,2))=0;
end

subplot(3,1,1)
plot(zgcamp,'g');
xlim([1,size(zgcamp,1)]);

subplot(3,1,2)
plot(zrcamp,'r');
xlim([1,size(zgcamp,1)]);

subplot(3,1,3)
imagesc(cdat); 
colormap([0 0 1; 1 1 0]); 
caxis([0 1]);

goatotsig = [];
gcatotsig = [];
roatotsig = [];
rcatotsig = [];
for i = 1 : size(casyncdoric,1)
    gcatotsig = [gcatotsig;gcamp(casyncdoric(i,1):casyncdoric(i,2),1)];
    rcatotsig = [rcatotsig;rcamp(casyncdoric(i,1):casyncdoric(i,2),1)];
end

for i = 1 : size(oasyncdoric,1)
    goatotsig = [goatotsig;zgcamp(oasyncdoric(i,1):oasyncdoric(i,2),1)];
    roatotsig = [roatotsig;zrcamp(oasyncdoric(i,1):oasyncdoric(i,2),1)];
end


gvalue = (nanmean(goatotsig)-nanmean(gcatotsig))/(nanmean(gcatotsig)+nanmean(goatotsig));
rvalue =(nanmean(roatotsig)-nanmean(rcatotsig))/(nanmean(rcatotsig)+nanmean(roatotsig));

caonsetind = [];
for i = 1 : size(casyncdoric,1)
    if casyncdoric(i,1) > 60 & i==1
        caonsetind = [caonsetind,i];
    elseif i> 1
        if casyncdoric(i,1) - casyncdoric(i-1,2) >60
            caonsetind = [caonsetind,i];
        end
    end
end
caonset = casyncdoric(caonsetind,1);
for i = 1 : size(caonset)
    gcaonsetsig(i,:) = zgcamp(caonset(i,1)-60:caonset(i,1)+60);
    rcaonsetsig(i,:) = zrcamp(caonset(i,1)-60:caonset(i,1)+60);
end
 
for i = 1 : size(gcaonsetsig,2)
    meangca(1,i) = nanmean(gcaonsetsig(:,i));
    semgca(1,i) = nanstd(gcaonsetsig(:,i))/size(gcaonsetsig,1);
end

x = -1:1/60:1;
upper_bound = meangca + semgca;
lower_bound = meangca - semgca;

figure;
hold on;

fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x, meangca, 'b-', 'LineWidth', 1.5);

xline(0, 'k--', 'LineWidth', 1.5)

xlabel('time:second');
ylabel('Ca signal(zscore)');
title('closed arm onset:gcamp');
grid on;
hold off;

for i = 1 : size(rcaonsetsig,2)
    meanrca(1,i) = nanmean(rcaonsetsig(:,i));
    semrca(1,i) = nanstd(rcaonsetsig(:,i))/size(rcaonsetsig,1);
end

upper_bound = meanrca + semrca;
lower_bound = meanrca - semrca;

figure;
hold on;

fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x, meanrca, 'b-', 'LineWidth', 1.5);

xline(0, 'k--', 'LineWidth', 1.5)

xlabel('time:second');
ylabel('Ca signal(zscore)');
title('closed arm onset:rcamp');
grid on;
hold off;



oaonsetind = [];
for i = 1 : size(oasyncdoric,1)
    if oasyncdoric(i,1) > 60 & i==1
        oaonsetind = [oaonsetind,i];
    elseif i> 1
        if oasyncdoric(i,1) - oasyncdoric(i-1,2) >60
            oaonsetind = [oaonsetind,i];
        end
    end
end
oaonset = oasyncdoric(oaonsetind,1);
for i = 1 : size(oaonset)
    goaonsetsig(i,:) = zgcamp(oaonset(i,1)-60:oaonset(i,1)+60);
    roaonsetsig(i,:) = zrcamp(oaonset(i,1)-60:oaonset(i,1)+60);
end

for i = 1 : size(goaonsetsig,2)
    meangoa(1,i) = nanmean(goaonsetsig(:,i));
    semgoa(1,i) = nanstd(goaonsetsig(:,i))/size(goaonsetsig,1);
end

upper_bound = meangoa + semgoa;
lower_bound = meangoa - semgoa;

figure;
hold on;

fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x, meangoa, 'b-', 'LineWidth', 1.5);

xline(0, 'k--', 'LineWidth', 1.5)

xlabel('time:second');
ylabel('Ca signal(zscore)');
title('open arm onset:gcamp');
grid on;
hold off;

for i = 1 : size(roaonsetsig,2)
    meanroa(1,i) = nanmean(roaonsetsig(:,i));
    semroa(1,i) = nanstd(roaonsetsig(:,i))/size(roaonsetsig,1);
end

upper_bound = meanroa + semroa;
lower_bound = meanroa - semroa;

figure;
hold on;

fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(x, meanroa, 'b-', 'LineWidth', 1.5);

xline(0, 'k--', 'LineWidth', 1.5)

xlabel('time:second');
ylabel('Ca signal(zscore)');
title('open arm onset:rcamp');
grid on;
hold off;

result.gvalue = gvalue;
result.rvalue = rvalue;
result.RCaMP_OAonsetsig = roaonsetsig;
result.RCaMP_CAonsetsig = rcaonsetsig;
result.GCaMP_OAonsetsig = goaonsetsig;
result.GCaMP_CAonsetsig = gcaonsetsig;
end