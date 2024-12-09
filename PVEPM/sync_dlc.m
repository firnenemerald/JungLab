clear all
load('filereaded_video.mat')

data = struct2cell(filereaded_video);
dataname= fieldnames(filereaded_video);

for i = 1  : size(data,1)
    cD=data{i};
    if strcmp(dataname{i},'PV_1_4_24_02_06_16_23_32_EPM')
        sync = 153;
    elseif strcmp(dataname{i},'PV_1_4_24_02_13_15_42_48_EPM')
        sync =9;
    elseif strcmp(dataname{i},'PV_1_5_24_02_06_16_40_10_EPM')
        sync =427;
    elseif strcmp(dataname{i},'PV_1_5_24_02_13_15_25_51_EPM')
        sync = 328;
    elseif strcmp(dataname{i},'PV_3_1_24_05_17_12_20_20_EPM')
        sync = 39;
    elseif strcmp(dataname{i},'PV_3_2_24_06_17_15_26_51_EPM')
        sync = -13;
    elseif strcmp(dataname{i},'PV_3_4_24_05_30_18_28_04_EPM')
        sync = -15;
    elseif strcmp(dataname{i},'PV_5_1_24_05_30_18_43_19_EPM')
        sync = -28;
    elseif strcmp(dataname{i},'PV_5_2_24_04_25_17_27_17_EPM')
        sync = -3;
    end

    dlc = cD.DLC;
    if sync>=1
        dlc_synced=dlc(find(dlc(:,1)==sync):end,:);
    else
        temp1 = [-28:0]';
        temp1(:,2:13) = nan;
        dlc_synced = [temp1;dlc];
    end

    temp.DLC = dlc_synced;
    temp.syncframe = sync;
    temp.VideoPath = cD.VideoPath;
    temp.Arena = cD.Arena;

    dlcsynced_video.(dataname{i}) = temp;
    clear temp
end

save("dlcsynced_video.mat",'dlcsynced_video');