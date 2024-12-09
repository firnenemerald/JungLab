clear all
load('dlcsynced_video.mat')

data = struct2cell(dlcsynced_video);
dataname= fieldnames(dlcsynced_video);

for i = 1 : size(data,1)
    name = dataname{i};
    cM = data{i};
    temp = asdf(cM);
    behavclustered.(name) = temp;
    clear temp;
end

save('behavclustered.mat','behavclustered');


function result=asdf(cM)
dlc = cM.DLC;
arena = cM.Arena;
arenasize = sqrt((arena(1,1)-arena(2,1))^2 + (arena(1,2)-arena(2,2))^2);
vidpath = cM.VideoPath;

if cM.syncframe > 0
head = dlc(:,2:4);
body = dlc(:,5:7);
else
    head = dlc(find(dlc(:,1)==1):end,2:4);
    body = dlc(find(dlc(:,1)==1):end,5:7);
end

head_kfp=kf_preprocessing(head);
body_kfp=kf_preprocessing(body);

head_kf=kalmanfilter_h(head);
body_kf=kalmanfilter_h(body);

% vid = VideoReader(vidpath);
% vid.CurrentTime = cM.syncframe/vid.FrameRate;
% dlcrow = 2;
% figure;
% while hasFrame(vid)
% frame = readFrame(vid);
% imshow(frame);
% hold on
% a=scatter(head_kf(dlcrow,1),head_kf(dlcrow,2),'filled','MarkerFaceColor','r');
% b=scatter(body_kf(dlcrow,1),body_kf(dlcrow,2),'filled','MarkerFaceColor','b');
% hold off
% dlcrow = dlcrow+1;
% pause(0.033);
% end

head_kf = head_kf(2:end,:);
body_kf = body_kf(2:end,:);

head_diff = [diff(head_kf(:,1)),diff(head_kf(:,2))];
body_diff = [diff(body_kf(:,1)),diff(body_kf(:,2))];

for i = 1 : size(head_diff)
    headvel(i,1) = sqrt((head_diff(i,1))^2 + (head_diff(i,2))^2);
    bodyvel(i,1) = sqrt((body_diff(i,1))^2 + (body_diff(i,2))^2);
end

headvel = headvel*(700/arenasize);
bodyvel = bodyvel*(700/arenasize);

%plot(bodyvel)

over2=find(bodyvel > 2);
over2se=startend(over2);
over08=find(bodyvel > 0.8);
over08se=startend(over08);

useind = [];
for i = 1 : size(over08se,1)
    temp = [];
    temp=find(over2se(:,1)>=over08se(i,1) & over2se(:,2)<=over08se(i,2));
    if ~isempty(temp)
        useind = [useind,i];
    end
end

accrange = over08se(useind,:);
useind = [];
useind1 = find(accrange(:,1)>30);
useind2 =find(accrange(:,2)<size(bodyvel,1)-30);
useind3 = find([accrange(:,2)-accrange(:,1)]>30);
useind=intersect(intersect(useind1,useind2),useind3);
accrange = accrange(useind,:);

k = 2;
while true
    try
        if (accrange(k,1) - accrange(k-1,2))<15
            accrange(k-1,:) = [accrange(k-1,1),accrange(k,2)];
            accrange(k,:) = [];
        else
            k = k+1;
        end
    catch
        break;
    end
end

useind = [];
for i = 1 : size(accrange,1)
    tbodyloc = body_kf(accrange(i,1),:);
    theadloc = head_kf(accrange(i,1),:);
    tbodyloc15f = body_kf(accrange(i,1)+15,:);
    tbhvec=theadloc-tbodyloc;
    tmovevec = tbodyloc15f-tbodyloc;
    dot_product = dot(tbhvec, tmovevec, 2); 

    norm_tbhvec = vecnorm(tbhvec, 2, 2); 
    norm_tmovevec = vecnorm(tmovevec, 2, 2); 

    cos_theta = dot_product ./ (norm_tbhvec .* norm_tmovevec);

    cos_theta = min(max(cos_theta, -1), 1);

    angles_in_degrees = acosd(cos_theta);
    if angles_in_degrees<90
        useind = [useind,i];
    end
end
accrange = accrange(useind,:);

for i = 1 : size(accrange,1)
    acconsetvel(i,:) = bodyvel(accrange(i,1)-30:accrange(i,1)+30);
end

for i = 1: size(acconsetvel,2)
    accovmean(1,i) = mean(acconsetvel(:,i));
end

% x= -1:1/30:1;
% plot(x, accovmean, 'b', 'LineWidth', 1.5); 
% hold on;
% 
% xline(0, 'k--', 'LineWidth', 1.5);
% 
% xlabel('Time (s)');
% ylabel('Mean Acceleration Onset Velocity');
% title('Acceleration Onset Velocity');
% grid on;
% hold off;


under1 = find(bodyvel<1);
under1se = startend(under1);
under2 = find(bodyvel<2);
under2se = startend(under2);

useind = [];
for i = 1 : size(under2se,1)
    temp = [];
    temp=find(under1se(:,1)>=under2se(i,1) & under1se(:,2)<=under2se(i,2));
    if ~isempty(temp)
        useind = [useind,i];
    end
end

strange = under2se(useind,:);
useind = [];
useind1 = [];
useind2 = [];
useind3 = [];
useind1 = find(strange(:,1)>30);
useind2 =find(strange(:,2)<size(bodyvel,1)-30);
useind3 = find([strange(:,2)-strange(:,1)]>30);
useind=intersect(intersect(useind1,useind2),useind3);
strange = strange(useind,:);

k = 2;
while true
    try
        if (strange(k,1) - strange(k-1,2))<15
            strange(k-1,:) = [strange(k-1,1),strange(k,2)];
            strange(k,:) = [];
        else
            k = k+1;
        end
    catch
        break;
    end
end


% x= -1:1/30:1;
% for i = 1 : size(strange,1)
%     stonsetvel(i,:) = bodyvel(strange(i,1)-30:strange(i,1)+30);
% end
% 
% for i = 1: size(acconsetvel,2)
%     stovmean(1,i) = mean(stonsetvel(:,i));
% end
% 
% plot(x, stovmean, 'b', 'LineWidth', 1.5); 
% hold on;
% 
% xline(0, 'k--', 'LineWidth', 1.5);
% 
% xlabel('Time (s)');
% ylabel('Mean Acceleration Onset Velocity');
% title('stop Onset Velocity');
% grid on;
% hold off;

useinds = [];
for i = 1 : size(strange,1)
    temp=find(accrange(:,1)<=strange(i,1)-15 & accrange(:,2)>strange(i,1));
    if ~isempty(temp)
        useinds = [useinds,i];
    end
end

useinda = [];
for i = 1 : size(accrange,1)
    temp=find(strange(:,1)<=accrange(i,1)-15 & strange(:,2)>accrange(i,1));
    if ~isempty(temp)
        useinda = [useinda,i];
    end
end

strange = strange(useinds,:);
accrange = accrange(useinda,:);
% 
% vid = VideoReader(vidpath);
% accstartind=accrange(:,1)+cM.syncframe + 1;
% cind = accstartind(1,1);
% vid.CurrentTime = (cind-30)/vid.FrameRate;
% figure;
% while hasFrame(vid)
% frame = readFrame(vid);
% imshow(frame);
% titletxt = round(vid.CurrentTime*vid.FrameRate);
% if titletxt > cind
%     title(['postonset',num2str(titletxt)]);
% else
%     title(['preonset',num2str(titletxt)]);
% end
% pause(0.033);
% end

result.mobile = accrange;
result.stop = strange;
result.velocity = bodyvel;

end