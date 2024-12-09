function preonsetzscore(RMOt)
temppreonset=RMOt(:,1:60);
RMOt = (RMOt - mean(temppreonset(:)))/std(temppreonset(:));

figure;
x= -1 : 1/60 : 1 ;
imagesc(x, 1:size(RMOt, 1), RMOt); 
colormap('jet'); 
colorbar;

hold on;
plot([0 0], ylim, 'k--', 'LineWidth', 1.5);

xlabel('Time (s)');
ylabel('behavior NO.');
title('RCaMP: mobile onset');
grid on;
hold off;