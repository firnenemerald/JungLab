clear all ;load("Arearange.mat"); 
load("errorfixed.mat"); 
load('dlcsmooth.mat');
%load('decaycorrected.mat')

mergeall;
%%
data = struct2cell(combined);
dataname = fieldnames(combined);

for i = 1 : size(data,1)
    cD = data{i};
    dname = dataname{i};
    SVM.(dname) = asdf(cD);
end

save('SVM.mat','SVM')
clear all
%%
clear all
load("SVM.mat");

for t = 1 : 100
    clearvars -except SVM accuracy_r accuracy_g t
    data = struct2cell(SVM);

    rdata = [];
    gdata = [];
    rdata_train = [];
    gdata_train = [];
    for i = 1:size(data,1)
        data_r_0 = data{i}.rdata(data{i}.rdata(:, 2) == 0, :);
        data_r_1 = data{i}.rdata(data{i}.rdata(:, 2) == 1, :);
        data_g_0 = data{i}.gdata(data{i}.gdata(:, 2) == 0, :);
        data_g_1 = data{i}.gdata(data{i}.gdata(:, 2) == 1, :);

        numsam = min([size(data_r_0, 1), size(data_r_1, 1), ...
            size(data_g_0, 1), size(data_g_1, 1)]);

        numtrain = round(0.5 * numsam);

        trainIdx_r_0 = randsample(size(data_r_0, 1), numtrain);
        trainIdx_r_1 = randsample(size(data_r_1, 1), numtrain);
        trainIdx_g_0 = randsample(size(data_g_0, 1), numtrain);
        trainIdx_g_1 = randsample(size(data_g_1, 1), numtrain);

        rdata_train = [rdata_train; data_r_0(trainIdx_r_0, :); data_r_1(trainIdx_r_1, :)];
        gdata_train = [gdata_train; data_g_0(trainIdx_g_0, :); data_g_1(trainIdx_g_1, :)];

        testIdx_r_0 = setdiff(1:size(data_r_0, 1), trainIdx_r_0);
        testIdx_r_1 = setdiff(1:size(data_r_1, 1), trainIdx_r_1);
        testIdx_g_0 = setdiff(1:size(data_g_0, 1), trainIdx_g_0);
        testIdx_g_1 = setdiff(1:size(data_g_1, 1), trainIdx_g_1);

        r_test{i,1} = [data_r_0(testIdx_r_0, :); data_r_1(testIdx_r_1, :)];
        g_test{i,1} = [data_g_0(testIdx_g_0, :); data_g_1(testIdx_g_1, :)];
    end

    SVMmodel_r = fitcsvm(rdata_train(:, 1), rdata_train(:, 2));
    SVMmodel_g = fitcsvm(gdata_train(:, 1), gdata_train(:, 2));

    for i = 1 : size(r_test,1)
        predicted_r = predict(SVMmodel_r, r_test{i,1}(:, 1));
        predicted_g = predict(SVMmodel_g, g_test{i,1}(:, 1));

        accuracy_r(i,t) = sum(predicted_r == r_test{i,1}(:, 2)) / length(r_test{i,1}) * 100;
        accuracy_g(i,t) = sum(predicted_g == g_test{i,1}(:, 2)) / length(g_test{i,1}) * 100;
        clear predicted_g predicted_r
    end
 
end

for i = 1 : size(accuracy_g,1)
    macc_g(i,1) = mean(accuracy_g(i,:));
    macc_r(i,1) = mean(accuracy_r(i,:));
end

save('accuracy.mat','macc_r','macc_g');

clear all
load("accuracy.mat")
% macc_g(8) = []; macc_g(3) = []; macc_g(1) = []; macc_r(8) = []; macc_r(3) = []; macc_r(1) = []; 

[~, p_value] = ttest(macc_r - macc_g);

figure;
b = bar([1,2],[mean(macc_g), mean(macc_r)]);
hold on
for i = 1 : size(macc_r)
    plot([1,2],[macc_g(i,1),macc_r(i,1)],'o-','MarkerFaceColor',[0,0,0],'Color',[0,0,0]);
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
y_max = max([macc_g; macc_r])*1.2; 
text(2.5, 0, sprintf('%s\np = %.3f', significance, p_value), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12, 'Color', 'blue');
b.FaceColor = 'flat';
b.CData(1, :) = [0.0, 0.6, 0.3]; 
b.CData(2, :) = [0.8, 0.1, 0.2]; 
set(gca, 'XTickLabel', {'GCaMP', 'RCaMP'});
ylabel('Accuracy (%)');
title('SVM Decoding');
yline(50, '--k', 'Chance', 'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
hold off;


function result = asdf(cD)

dlc = cD.DLC(2:end,:);
gcamp = cD.GCaMP;
rcamp = cD.RCaMP;
time = [0:1/60.241:(1/60.241)*size(rcamp,1)]';

stime=(dlc(1,1)-cD.syncframe)*(1/29.99);

[~,sind]=min(abs(time-stime));
gcamp = gcamp(sind:end,1);
rcamp = rcamp(sind:end,1);

gcamp = (gcamp - nanmean(gcamp))/nanstd(gcamp);
rcamp = (rcamp - nanmean(rcamp))/nanstd(rcamp);

dorictime = [0:1/60.241:(1/60.241)*size(rcamp,1)]';
dlctime = [0:1/29.99:(1/29.99)*size(dlc,1)]';

oarange =cD.OArange;
oatime=(oarange-cD.syncframe)*(1/29.99);
for i = 1 : size(oatime,1)
    temp = [];
    for j = 1 : size(oatime,2)
        [~,mind]=min(abs(time-oatime(i,j)));
        temp = [temp,mind];
    end
    oasyncdoric(i,:) = temp;
    clear temp
end
oasyncdoric = oasyncdoric - sind+1;
% OA = 0 CA = 1
svmdata=ones(size(gcamp,1),1);
for i = 1 : size(oasyncdoric,1)
    svmdata(oasyncdoric(i,1):oasyncdoric(i,2),1)=0;
end

rdata = [rcamp,svmdata];
gdata = [gcamp,svmdata];

result.rdata = rdata;
result.gdata = gdata;
end
