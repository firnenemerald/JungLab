function result=normhmap(hmap01,arena)

difff=arena(1,:)-arena(4,:);
allowarea=[arena(1,:)+difff;arena(2,:)+difff;arena(3,:)-difff;arena(4,:)-difff];

gcenter = [mean(arena(:,1)),mean(arena(:,2))];

arenasize = sqrt((arena(1,1)-arena(2,1))^2 + (arena(1,2)-arena(2,2))^2);

x1 = (arena(1,1)+arena(4,1)) /2;
y1 = (arena(1,2)+arena(4,2)) /2;
x2 = (arena(2,1)+arena(3,1)) /2;
y2 = (arena(2,2)+arena(3,2)) /2;

gnormhmap = cell(900,900);
rnormhmap = cell(900,900);

gphm=hmap01.pheatmap_gcamp;
rphm=hmap01.pheatmap_rcamp;

sizeratio = 700/arenasize;

for i = 1 : size(gphm,1)
    for j = 1 : size(gphm,2)
        if ~isempty(gphm{i,j}) 
            x0 = i; y0 = j;
            numerator = (y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1;
            denominator = sqrt((y2 - y1)^2 + (x2 - x1)^2);
            distance = numerator / denominator;
            gdist = sqrt((x0-gcenter(1,1))^2 + (y0-gcenter(1,2))^2);
            dist1 = sqrt((x1-x0)^2 + (y1-y0)^2);
            dist2 = sqrt((x2-x0)^2 + (y2-y0)^2);
            distance2=sqrt(gdist^2 - distance^2);
            if dist1 <= dist2
                distance2 = distance2 *(-1);
            end
            cdist1 = round(distance * sizeratio);
            cdist2 = round(distance2* sizeratio);

            try
            gnormhmap{400+cdist2,400+cdist1} = gphm{i,j};
            catch
            end
        end
    end
end

for i = 1 : size(rphm,1)
    for j = 1 : size(rphm,2)
        if ~isempty(rphm{i,j}) 
            x0 = i; y0 = j;
            numerator = (y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1;
            denominator = sqrt((y2 - y1)^2 + (x2 - x1)^2);
            distance = numerator / denominator;
            gdist = sqrt((x0-gcenter(1,1))^2 + (y0-gcenter(1,2))^2);
            dist1 = sqrt((x1-x0)^2 + (y1-y0)^2);
            dist2 = sqrt((x2-x0)^2 + (y2-y0)^2);
            distance2=sqrt(gdist^2 - distance^2);
            if dist1 <= dist2
                distance2 = distance2 *(-1);
            end
            cdist1 = round(distance * sizeratio);
            cdist2 = round(distance2* sizeratio);

            try
            rnormhmap{400+cdist2,400+cdist1} = rphm{i,j};
            catch
            end
        end
    end
end

result.norm_ghmap = gnormhmap;
result.norm_rhmap = rnormhmap;

%{
fgnormhmap = nan(800,800);
for i = 1 : size(gnormhmap,1)
    for j = 1 : size(gnormhmap,2)
        if ~isempty(gnormhmap{i,j})
            fgnormhmap(i,j) = mean(gnormhmap{i,j});
        end
    end
end

imagesc(fgnormhmap)
%}
