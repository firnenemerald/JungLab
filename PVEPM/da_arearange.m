clear all
load('dlcsmooth.mat');
load('errorfixed.mat');
mergeall;

data = struct2cell(combined);
dataname = fieldnames(combined);

for i = 1 : size(data,1)
    cD = data{i};
    dname = dataname{i};
    Arearange.(dname) = asdf(cD);
end

save('Arearange.mat','Arearange');


function result = asdf(cD)

OAarea=cD.Arena;
dlc = cD.DLC(2:end,:);
difff=OAarea(1,:)-OAarea(4,:);
allowarea=[OAarea(1,:)+difff;OAarea(2,:)+difff;OAarea(3,:)-difff;OAarea(4,:)-difff];
head = dlc(:,2:3);

oarange=startend(find(inpolygon(head(:,1),head(:,2),OAarea(:,1),OAarea(:,2))));
aarange=startend(find(inpolygon(head(:,1),head(:,2),allowarea(:,1),allowarea(:,2))));

foarange = [];
for i = 1 : size(aarange,1)
    correspondingind = find(oarange(:,1)>= aarange(i,1) & oarange(:,2)<=aarange(i,2));
    foarange=[foarange;min(oarange(correspondingind,1)),max(oarange(correspondingind,2))];
    clear correspondingind
end

tfoarange = [];
for i = 1 : size(foarange,1)
    tfoarange = [tfoarange;[foarange(i,1):foarange(i,2)]'];
end

carange=startend(setdiff([1:size(dlc,1)]',tfoarange));

result.OArange = oarange;
result.CArange = carange;

end


