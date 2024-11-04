clear all ;load("Arearange.mat"); load("errorfixed.mat"); load('dlcsmooth.mat');

mergeall;

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

data = struct2cell(SVM);

rdata = [];
gdata = [];
for i = 1 : size(data,1)
    cv = cvpartition(size(data{i}.rdata,1), 'HoldOut', 0.5);
    rdata_train=[rdata;data{i}.rdata(cv.training,:)];
    gdata_train=[gdata;data{i}.gdata(cv.training,:)];
    rdata_test=[rdata;data{i}.rdata(cv.test,:)];
    gdata_test=[gdata;data{i}.gdata(cv.test,:)];
end

ratio=size(find(rdata_train(:,2) == 0),1) / size(rdata_train,1);
weight = [1,ratio];

SVMmodel_r = fitcsvm(rdata_train(:, 1), rdata_train(:, 2), 'Weights', weight(rdata_train(:, 2) + 1));
SVMmodel_g = fitcsvm(gdata_train(:, 1), gdata_train(:, 2), 'Weights', weight(gdata_train(:, 2) + 1));

predicted_r = predict(SVMmodel_r, rdata_test(:, 1));
predicted_g = predict(SVMmodel_g, gdata_test(:, 1));

accuracy_r = sum(predicted_r == rdata_test(:, 2)) / length(rdata_test) * 100;
accuracy_g = sum(predicted_g == gdata_test(:, 2)) / length(gdata_test) * 100;

figure;
b = bar([accuracy_g, accuracy_r]);
b.FaceColor = 'flat';
b.CData(1, :) = [0.0, 0.6, 0.3]; 
b.CData(2, :) = [0.8, 0.1, 0.2]; 
set(gca, 'XTickLabel', {'GCaMP', 'RCaMP'});
ylabel('Accuracy (%)');
title('SVM Decoding');


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

% OA = 0 CA = 1
svmdata=repmat(1,size(gcamp,1),1);
for i = 1 : size(oasyncdoric,1)
    svmdata(oasyncdoric(i,1):oasyncdoric(i,2),1)=0;
end

rdata = [rcamp,svmdata];
gdata = [gcamp,svmdata];

result.rdata = rdata;
result.gdata = gdata;
end
