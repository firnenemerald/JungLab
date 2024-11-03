clear all
load('norm_hmap.mat');

%%

data = struct2cell(Heatmap);
dataname = fieldnames(Heatmap);

path = uigetdir;
path1 = fullfile(path,'normhmap');
mkdir(path1);

for i = 1 : size(data,1)
    cD = data{i};
    dname = dataname{i};
    path2 = fullfile(path1,dname);
    mkdir(path2);
    g01 = cD.normhmap01.norm_ghmap;
    r01 = cD.normhmap01.norm_rhmap; 
    g05 = cD.normhmap05.norm_ghmap;
    r05 =cD.normhmap05.norm_rhmap;
    g1 = cD.normhmap1.norm_ghmap;      
    r1 = cD.normhmap1.norm_rhmap;  
    result01{i,1} = asdf(g01,r01);
    sgtitle ([strrep(dname,'_','-'),':0.1 second'])
    fileName = fullfile(path2,'hmap_01.png');
    saveas(gcf, fileName);
    close all
    result05{i,1} = asdf(g05,r05);
    sgtitle ([strrep(dname,'_','-'),':0.5 second'])
    fileName = fullfile(path2,'hmap_05.png');
    saveas(gcf, fileName);
    close all
    result1{i,1} = asdf(g1,r1);
    sgtitle ([strrep(dname,'_','-'),':1second'])
    fileName = fullfile(path2,'hmap_1.png');
    saveas(gcf, fileName);
    close all
end

%%
fdsa(result01)
sgtitle (['total:0.1second'])
fileName = fullfile(path1,'hmap_01.png');
saveas(gcf, fileName);
close all

fdsa(result05)
sgtitle (['total:0.5second'])
fileName = fullfile(path1,'hmap_05.png');
saveas(gcf, fileName);
close all

fdsa(result1)
sgtitle (['total:1second'])
fileName = fullfile(path1,'hmap_1.png');
saveas(gcf, fileName);
close all


function fdsa(result01)
allg01 = cell(900,900);
allr01 = cell(900,900);
for i = 1 : size(result01,1)
    for x = 1 : size(allr01,1)
        for y = 1 : size(allr01,2)
            allg01{x,y} = [allg01{x,y};result01{i,1}.gcamp{x,y}];
            allr01{x,y} = [allr01{x,y};result01{i,1}.rcamp{x,y}];
        end
    end
end

for x = 1 : size(allr01,1)
     for y = 1 : size(allr01,2)
         aallg01(x,y) = mean(allg01{x,y});
         aallr01(x,y) = mean(allr01{x,y});
     end
end

minVal = min([aallg01(:); aallr01(:)], [], 'omitnan');
maxVal = max([aallg01(:); aallr01(:)], [], 'omitnan');

figure('units', 'normalized', 'outerposition', [0 0 1 1]);
subplot(1, 2, 1);
imagesc(aallg01);
colormap(jet);
caxis([minVal, maxVal]);
set(gca, 'Color', [1 1 1]);
ghmap_alpha = ~isnan(aallg01);
set(gca().Children, 'AlphaData', ghmap_alpha);
title('GCaMP')

subplot(1, 2, 2);
imagesc(aallr01);
colormap(jet);
caxis([minVal, maxVal]);
set(gca, 'Color', [1 1 1]);
rhmap_alpha = ~isnan(aallr01);
set(gca().Children, 'AlphaData', rhmap_alpha);
title('RCaMP')

colorbar('Position', [0.92, 0.11, 0.02, 0.815]);
end


function result=asdf(g01,r01)
 g01_1 = cell(900,900);
    r01_1 = cell(900,900);
    for x = 1 : size(g01,1)
        for y = 1 : size(g01,2)
            if ~isempty(g01{x,y})
                try
                g01_1{x,y} = [g01_1{x,y}; g01{x,y}];
                catch
                end
                try
                g01_1{x-1,y} = [g01_1{x-1,y}; g01{x,y}];
                catch
                end
                try
                g01_1{x+1,y} = [g01_1{x+1,y}; g01{x,y}];
                catch
                end
                try
                g01_1{x,y-1} = [g01_1{x,y-1}; g01{x,y}];
                catch
                end
                try
                g01_1{x,y+1} = [g01_1{x,y+1}; g01{x,y}];
                catch
                end
                try
                r01_1{x,y} = [r01_1{x,y}; r01{x,y}];
                catch
                end
                try
                r01_1{x-1,y} = [r01_1{x-1,y}; r01{x,y}];
                catch
                end
                try
                r01_1{x+1,y} = [r01_1{x+1,y}; r01{x,y}];
                
                catch
                end
                try
                r01_1{x,y-1} = [r01_1{x,y-1}; r01{x,y}];
                catch
                end
                try
                r01_1{x,y+1} = [r01_1{x,y+1}; r01{x,y}];
                catch
                end
            end
        end
    end

    for x = 1 : size(g01,1)
        for y = 1 : size(g01,2)
            ag01(x,y)= mean(g01_1{x,y});
            ar01(x,y)= mean(r01_1{x,y});
        end
    end
    minVal = min([ag01(:); ar01(:)], [], 'omitnan');
    maxVal = max([ag01(:); ar01(:)], [], 'omitnan');

    figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    subplot(1, 2, 1);
    imagesc(ag01);
    colormap(jet);
    caxis([minVal, maxVal]);
    set(gca, 'Color', [1 1 1]);
    ghmap_alpha = ~isnan(ag01);
    set(gca().Children, 'AlphaData', ghmap_alpha);
    title('GCaMP')

    subplot(1, 2, 2);
    imagesc(ar01);
    colormap(jet);
    caxis([minVal, maxVal]);
    set(gca, 'Color', [1 1 1]);
    rhmap_alpha = ~isnan(ar01);
    set(gca().Children, 'AlphaData', rhmap_alpha);
    title('RCaMP')

    colorbar('Position', [0.92, 0.11, 0.02, 0.815]);
    result.gcamp = g01_1;
    result.rcamp = r01_1;
end