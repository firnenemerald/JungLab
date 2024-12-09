clear all
load("onsetresults.mat");

data = struct2cell(results);

%% signal nan 처리
troa = [];
tgoa = [];
trca = [];
tgca = [];
for i = 1 : size(data,1)
    temp=data{i}.RCaMP_OAonsetsig(:,31:121);
    temp = temp(~any(isnan(temp), 2), :);
    roa{i,1} = temp;
    troa = [troa;temp];
    clear temp

    temp=data{i}.GCaMP_OAonsetsig(:,31:121);
    temp = temp(~any(isnan(temp), 2), :);
    goa{i,1} = temp;
    tgoa = [tgoa;temp];
    clear temp

    temp=data{i}.RCaMP_CAonsetsig(:,31:121);
    temp = temp(~any(isnan(temp), 2), :);
    rca{i,1} = temp;
    trca = [trca;temp];
    clear temp

    temp=data{i}.GCaMP_CAonsetsig(:,31:121);
    temp = temp(~any(isnan(temp), 2), :);
    gca{i,1} = temp;
    tgca = [tgca;temp];
    clear temp
end