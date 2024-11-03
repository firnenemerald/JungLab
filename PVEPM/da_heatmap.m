function result=da_heatmap(head01,gcamp01,rcamp01)

ghmap=NaN(ceil(max(head01(:,1))),ceil(max(head01(:,2))));
rhmap=NaN(ceil(max(head01(:,1))),ceil(max(head01(:,2))));

zgcamp01 = (gcamp01 - nanmean(gcamp01))/nanstd(gcamp01);
zrcamp01 = (rcamp01 - nanmean(rcamp01))/nanstd(rcamp01);

for i = 1 : size(ghmap,1)
    for j = 1 : size(ghmap,2)
        prehmap{i,j}=find(head01(:,1)>=i & head01(:,1)<i+1 & head01(:,2) >=j & head01(:,2) < j+1);
    end
end

for i = 1 : size(prehmap,1)
    for j = 1 : size(prehmap,2)
        if ~isempty(prehmap{i,j})
            gprehmap2{i,j}= zgcamp01(prehmap{i,j},1);
            rprehmap2{i,j}= zrcamp01(prehmap{i,j},1);
        else
            gprehmap2{i,j}= [];
            rprehmap2{i,j}= [];
        end
    end
end
 
result.pheatmap_gcamp = gprehmap2;
result.pheatmap_rcamp = rprehmap2;

%{
ghmap =ghmap';
rhmap = rhmap';


minVal = min([ghmap(:); rhmap(:)], [], 'omitnan');
maxVal = max([ghmap(:); rhmap(:)], [], 'omitnan');

subplot(1, 2, 1);
imagesc(ghmap); 
colormap(jet);
caxis([minVal, maxVal]); 
set(gca, 'Color', [1 1 1]); 
ghmap_alpha = ~isnan(ghmap); 
set(gca().Children, 'AlphaData', ghmap_alpha); 
hold on;
drawpolygon('Position', cD.Arena, 'FaceAlpha', 0);
hold off;

subplot(1, 2, 2);
imagesc(rhmap); 
colormap(jet);
caxis([minVal, maxVal]); 
set(gca, 'Color', [1 1 1]); 
rhmap_alpha = ~isnan(rhmap); 
set(gca().Children, 'AlphaData', rhmap_alpha); 
hold on;
drawpolygon('Position', cD.Arena, 'FaceAlpha', 0);
hold off;

colorbar('Position', [0.92, 0.11, 0.02, 0.815]); 
%}