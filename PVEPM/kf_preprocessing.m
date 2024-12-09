function result = kf_preprocessing(inputdata)


try
xydat=inputdata(:,1:2);
diffxy=diff(xydat);

for i = 1: size(diffxy,1)
    velocity(i,1) = sqrt(diffxy(i,1)^2 + diffxy(i,2)^2);
end

zvel=zscore(velocity);
[zveldat,zvelind]=sort(zvel,'descend');

fixind=zvelind(find(zveldat>7));

velocity2 = velocity;

velocity2(fixind,1) = nan;

zvel2=(velocity2-nanmean(velocity2))/nanstd(velocity2);

[zveldat2,zvelind2]=sort(zvel2,'descend');

iind = find(~isnan(zveldat2)==1);

zveldat2 = zveldat2(iind,1);
zvelind2 = zvelind2(iind,1);

fixind2=zvelind2(find(zveldat2>7));

ffixind = [fixind;fixind2];

fffixind=[];
for i = 1 : size(ffixind,1)
    fffixind = [fffixind;ffixind(i,1);ffixind(i,1)+1];
end

fffixind = unique(fffixind);

fffixind=sort(fffixind,'ascend');

dfi=diff(fffixind);
fixind3 = fffixind;

eind=fffixind(find(dfi>20));
sind=fffixind(find(dfi>20)+1);

sind2 = [fffixind(1,1);sind(1:end-1,1)];

range = [sind2-1,eind+1];


for i = 1 :size(range,1)
    fixind3 = [fixind3;[[range(i,1):range(i,2)]']];
end

fixind3 = unique(fixind3);

result = inputdata;

result(fixind3,3) = 1e-6;
catch
    inputdata(:,3)=repmat(1,size(inputdata,1),1);
    result = inputdata;
end