clear all
load('dlcsmooth.mat');
load('errorfixed.mat');
mergeall;

data = struct2cell(combined);
dataname = fieldnames(combined);

for i = 1 : size(data,1)
    cD = data{i};
    dname = dataname{i};
    Heatmap.(dname) = asdf(cD);
end

save('norm_hmap.mat','Heatmap')

function result = asdf(cD)

dlc = cD.DLC(1:end,:);
gcamp = cD.GCaMP;
rcamp = cD.RCaMP;
time = [0:1/60.241:(1/60.241)*size(rcamp,1)]';

stime=(dlc(1,1)-cD.syncframe)*(1/29.99);

[~,sind]=min(abs(time-stime));
gcamp = gcamp(sind:end,1);
rcamp = rcamp(sind:end,1);

dorictime = [0:1/60.241:(1/60.241)*size(rcamp,1)]';
dlctime = [0:1/29.99:(1/29.99)*size(dlc,1)]';

head = dlc(:,2:3);

[head01,gcamp01,rcamp01] = bywindow_doric(dlctime,dorictime,head,gcamp,rcamp,0.1);
[head05,gcamp05,rcamp05] = bywindow_doric(dlctime,dorictime,head,gcamp,rcamp,0.5);
[head1,gcamp1,rcamp1] = bywindow_doric(dlctime,dorictime,head,gcamp,rcamp,1);

hmap01=da_heatmap(head01,gcamp01,rcamp01);
hmap05 =da_heatmap(head05,gcamp05,rcamp05);
hmap1 = da_heatmap(head1,gcamp1,rcamp1);

normhmap01=normhmap(hmap01,cD.Arena);
normhmap05=normhmap(hmap05,cD.Arena);
normhmap1=normhmap(hmap1,cD.Arena);

result.normhmap01 = normhmap01;
result.normhmap05 = normhmap05;
result.normhmap1 = normhmap1;   
end
