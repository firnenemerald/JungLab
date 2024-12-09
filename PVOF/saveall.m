function saveall(folpath,genpath)
fullfolpath = fullfile(folpath,genpath);
if ~exist(fullfolpath, 'dir')
   mkdir(fullfolpath);
end
figures = findall(0, 'Type', 'figure');
for i = 1:length(figures)
    if figures(i).Name ~= "MATLAB App"
    figureName = sprintf('Figure_%d.jpg', figures(i).Number);
    saveas(figures(i), fullfile(fullfolpath, figureName), 'jpeg');
    end
end
close all
end