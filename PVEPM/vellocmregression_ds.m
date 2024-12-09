function result=vellocmregression_ds(roa_m,ovel_m,wos)

for i = 1 : size(roa_m,1)
csig=roa_m(i,:);
cvel = ovel_m(i,:)';
for j = 1 : 15
    sig1(1,j) = mean(csig(2*(j-1)+1:2*j));
end
for j =1:30
    sig2(1,j) = mean(csig(2*(j-1)+32:2*j+31));
end
ds_sig = [sig1,csig(31),sig2];
if strcmp(wos,'ca')
    loc = [ones([1,16]),zeros([1,30])]';
elseif strcmp(wos,'oa')
    loc = [zeros([1,16]),ones([1,30])]';
end
X = [ones(size(cvel)) cvel loc cvel.*loc];
y = ds_sig';

[b, bint, r, rint, stats] = regress(y, X);

locval(i,1) = b(2);
velval(i,1) = b(1);
clearvars -except i wos locval velval data result roa_m ovel_m
end

result.locval = locval;
result.velval = velval;