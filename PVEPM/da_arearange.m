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
dlc = cD.DLC(1:end,:);
difff=OAarea(1,:)-OAarea(4,:);
allowarea=[OAarea(1,:)+difff;OAarea(2,:)+difff;OAarea(3,:)-difff;OAarea(4,:)-difff];
head = dlc(:,2:3);

oarange=startend(find(inpolygon(head(:,1),head(:,2),OAarea(:,1),OAarea(:,2))));
aarange=startend(find(inpolygon(head(:,1),head(:,2),allowarea(:,1),allowarea(:,2))));
k = 1;
while true
    try
        if aarange(k+1,1)-aarange(k,2) < 10
            aarange(k,:) = [aarange(k,1),aarange(k+1,2)];
            aarange(k+1,:) = [];
        else
            k = k+1;
        end
    catch
        break;
    end
end

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

for i = 1 : size(foarange,1)
    clear temp
    temp = [dlc(foarange(i,1),1),dlc(foarange(i,2),1)];
    oarange1(i,:) = temp;
end

for i = 1 : size(carange,1)
    clear temp
    temp = [dlc(carange(i,1),1),dlc(carange(i,2),1)];
    carange1(i,:) = temp;
end

result.OArange = oarange1;
result.CArange = carange1;

end


