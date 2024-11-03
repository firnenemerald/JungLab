clear all
load('dlcsmooth.mat')
%%
data = struct2cell(dlcsmooth);
dataname= fieldnames(dlcsmooth);

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

function result = asdf(cD,dname)
dlc=cD.DLC(2:end,:);

head = dlc(:,2:3)*(150/cD.Arena);
body = dlc(:,4:5)*(150/cD.Arena);

diffhead = diff(head);
for i = 1 : size(diffhead,1)
    headvel(i,1) = sqrt(diffhead(i,1)^2 + diffhead(i,2)^2);
end

figure('units','normalized','outerposition',[0 0 1 1]);
plot(headvel)

while true
    clf; 
    p = plot(headvel, 'g'); 
    rect = drawrectangle;

    startIdx = round(rect.Position(1,1));
    if startIdx >= 1
        headvel1 = headvel(startIdx:startIdx + round(rect.Position(1,3)), 1);
    else
        headvel1 = headvel(1:round(rect.Position(1,1) + rect.Position(1,3)), 1);
    end

    p=plot(headvel1,'g');

    while true
        [x, y] = ginput(2);
        hold on;
        k = scatter(x, y, 'r'); 
        hold off;

        qans = questdlg('OK?', 'OK?', 'yes', 'no','nochange', 'no');
        switch qans
            case 'yes'
                x = round(x) + startIdx - 1;
                headvel(x(1):x(2)) = nan; 
                break;
            case 'no'
                delete(k); 
            case 'nochange'
                break;
        end
    end

 
    clf; 
    p=plot(headvel, 'g'); 

    qans2 = questdlg('continue?', 'continue?', 'yes', 'no', 'no');
    switch qans2
        case 'yes'
            continue;
        case 'no'
            close all
            clear p
            break;
    end
    clear x y startIdx
end
%{
vid = VideoReader(cD.VideoPath);

k = 7200;
fps = 30;                     
frame_delay = 1 / fps;        

figure('Position', [100, 100, 1200, 600]);

numFrames =height(dlc); 

start_frame = dlc(1, 1)+k-1;
vid.CurrentTime = (start_frame - 1) / vid.FrameRate;  
for i = k:numFrames
    if hasFrame(vid)
        frame = readFrame(vid); 
     
        imshow(frame); hold on;
        scatter(dlc(i, 2), dlc(i, 3), 'r', 'filled');
        scatter(dlc(i, 4), dlc(i, 5), 'g', 'filled');
        scatter(dlc(i, 6), dlc(i, 7), 'b', 'filled'); 
        hold off;
        title(num2str(dlc(i,1)));

        pause(frame_delay);
    else
        break; 
    end
end
%}
