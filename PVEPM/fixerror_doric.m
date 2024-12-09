clear all
load("filereaded_doric.mat");
try
load("errorfixed.mat")
catch
end
data = struct2cell(filereaded_doric);
dataname= fieldnames(filereaded_doric);

for i = 1  : size(data,1)
    %%
    cD=data{i};
    dname = dataname{i};
    errorfixed_doric.(dname)=asdf(cD);
    %%
end

save('errorfixed.mat','errorfixed_doric')


function result=asdf(cD)
gcamp1=cD.GCaMP;
rcamp1=cD.RCaMP;

gcamp = gcamp1;
rcamp = rcamp1;

figure('units','normalized','outerposition',[0 0 1 1]);
while true
    clf; 
    p = plot(gcamp, 'g'); 
    rect = drawrectangle;

    startIdx = round(rect.Position(1,1));
    if startIdx >= 1
        zgcamp = gcamp(startIdx:startIdx + round(rect.Position(1,3)), 1);
    else
        zgcamp = gcamp(1:round(rect.Position(1,1) + rect.Position(1,3)), 1);
    end

    p=plot(zgcamp,'g');

    while true
        [x, y] = ginput(2);
        hold on;
        k = scatter(x, y, 'r'); 
        hold off;

        qans = questdlg('OK?', 'OK?', 'yes', 'no','nochange', 'no');
        switch qans
            case 'yes'
                x = round(x) + startIdx - 1;
                if x(1) >=1
                gcamp(x(1):x(2)) = nan; 
                nandiff = gcamp(x(1)-1) - gcamp(x(2)+1);
                else
                    gcamp(1:x(2)) = nan;
                    nandiff = 0;
                end
                
                gcamp(x(2)+1:end) = gcamp(x(2)+1:end) + nandiff;
                break;
            case 'no'
                delete(k); 
            case 'nochange'
                break;
        end
    end

 
    clf; 
    p=plot(gcamp, 'g'); 

    qans2 = questdlg('continue?', 'continue?', 'yes', 'no', 'no');
    switch qans2
        case 'yes'
            continue;
        case 'no'
            close all
            clear p
            break;
    end
    clear x y startIdx
end

figure('units','normalized','outerposition',[0 0 1 1]);
while true
    clf; 
    p = plot(rcamp, 'r'); 
    rect = drawrectangle;

    startIdx = round(rect.Position(1,1));
    if startIdx >= 1
        if startIdx + round(rect.Position(1,3)) <=size(rcamp,1)
           zrcamp = rcamp(startIdx:startIdx + round(rect.Position(1,3)), 1);
        else
            zrcamp = rcamp(startIdx:end, 1);
        end
    else
        zrcamp = rcamp(1:round(rect.Position(1,1) + rect.Position(1,3)), 1);
    end

    p=plot(zrcamp,'r');

    while true
        [x, y] = ginput(2);
        hold on;
        k = scatter(x, y, 'r'); 
        hold off;

        qans = questdlg('OK?', 'OK?', 'yes', 'no','nochange', 'no');
        switch qans
            case 'yes'
                x = round(x) + startIdx - 1;
                if x(2) <= size(rcamp,1)
                   rcamp(x(1):x(2)) = nan; 
                   nandiff = rcamp(x(1)-1) - rcamp(x(2)+1);
                   rcamp(x(2)+1:end) = rcamp(x(2)+1:end) + nandiff;
                else
                    rcamp(x(1):end) = nan; 
                end
                break;
            case 'no'
                delete(k); 
            case 'nochange'
                break;
        end
    end

 
    clf; 
    p=plot(rcamp, 'r'); 

    qans2 = questdlg('continue?', 'continue?', 'yes', 'no', 'no');
    switch qans2
        case 'yes'
            continue;
        case 'no'
            close all
            break;
    end
    clear x y startIdx
end

result.GCaMP = gcamp;
result.RCaMP = rcamp;

end
