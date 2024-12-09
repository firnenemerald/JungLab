load("Arearange.mat")
load("dlcsmooth.mat")
mergeall;

data = struct2cell(combined);

i = 1;
cD = data{i};

oarange=cD.OArange;
dlc = cD.DLC(2:end,:);

vid=VideoReader(cD.VideoPath);
vid.CurrentTime = (dlc(1,1)-1)/30;

k = 1
while hasFrame(vid)
    isoa = false;
    for i = 1 : size(oarange,1)
        if dlc(k,1)>=oarange(i,1) && dlc(k,1) <= oarange(i,2)
            isoa = true;
            break;
        end
    end
    frame = readFrame(vid);
    imshow(frame);
    hold on
    if isoa
        scatter(dlc(k,2),dlc(k,3),'r');
    else
        scatter(dlc(k,2),dlc(k,3),'b');
    end
    hold off
    if isoa
        title(['OA',num2str(dlc(k,1))]);
    else
        title(['CA',num2str(dlc(k,1))]);
    end
    pause(0.033)
    k = k+1;
end