clear all
load('behavclustered.mat')
%load('bclust.mat')
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

save("onsetplotresultv2.mat",'result');

%%
clear all
load("onsetplotresultv2.mat");

data = struct2cell(result);
GMOt = [];
RMOt = [];
GSOt = [];
RSOt = [];
tsovel = [];
tmovel = [];
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
    for j = 1 : size(data{i}.GSO,2)
        temp1(1,j) = nanmean(data{i}.GSO(:,j));
        temp2(1,j) = nanmean(data{i}.RSO(:,j));
    end
    GSO(i,:) = temp1;
    RSO(i,:) = temp2;
    clear temp1 temp2

    GSOt = [GSOt;data{i}.GSO];
    RSOt =[RSOt;data{i}.RSO];

    tmovel = [tmovel;data{i}.mobileonsetvel];
    tsovel = [tsovel;data{i}.stoponsetvel];
end

% f_plotrg(GMO,RMO,'mobile');
% f_plotrg(GFO,RFO,'forward');
% f_plotrg(GIO,RIO,'right turn');
% f_plotrg(GCO,RCO,'left turn');
% f_plotrg(GSO,RSO,'stop');

GMOt=GMOt(~any(isnan(GMOt), 2), :);
RMOt=RMOt(~any(isnan(RMOt), 2), :);
GSOt=GSOt(~any(isnan(GSOt), 2), :);
RSOt=RSOt(~any(isnan(RSOt), 2), :);

f_plotrg(GMOt,RMOt,tmovel,'mobile','sem');

f_plotrg(GSOt,RSOt,tsovel,'stop','sem');

f_plotrg(GMOt,RMOt,tmovel,'mobile','std');

f_plotrg(GSOt,RSOt,tsovel,'stop','std');


for i = 1 : size(GMOt,1)
    GMOpreom(i,1)=mean(GMOt(i,1:60));
end
[~,sortind]=sort(GMOpreom,'descend');
GMOt = GMOt(sortind,:);

sortind = [];
for i = 1 : size(RMOt,1)
    RMOpreom(i,1)=mean(RMOt(i,1:60));
end
[~,sortind]=sort(RMOpreom,'descend');
RMOt = RMOt(sortind,:);

sortind = [];
for i = 1 : size(GSOt,1)
    GSOpreom(i,1)=mean(GSOt(i,1:60));
end
[~,sortind]=sort(GSOpreom,'descend');
GSOt = GSOt(sortind,:);

sortind = [];
for i = 1 : size(RSOt,1)
    RSOpreom(i,1)=mean(RSOt(i,1:60));
end
[~,sortind]=sort(RSOpreom,'descend');
RSOt = RSOt(sortind,:);

figure;
x= -1 : 1/60 : 1 ;
imagesc(x, 1:size(GSOt, 1), GSOt); 
colormap('jet'); 
colorbar;

hold on;
plot([0 0], ylim, 'k--', 'LineWidth', 1.5);

xlabel('Time (s)');
ylabel('behavior NO.');
title('GCaMP: stop onset');
grid on;
hold off;

figure;
x= -1 : 1/60 : 1 ;
imagesc(x, 1:size(RSOt, 1), RSOt); 
colormap('jet'); 
colorbar;

hold on;
plot([0 0], ylim, 'k--', 'LineWidth', 1.5);

xlabel('Time (s)');
ylabel('behavior NO.');
title('RCaMP: stop onset');
grid on;
hold off;

figure;
x= -1 : 1/60 : 1 ;
imagesc(x, 1:size(GMOt, 1), GMOt); 
colormap('jet'); 
colorbar;

hold on;
plot([0 0], ylim, 'k--', 'LineWidth', 1.5);

xlabel('Time (s)');
ylabel('behavior NO.');
title('GCaMP: mobile onset');
grid on;
hold off;

figure;
x= -1 : 1/60 : 1 ;
imagesc(x, 1:size(RMOt, 1), RMOt); 
colormap('jet'); 
colorbar;

hold on;
plot([0 0], ylim, 'k--', 'LineWidth', 1.5);

xlabel('Time (s)');
ylabel('behavior NO.');
title('RCaMP: mobile onset');
grid on;
hold off;

path = uigetdir;
saveall(path,'onsetplot_h')


function result=asdf(cD)
dlc=cD.DLC;
if cD.syncframe < 1
dlc=dlc(find(dlc(:,1)==1):end,:);
end
rcamp = cD.RCaMP;
gcamp = cD.GCaMP;
time = [0:1/60.241:(size(rcamp,1)-1)*(1/60.241)]';
starttime = (dlc(1,1)-cD.syncframe) * (1/29.99);
bodyvel=cD.velocity;

[~,mind]=min(abs(time-starttime));

rcamp = (rcamp - nanmean(rcamp))/nanstd(rcamp);
gcamp = (gcamp - nanmean(gcamp))/nanstd(gcamp);

time = time(mind:end,1);
time = time - time(1,1);
mobile = cD.mobile;
stop = cD.stop;

useind = [];
for i = 1:  size(mobile,1)
    if mobile(i,1)>30 && mobile(i,2) < size(time,1)
        useind = [useind,i];
    end
end
mobile = mobile(useind,:);



for i = 1 : size(mobile,1)
    mobileonsetvel(i,:) = bodyvel(mobile(i,1)-30:mobile(i,1)+30);
end

for i = 1 : size(stop,1)
    stoponsetvel(i,:) = bodyvel(stop(i,1)-30:stop(i,1)+30);
end

mobile_doric = logi2doric(mobile,time);
stop_doric = logi2doric(stop,time);

mobile_doric=eventrangefilter(mobile_doric,30);
stop_doric=eventrangefilter(stop_doric,30);

result.GMO=geteventonset(mobile_doric,gcamp);
result.RMO=geteventonset(mobile_doric,rcamp);
result.GSO=geteventonset(stop_doric,gcamp);
result.RSO=geteventonset(stop_doric,rcamp);
result.stoponsetvel = stoponsetvel;
result.mobileonsetvel = mobileonsetvel;

end