clear all;
load('hmapmidsave.mat')

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
         aallg01(x,y) = nanmean(allg01{x,y});
         aallr01(x,y) = nanmean(allr01{x,y});
     end
end


minVal = min([aallg01(:); aallr01(:)], [], 'omitnan');
maxVal = max([aallg01(:); aallr01(:)], [], 'omitnan');

aallg01_nan_replaced = aallg01;
aallg01_nan_replaced(isnan(aallg01_nan_replaced)) = minVal;
aallr01_nan_replaced = aallr01;
aallr01_nan_replaced(isnan(aallr01_nan_replaced)) = minVal;

sigma = 1; 
kernelSize = 9; 
gaussianKernel = fspecial('gaussian', kernelSize, sigma);

nanReplacementValue = minVal - 1; 
aallg01_nan_replaced(isnan(aallg01)) = nanReplacementValue;
aallr01_nan_replaced(isnan(aallr01)) = nanReplacementValue;

smoothed_gcamp = imfilter(aallg01_nan_replaced, gaussianKernel, 'same', 'replicate');
smoothed_rcamp = imfilter(aallr01_nan_replaced, gaussianKernel, 'same', 'replicate');

figure('units', 'normalized', 'outerposition', [0 0 1 1]);

customColormap = colormap(jet);
customColormap(1, :) = [0 0 0.3];

% GCaMP
subplot(1, 2, 1);
imagesc(smoothed_gcamp);
colormap(customColormap);
caxis([nanReplacementValue, maxVal - 0.5]); 
set(gca, 'Color', [1 1 1]);
title('non-PV');

% RCaMP
subplot(1, 2, 2);
imagesc(smoothed_rcamp);
colormap(customColormap); 
caxis([nanReplacementValue, maxVal - 0.5]);
set(gca, 'Color', [1 1 1]);
title('PV ');
colorbar;