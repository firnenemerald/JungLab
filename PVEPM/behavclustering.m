clear all
load('dlcsynced_video.mat');


list = who;

for i = 1 : size(list,1)
    name = list{i}(min(find(list{i}=='_'))+1:end);
    eval(['cM=',list{i},';']);
    result = asdf(cM);
    eval(['behavcluster_',name,'=result;']);
    clear result
end

list2 = who; 

for i = 1:length(list2)
    varName = list2{i}; 
    if ~startsWith(varName, 'behavcluster') 
        clear(varName);
    end
end

clear i list2 varName

save('bclust.mat')

function result=asdf(cM)
data = struct2cell(cM);
dataname = fieldnames(cM);
for i = 1 : size(data,1)
    cD = data{i};
    dlc=cD.DLC;
    arena = cD.Arena;
    arenasize = sqrt((arena(1,1)-arena(2,1))^2 + (arena(1,2)-arena(2,2))^2);
    indd=min(find(~isnan(dlc(:,2))));
    dlc1 = dlc(indd:end,:);
    dlc2 = dlc(1:indd-1,:);
    body = dlc1(:,5:7);
    body_pf = kf_preprocessing(body);
    body_kf = kalmanfilter_h(body_pf);
    body_kf = body_kf(2:end,:);
    body_diff = [diff(body_kf(:,1)),diff(body_kf(:,2))];
    for j = 1 : size(body_diff,1)
        bodyvel(j,1) = sqrt(body_diff(j,1)^2 + body_diff(j,2)^2);
    end
    temptot=fn_behavcluster_OF_v2(dlc1,arenasize);
    if ~isempty(dlc2)
    frameplus=dlc1(1,1) - dlc2(1,1) ;
    else
        frameplus = 0;
    end
    mobile = [temptot.l_thlocstr1_05,temptot.l_thlocend1_05]+frameplus;
    forward = [temptot.f_thlocstr1_05,temptot.f_thlocend1_05]+frameplus;
    ipsiturn = [temptot.t_ipsi]+frameplus;
    contraturn = [temptot.t_cont]+frameplus;
    stop = [temptot.s_thstopstr03_015,temptot.s_thstopend03_015]+frameplus;
    
    temp.mobile = mobile;
    temp.forward = forward;
    temp.ipsiturn = ipsiturn;
    temp.contraturn = contraturn;
    temp.stop = stop;
    temp.velocity = bodyvel;
    result.(dataname{i}) = temp;
    clear temp temptot mobile forward ipsiturn contraturn stop
end
end