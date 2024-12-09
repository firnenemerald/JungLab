clear all
load('bclust.mat')
load("errorfixed.mat");
%load("decaycorrected.mat")
load("dlcsynced_video.mat")

mergeall;

%%
data = struct2cell(combined);
dataname = fieldnames(combined);

for i = 1 :size(data,1)
    cD = data{i};
    dname = dataname{i};
    result.(dname) = asdf(cD);
end

save("onsetplotresult.mat",'result');

%%
clear all
load("onsetplotresult.mat");

data = struct2cell(result);
GMOt = [];
RMOt = [];
GFOt = [];
RFOt = [];
GIOt = [];
RIOt = [];
GCOt = [];
RCOt = [];
GSOt = [];
RSOt = [];
for i = 1 : size(data,1)
    for j = 1 : size(data{i}.GMO,2)
        temp1(1,j) = nanmean(data{i}.GMO(:,j));
        temp2(1,j) = nanmean(data{i}.RMO(:,j));
    end
    GMO(i,:) = temp1;
    RMO(i,:) = temp2;
    clear temp1 temp2
    GMOt = [GMOt;data{i}.GMO];
    RMOt = [RMOt;data{i}.RMO];
    

    for j = 1 : size(data{i}.GFO,2)
        temp1(1,j) = nanmean(data{i}.GFO(:,j));
        temp2(1,j) = nanmean(data{i}.RFO(:,j));
    end
    GFO(i,:) = temp1;
    RFO(i,:) = temp2;
    clear temp1 temp2

    GFOt =[GFOt;data{i}.GFO];
    RFOt =[RFOt;data{i}.RFO];

    for j = 1 : size(data{i}.GIO,2)
        temp1(1,j) = nanmean(data{i}.GIO(:,j));
        temp2(1,j) = nanmean(data{i}.RIO(:,j));
    end
    GIO(i,:) = temp1;
    RIO(i,:) = temp2;
    clear temp1 temp2

    GIOt =[GIOt;data{i}.GIO];
    RIOt = [RIOt;data{i}.RIO];

    for j = 1 : size(data{i}.GCO,2)
        temp1(1,j) = nanmean(data{i}.GCO(:,j));
        temp2(1,j) = nanmean(data{i}.RCO(:,j));
    end
    GCO(i,:) = temp1;
    RCO(i,:) = temp2;
    clear temp1 temp2

    GCOt = [GCOt;data{i}.GCO];
    RCOt = [RCOt;data{i}.RCO];

    for j = 1 : size(data{i}.GSO,2)
        temp1(1,j) = nanmean(data{i}.GSO(:,j));
        temp2(1,j) = nanmean(data{i}.RSO(:,j));
    end
    GSO(i,:) = temp1;
    RSO(i,:) = temp2;
    clear temp1 temp2

    GSOt = [GSOt;data{i}.GSO];
    RSOt =[RSOt;data{i}.RSO];
end

% f_plotrg(GMO,RMO,'mobile');
% f_plotrg(GFO,RFO,'forward');
% f_plotrg(GIO,RIO,'right turn');
% f_plotrg(GCO,RCO,'left turn');
% f_plotrg(GSO,RSO,'stop');

f_plotrg(GMOt,RMOt,'mobile');
f_plotrg(GFOt,RFOt,'forward');
f_plotrg(GIOt,RIOt,'right turn');
f_plotrg(GCOt,RCOt,'left turn');
f_plotrg(GSOt,RSOt,'stop');

path = uigetdir;
saveall(path,'onsetplot_of_ter')


function result=asdf(cD)
dlc=cD.DLC;
rcamp = cD.RCaMP;
gcamp = cD.GCaMP;
time = [0:1/60.241:(size(rcamp,1)-1)*(1/60.241)]';
starttime = (dlc(1,1)-cD.syncframe) * (1/29.99);

[~,mind]=min(abs(time-starttime));

rcamp = zscore(rcamp(mind:end,1));
gcamp = zscore(gcamp(mind:end,1));

mobile = cD.mobile;
forward = cD.forward;
rturn = cD.ipsiturn;
lturn = cD.contraturn;
stop = cD.stop;

mobile_doric = logi2doric(mobile,time);
forward_doric = logi2doric(forward,time);
rturn_doric = logi2doric(rturn,time);
lturn_doric = logi2doric(lturn,time);
stop_doric = logi2doric(stop,time);

mobile_doric=eventrangefilter(mobile_doric,30);
forward_doric=eventrangefilter(forward_doric,30);
rturn_doric=eventrangefilter(rturn_doric,30);
lturn_doric=eventrangefilter(lturn_doric,30);
stop_doric=eventrangefilter(stop_doric,30);

result.GMO=geteventonset(mobile_doric,gcamp);
result.RMO=geteventonset(mobile_doric,rcamp);
result.GFO=geteventonset(forward_doric,gcamp);
result.RFO=geteventonset(forward_doric,rcamp);
result.GIO=geteventonset(rturn_doric,gcamp);
result.RIO=geteventonset(rturn_doric,rcamp);
result.GCO=geteventonset(lturn_doric,gcamp);
result.RCO=geteventonset(lturn_doric,rcamp);
result.GSO=geteventonset(stop_doric,gcamp);
result.RSO=geteventonset(stop_doric,rcamp);

end