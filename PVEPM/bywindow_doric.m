function [mod_head,mod_gcamp,mod_rcamp]=bywindow_doric(dlctime,dorictime,head,gcamp,rcamp,timewindow)

numind=floor(min([max(dorictime),max(dlctime)])/timewindow);

for i = 1 : numind
    tempind=find(dlctime>(i-1)*timewindow&dlctime<=i*timewindow);
    mod_head(i,:)=[mean(head(tempind,1)),mean(head(tempind,2))];
    tempind2 = find(dorictime>(i-1)*timewindow&dorictime<=i*timewindow);
    mod_gcamp(i,1) = mean(gcamp(tempind2,1));
    mod_rcamp(i,1) = mean(rcamp(tempind2,1));
end