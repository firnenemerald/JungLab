clear all
load('dlcsynced_video.mat')
%%
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
        useind = 46;
    elseif strcmp(dname,'PV_3_4_24_05_30_18_28_04_EPM')
        useind = 44;
    elseif strcmp(dname,'PV_5_1_24_05_30_18_43_19_EPM')
        useind = 31;
    elseif strcmp(dname,'PV_5_2_24_04_25_17_27_17_EPM')
        useind = 56;
    elseif strcmp(dname,'PV_1_4_24_02_08_16_04_13_OF')
        useind = 1;
    elseif strcmp(dname,'PV_1_5_24_02_13_15_11_04_OF')
        useind = 1;
    elseif strcmp(dname,'PV_1_5_24_02_15_11_48_55_OF')
        useind = 1;
    elseif strcmp(dname,'PV_3_1_24_05_27_21_13_01_OF')
        useind = 104;
    elseif strcmp(dname,'PV_3_2_24_05_30_20_20_27_OF')
        useind = 206;
    elseif strcmp(dname,'PV_3_4_24_05_30_19_47_22_OF')
        useind = 38;
    elseif strcmp(dname,'PV_5_1_24_05_27_19_38_48_OF')
        useind = 96;
    elseif strcmp(dname,'PV_5_2_24_05_27_20_41_51_OF')
        useind = 164;
end

dlc=dlc(find(dlc(:,1)==useind):end,:);

head = dlc(:,2:4);
body = dlc(:,5:7);
tail = dlc(:,8:10);

head1=kf_preprocessing(head);
body1=kf_preprocessing(body);
tail1=kf_preprocessing(tail);

result=[dlc(:,1),kalmanfilter_h(head1),kalmanfilter_h(body1),kalmanfilter_h(tail1)];

%{
vid = VideoReader(cD.VideoPath);


fps = 30;                     
frame_delay = 1 / fps;        

figure('Position', [100, 100, 1200, 600]);

numFrames = min([height(dlc), height(result)]); 

start_frame = dlc(1, 1);
vid.CurrentTime = (start_frame - 1) / vid.FrameRate;  
for i = 1:numFrames
    if hasFrame(vid)
        frame = readFrame(vid); 
        
        subplot(1, 2, 1);
        imshow(frame); hold on;
        scatter(dlc(i, 2), dlc(i, 3), 'r', 'filled'); 
        scatter(dlc(i, 5), dlc(i, 6), 'g', 'filled');
        scatter(dlc(i, 8), dlc(i, 9), 'b', 'filled'); 
        title('DLC Points');
        hold off;

        subplot(1, 2, 2);
        imshow(frame); hold on;
        scatter(result(i, 2), result(i, 3), 'r', 'filled');
        scatter(result(i, 4), result(i, 5), 'g', 'filled');
        scatter(result(i, 6), result(i, 7), 'b', 'filled'); 
        title('Result Points');
        hold off;
        title(num2str(dlc(i,1)));

        pause(frame_delay);
    else
        break; 
    end
end
%}
end