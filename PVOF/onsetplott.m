clear all
load("onsetplotresult.mat");

data = struct2cell(result);

for i = 1 : size(data,1)
    for j = 1 : size(data{i}.GMO,2)
        temp1(1,j) = nanmean(data{i}.GMO(:,j));
        temp2(1,j) = nanmean(data{i}.RMO(:,j));
    end
    GMO(i,:) = temp1;
    RMO(i,:) = temp2;
    clear temp1 temp2

    for j = 1 : size(data{i}.GFO,2)
        temp1(1,j) = nanmean(data{i}.GFO(:,j));
        temp2(1,j) = nanmean(data{i}.RFO(:,j));
    end
    GFO(i,:) = temp1;
    RFO(i,:) = temp2;
    clear temp1 temp2

    for j = 1 : size(data{i}.GIO,2)
        temp1(1,j) = nanmean(data{i}.GIO(:,j));
        temp2(1,j) = nanmean(data{i}.RIO(:,j));
    end
    GIO(i,:) = temp1;
    RIO(i,:) = temp2;
    clear temp1 temp2

    for j = 1 : size(data{i}.GCO,2)
        temp1(1,j) = nanmean(data{i}.GCO(:,j));
        temp2(1,j) = nanmean(data{i}.RCO(:,j));
    end
    GCO(i,:) = temp1;
    RCO(i,:) = temp2;
    clear temp1 temp2

    for j = 1 : size(data{i}.GSO,2)
        temp1(1,j) = nanmean(data{i}.GSO(:,j));
        temp2(1,j) = nanmean(data{i}.RSO(:,j));
    end
    GSO(i,:) = temp1;
    RSO(i,:) = temp2;
    clear temp1 temp2
end

f_plotrg(GMO,RMO,'mobile');
f_plotrg(GFO,RFO,'forward');
f_plotrg(GIO,RIO,'right turn');
f_plotrg(GCO,RCO,'left turn');
f_plotrg(GSO,RSO,'stop');