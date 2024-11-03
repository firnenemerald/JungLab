list = who;

eval(['dataname=fieldnames(',list{1},');']);

for i = 1 : size(dataname,1)
    for j = 1 : size(list,1)
        eval(['data',num2str(j),'=struct2cell(',list{j},'.(dataname{i}));']);
        eval(['dataname',num2str(j),'=fieldnames(',list{j},'.(dataname{i}));']);
    end
    for j = 1 : size(list,1)
        eval(['cdata = data',num2str(j),';']);
        eval(['cdataname = dataname',num2str(j),';']);
        for k = 1 : size(cdata,1)
            temp.(cdataname{k}) = cdata{k};
        end
        clear cdata cdataname
    end
    combined.(dataname{i}) = temp;
    clear temp
end

clearvars -except combined