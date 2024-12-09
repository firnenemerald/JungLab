clear all
load('SVMdata.mat');
gcaedge = gcaedge([2,4,5,6,7,9],1);
goaedge = goaedge([2,4,5,6,7,9],1);
rcaedge = rcaedge([2,4,5,6,7,9],1);
roaedge = roaedge([2,4,5,6,7,9],1);


for t= 1 : 100
% ca = 0 oa = 1
for i = 1 : size(gcaedge,1)
    temprperm=randperm(size(goaedge{i},1));
    trainind = temprperm(1:floor(size(goaedge{i},1)/2));
    testind = temprperm(floor(size(goaedge{i},1)/2)+1:end);
    temprotrain(:,1) = goaedge{i,1}(trainind);
    temprotest(:,1) = goaedge{i,1}(testind);
    temprotrain = [temprotrain,ones(size(temprotrain,1),1)];
    temprotest = [temprotest,ones(size(temprotest,1),1)];
    clear temprperm trainind testind
    temprperm=randperm(size(gcaedge{i},1));
    trainind = temprperm(1:floor(size(goaedge{i},1)/2));
    testind = temprperm(floor(size(goaedge{i},1)/2)+1:end);
    temprctrain(:,1) = gcaedge{i,1}(trainind);
    temprctest(:,1) = gcaedge{i,1}(testind);
    temprctrain = [temprctrain,zeros(size(temprctrain,1),1)];
    temprctest = [temprctest,zeros(size(temprctest,1),1)];
    clear temprperm trainind testind
    gtrain{i,1} = [temprotrain;temprctrain];
    gtest{i,1} =[temprotest;temprctest];
    clear temprctest temprctrain temprotest temprotrain
end

for i = 1 : size(rcaedge,1)
    temprperm=randperm(size(roaedge{i},1));
    trainind = temprperm(1:floor(size(roaedge{i},1)/2));
    testind = temprperm(floor(size(roaedge{i},1)/2)+1:end);
    temprotrain(:,1) = roaedge{i,1}(trainind);
    temprotest(:,1) = roaedge{i,1}(testind);
    temprotrain = [temprotrain,ones(size(temprotrain,1),1)];
    temprotest = [temprotest,ones(size(temprotest,1),1)];
    clear temprperm trainind testind
    temprperm=randperm(size(rcaedge{i},1));
    trainind = temprperm(1:floor(size(roaedge{i},1)/2));
    testind = temprperm(floor(size(roaedge{i},1)/2)+1:end);
    temprctrain(:,1) = rcaedge{i,1}(trainind);
    temprctest(:,1) = rcaedge{i,1}(testind);
    temprctrain = [temprctrain,zeros(size(temprctrain,1),1)];
    temprctest = [temprctest,zeros(size(temprctest,1),1)];
    clear temprperm trainind testind
    rtrain{i,1} = [temprotrain;temprctrain];
    rtest{i,1} =[temprotest;temprctest];
    clear temprctest temprctrain temprotest temprotrain
end

npvtrain = [];
for i = 1 : size(gtrain,1)
    npvtrain = [npvtrain;gtrain{i,1}];
end

pvtrain = [];
for i = 1: size(rtrain,1)
    pvtrain = [pvtrain;rtrain{i,1}];
end

tpvtest =[];
tnpvtest =[];
for i = 1 : size(gtest,1)
    tnpvtest = [tnpvtest;gtest{i,1}];
end
for i = 1 : size(rtest,1)
    tpvtest = [tpvtest;rtest{i,1}];
end

SVMmodel_r = fitcsvm(pvtrain(:, 1), pvtrain(:, 2));
SVMmodel_g = fitcsvm(npvtrain(:, 1), npvtrain(:, 2));

predict_tr = predict(SVMmodel_r,tpvtest(:,1));
predict_tg = predict(SVMmodel_g,tnpvtest(:,1));

accuracy_tr(1,t) = sum(predict_tr == tpvtest(:, 2)) / length(tpvtest) * 100;
accuracy_tg(1,t) = sum(predict_tg == tnpvtest(:, 2)) / length(tnpvtest) * 100;

for i = 1 : size(rtest,1)
    predict_g = predict(SVMmodel_g,gtest{i,1}(:,1));
    predict_r = predict(SVMmodel_r,rtest{i,1}(:,1));

    accuracy_r(i,t) = sum(predict_r == rtest{i,1}(:, 2)) / length(rtest{i,1}) * 100;
    accuracy_g(i,t) = sum(predict_g == gtest{i,1}(:, 2)) / length(gtest{i,1}) * 100;
end

clearvars -except accuracy_g accuracy_r accuracy_tg accuracy_tr rcaedge roaedge goaedge gcaedge t
end

save('svmresult.mat')
clear all

load('svmresult.mat')

for i = 1 : size(accuracy_g,1)
    accuracy_rmean(i,1) = mean(accuracy_r(i,:));
    accuracy_gmean(i,1)=mean(accuracy_g(i,:));
end

figure;
b = bar([1, 2], [mean(accuracy_gmean), mean(accuracy_rmean)], 'FaceColor', 'flat');
b.CData(1, :) = [0.4, 0.8, 0.9];
b.CData(2, :) = [1.0, 0.6, 0.6];

ylabel('Accuracy(%)');

hold on
for i = 1:size(accuracy_gmean, 1)
    plot([1, 2], [accuracy_gmean(i,1), accuracy_rmean(i,1)], '-o', 'Color', [0.6, 0.6, 0.6]);
end


[~, p] = ttest(accuracy_gmean- accuracy_rmean);

if p < 0.001
    stars = '***';
elseif p < 0.01
    stars = '**';
elseif p < 0.05
    stars = '*';
else
    stars = 'n.s.'; 
end

yMax = max([mean(accuracy_gmean), mean(accuracy_rmean)]) * 1.1;  
line([1, 2], [yMax, yMax], 'Color', 'k', 'LineWidth', 1.5);

p_text = sprintf('p = %.3f %s', p, stars);
text(1.5, yMax * 1.05, p_text, 'HorizontalAlignment', 'center', 'FontSize', 12);
yline(50, '--k', 'LineWidth', 1);
text(2.1, 50, 'chance', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'FontSize', 12);


hold off

xticks([1, 2]);
xticklabels({'non-PV', 'PV'});

%%
mean_values = [mean(accuracy_tg), mean(accuracy_tr)];
errors = [std(accuracy_tg) / sqrt(length(accuracy_tg)), std(accuracy_tr) / sqrt(length(accuracy_tr))];
[~, p] = ttest(accuracy_tg - accuracy_tr);
if p < 0.001
    stars = '***';
elseif p < 0.01
    stars = '**';
elseif p < 0.05
    stars = '*';
else
    stars = 'n.s.'; 
end
figure;
b = bar([1, 2], mean_values, 'FaceColor', 'flat');
b.CData(1, :) = [0.4, 0.8, 0.9];
b.CData(2, :) = [1.0, 0.6, 0.6];

hold on;
errorbar([1, 2], mean_values, errors, 'k', 'LineStyle', 'none', 'LineWidth', 1);
yMax = max([mean(accuracy_tg), mean(accuracy_tr)]) * 1.1;  
line([1, 2], [yMax, yMax], 'Color', 'k', 'LineWidth', 1.5);

p_text = sprintf('p = %.3f %s', p, stars);
text(1.5, yMax * 1.05, p_text, 'HorizontalAlignment', 'center', 'FontSize', 12);
yline(50, '--k', 'LineWidth', 1);
text(2.1, 50, 'chance', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'FontSize', 12);

hold off;

xticks([1, 2]);
xticklabels({'non-PV', 'PV'});