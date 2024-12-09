path = uigetdir;

list = dir(path);

for i = 1 : size(list,1)
    if endsWith(list(i).name,'labeled.mp4')
        vidpath = fullfile(list(i).folder,list(i).name);
    elseif endsWith(list(i).name,'000.csv')
        dlcpath = fullfile(list(i).folder,list(i).name);
    end
end

dlc1 = readcell(dlcpath);
dlc = cell2mat(dlc1(4:end,:));

startframe = 100;

vid = VideoReader(vidpath);
vid.CurrentTime = startframe/30;

while hasFrame(vid)
    frame = readFrame(vid);
    imshow(frame)
    hold on
    scatter(dlc(startframe,2),dlc(startframe,3));
    scatter(dlc(startframe,5),dlc(startframe,6));
    scatter(dlc(startframe,8),dlc(startframe,9));
    hold off
    startframe = startframe+1;
    title(num2str(startframe));
    pause(0.033)
end