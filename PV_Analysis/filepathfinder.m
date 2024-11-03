

path = uigetdir;
list = dir(path);

tind = [];
for i = 1 : size(list,1)
    if ~endsWith(list(i).name,'.') && ~endsWith(list(i).name,'..')
        tind = [tind,i];
    end
end
list = list(tind);

useind = [];
for i = 1 : size(list,1)
    if endsWith(list(i).name,EXPname) 
        useind = [useind,i];
    end
end

explist = list(useind);

for i = 1 : size(explist)
    exppath{i,1} = fullfile(explist(i).folder,explist(i).name);
end

save("pvdual_path.mat",'exppath')
clear all
