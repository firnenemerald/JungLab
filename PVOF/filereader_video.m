clear all
load("pvdual_path.mat")

for i = 1  : size(exppath,1)
    CurrentPath = exppath{i};
    name=CurrentPath(max(find(CurrentPath == '\'))+1:end);
    list = dir(CurrentPath);
    Arena = [];
    for j = 1 : size(list,1)
        filename=list(j).name;
        if endsWith(filename,'labeled.mp4')
            if isempty(Arena)
            vpath = fullfile(list(j).folder,list(j).name);
            vid=VideoReader(vpath);
            vid.CurrentTime = 200;
            frame=readFrame(vid);
            figure;
            imshow(frame);
            title('1->2 긴변으로 점을 찍어주세요')
            while true
                circ=drawcircle;
                qans=questdlg('ok?',...
                    'ok?',...
                    'yes','no','no');
                switch qans
                    case 'yes'
                        Arena = circ.Radius;
                        close all
                        break;
                    case 'no'
                        delete(circ)
                        continue;
                end

            end
            end
        end
        if endsWith(filename,'0.csv')
            if endsWith(filename(1:max(find(filename=='_'))-1),'shuffle1')
                aa = readcell(fullfile(list(j).folder,list(j).name));
                DLC=cell2mat(aa(4:end,:));
                clear aa
            end
        end
    end
    go = true;
        try
            temp.Arena = Arena;
            temp.VideoPath = vpath;
        catch
            disp([name,':video 파일이 없습니다']);
            go = false;
        end
        try
            temp.DLC = DLC;
        catch
            disp([name,':DLC 파일이 없습니다']);
            go = false;
        end
        if go
        filereaded_video.((strrep(name,'-','_'))) = temp;
        clear temp
        end
end

save("filereaded_video.mat",'filereaded_video')