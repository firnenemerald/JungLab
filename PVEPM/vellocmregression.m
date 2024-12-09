function result=vellocmregression(roa_m,ovel_m,wos)

for i = 1 : size(roa_m,1)
csig=roa_m(i,:);
cvel = ovel_m(i,:);
time1 = (1:30)/30;
time2 =(1:60)/60;
time3 = (1:15)/30;
time4 =(1:30)/60;
us_vel1=interp1(time3, cvel(1:15), time4, 'linear');
us_vel2=interp1(time1, cvel(17:46), time2, 'linear');
cvel_us = [us_vel1,cvel(16),us_vel2]';
if strcmp(wos,'ca')
    loc = [ones([1,31]),zeros([1,60])]';
elseif strcmp(wos,'oa')
    loc = [zeros([1,31]),ones([1,60])]';
end
X = [ones(size(cvel_us)) cvel_us loc cvel_us.*loc];
y = csig';

[b, bint, r, rint, stats] = regress(y, X);

locval(i,1) = b(2);
velval(i,1) = b(1);
clearvars -except i wos locval velval data result roa_m ovel_m
end

result.locval = locval;
result.velval = velval;