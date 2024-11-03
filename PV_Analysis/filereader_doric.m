clear all
load("pvdual_path.mat")

for i = 1  : size(exppath,1)
    CurrentPath = exppath{i};
    name=CurrentPath(max(find(CurrentPath == '\'))+1:end);
    list = dir(CurrentPath);
    for j = 1 : size(list,1)
        filename=list(j).name;
        Arena = [];
        if endsWith(filename,'0.csv')
            if ~endsWith(filename(1:max(find(filename=='_'))-1),'shuffle1')
                aa = readcell(fullfile(list(j).folder,list(j).name));
                time = cell2mat(aa(2:end,1));
                data1 = cell2mat(aa(2:end,2));
                clear aa
            end
        elseif endsWith(filename,'1.csv')
            aa = readcell(fullfile(list(j).folder,list(j).name));
            data2 = cell2mat(aa(2:end,2));
            clear aa
        elseif endsWith(filename,'2.csv')
            aa = readcell(fullfile(list(j).folder,list(j).name));
            data3 = cell2mat(aa(2:end,2));
            clear aa
        elseif endsWith(filename,'3.csv')
            aa = readcell(fullfile(list(j).folder,list(j).name));
            data4 = cell2mat(aa(2:end,2));
            clear aa
        
        end
    end

    go = true;

    
    try
        GCaMP = data2 -data1;
        RCaMP = data4 - data3;
        temp.GCaMP = GCaMP;
        temp.RCaMP = RCaMP;
        temp.time=time;
    catch
        disp([name,':doric 파일이 없습니다']);
        go = false;
    end
    if go
    filereaded_doric.(strrep(name,'-','_')) = temp;
    clear temp
    end
    
end

save("filereaded_doric.mat",'filereaded_doric')