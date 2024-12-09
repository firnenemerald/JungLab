clear all;load('bclust.mat');load("errorfixed.mat");load("dlcsynced_video.mat");load("onsetplotresult.mat");
mergeall;

data = struct2cell(combined);
dataname= fieldnames(combined);
session = 1;
currentSession = data{session};
disp(dataname{session})


%%
mobile=currentSession.mobile;
forward=currentSession.forward;
ipsiturn=currentSession.ipsiturn;
contraturn=currentSession.contraturn;
stop=currentSession.stop;
dlc = currentSession.DLC;
indd=min(find(~isnan(dlc(:,2))));

dlc1 = dlc(indd:end,:);
dlc2 = dlc(1:indd-1,:);

if ~isempty(dlc2)
    frameplus=dlc1(1,1) - dlc2(1,1) ;
else
    frameplus = 0;
end
vid = VideoReader(currentSession.VideoPath);

%%
mobile = mobile-frameplus;

gonext = true;
for i = 1 : size(mobile,1)
    gonext = true;
    while gonext
        
        vid.CurrentTime = (mobile(i,1)-31)/vid.FrameRate;
        figure;
        while mean(vid.CurrentTime*vid.FrameRate) <= mobile(i,1)+30;
            frame= readFrame(vid);
            imshow(frame);
            if mean(vid.CurrentTime*vid.FrameRate)< mobile(i,1)
                title(['pre-onset:',num2str(mean(vid.CurrentTime*vid.FrameRate))]);
            else
                title(['post-onset:',num2str(mean(vid.CurrentTime*vid.FrameRate))]);
            end
            pause(0.033);
        end
        qans=questdlg('gonext','gonext?','yes','no','yes');
        switch qans
            case 'yes'
                gonext = false;
        end
        close all
    end
end
