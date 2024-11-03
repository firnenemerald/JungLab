clear all
load('dlcsynced_video.mat')

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
    temptot=fn_behavcluster_OF_v2(cD.DLC(2:end,:),cD.Arena);
    mobile = [temptot.l_thlocstr1_05,temptot.l_thlocend1_05];
    forward = [temptot.f_thlocstr1_05,temptot.f_thlocend1_05];
    ipsiturn = [temptot.t_ipsi];
    contraturn = [temptot.t_cont];
    stop = [temptot.s_thstopstr03_015,temptot.s_thstopend03_015];
    temp.mobile = mobile;
    temp.forward = forward;
    temp.ipsiturn = ipsiturn;
    temp.contraturn = contraturn;
    temp.stop = stop;
    result.(dataname{i}) = temp;
    clear temp temptot mobile forward ipsiturn contraturn stop
end
end