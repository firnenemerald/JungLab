clear all
load('dlcsynced_video.mat')

data = struct2cell(dlcsynced_video);
dataname= fieldnames(dlcsynced_video);

for i = 1  : size(data,1)
    cD=data{i};
    dname = dataname{i};
    temp= asdf(cD,dname);
    dlcsmooth.(dname).DLC = temp;
    dlcsmooth.(dname).DLC;
    dlcsmooth.(dname).syncframe = cD.syncframe;
    dlcsmooth.(dname).VideoPath = cD.VideoPath;
    dlcsmooth.(dname).Arena = cD.Arena;
    clear temp
end

save("dlcsmooth.mat",'dlcsmooth')

function result = asdf(cD,dname)
dlc=cD.DLC;
if strcmp(dname,'PV_1_4_24_02_06_16_23_32_EPM')
        useind = 588;
    elseif strcmp(dname,'PV_1_4_24_02_13_15_42_48_EPM')
        useind =280;
    elseif strcmp(dname,'PV_1_5_24_02_06_16_40_10_EPM')
        useind =670;
    elseif strcmp(dname,'PV_1_5_24_02_13_15_25_51_EPM')
        useind = 328;
    elseif strcmp(dname,'PV_3_1_24_05_17_12_20_20_EPM')
        useind = 39;
    elseif strcmp(dname,'PV_3_2_24_06_17_15_26_51_EPM')
        useind = -13;
    elseif strcmp(dname,'PV_3_4_24_05_30_18_28_04_EPM')
        useind = -15;
    elseif strcmp(dname,'PV_5_1_24_05_30_18_43_19_EPM')
        useind = -28;
    elseif strcmp(dname,'PV_5_2_24_04_25_17_27_17_EPM')
        useind = -3;
end

dlc=dlc(find(dlc(:,1)==useind):end,:);
aaaa=min(find(~isnan(dlc(:,2))));
dlc1 = dlc(aaaa:end,:);
dlc2 = dlc(1:aaaa-1,:);

head = dlc1(:,2:4);
body = dlc1(:,5:7);
tail = dlc1(:,8:10);

head1=kf_preprocessing(head);
body1=kf_preprocessing(body);
tail1=kf_preprocessing(tail);

result=[dlc1(:,1),kalmanfilter_h(head1),kalmanfilter_h(body1),kalmanfilter_h(tail1)];
clear dlc
result = [dlc2(:,[1,2,3,5,6,8,9]);result];

end