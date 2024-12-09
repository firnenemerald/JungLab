clear all
load("onsetresults.mat");

data = struct2cell(results);

goa_e = [];
roa_e = [];
gca_e = [];
rca_e = [];
for i = 1 : size(data,1)
    for j = 1 : size(data{i}.GCaMP_CAonsetsig,2)
        gca_m(i,j) = nanmean(data{i}.GCaMP_CAonsetsig(:,j));
    end
    gca_e = [gca_e;data{i}.GCaMP_CAonsetsig];

    for j = 1 : size(data{i}.GCaMP_OAonsetsig,2)
        goa_m(i,j) = nanmean(data{i}.GCaMP_OAonsetsig(:,j));
    end
    goa_e = [goa_e;data{i}.GCaMP_OAonsetsig];

    for j = 1 : size(data{i}.RCaMP_OAonsetsig,2)
        
        roa_m(i,j) = nanmean(data{i}.RCaMP_OAonsetsig(:,j));
    end
    roa_e = [roa_e;data{i}.RCaMP_OAonsetsig];

    for j = 1 : size(data{i}.RCaMP_CAonsetsig,2)
        rca_m(i,j) = nanmean(data{i}.RCaMP_CAonsetsig(:,j));
    end
    rca_e = [rca_e;data{i}.RCaMP_CAonsetsig];
end

ovel_e = [];
cvel_e = [];
for i = 1 : size(data,1)
    for j = 1 : size(data{i}.OAonsetvel,2)
        ovel_m(i,j) = nanmean(data{i}.OAonsetvel(:,j));
    end
    ovel_e = [ovel_e;data{i}.OAonsetvel];

    for j = 1 : size(data{i}.CAonsetvel,2)
        cvel_m(i,j) = nanmean(data{i}.CAonsetvel(:,j));
    end
    cvel_e = [cvel_e;data{i}.CAonsetvel];
end

gca_m = gca_m(:,31:end);
rca_m = rca_m(:,31:end);
gca_e = gca_e(:,31:end);
rca_e = rca_e(:,31:end);
goa_m = goa_m(:,31:end);
roa_m = roa_m(:,31:end);
goa_e = goa_e(:,31:end);
roa_e = roa_e(:,31:end);



onsetsigvelplot(gca_m,rca_m,cvel_m,'mouse:closed arm');
onsetsigvelplot(gca_e,rca_e,cvel_e,'event:closed arm');

onsetsigvelplot(goa_m,roa_m,ovel_m,'mouse:open arm');
onsetsigvelplot(goa_e,roa_e,ovel_e,'event:open arm');

roa_mr=vellocmregression(roa_m,ovel_m,'oa');
goa_mr=vellocmregression(goa_m,ovel_m,'oa');
rca_mr=vellocmregression(rca_m,cvel_m,'ca');
gca_mr=vellocmregression(gca_m,cvel_m,'ca');

roa_mr=vellocmregression_ds(roa_m,ovel_m,'oa');
goa_mr=vellocmregression_ds(goa_m,ovel_m,'oa');
rca_mr=vellocmregression_ds(rca_m,cvel_m,'ca');
gca_mr=vellocmregression_ds(gca_m,cvel_m,'ca');


b=bar([mean(goa_mr.locval),mean(goa_mr.velval)]);
b.FaceColor = 'flat';  
b.CData(1,:) = [1 1 0]; 
b.CData(2,:) = [0 0 1]; 
set(gca, 'xticklabel', {'Location', 'Velocity'});
hold on;
scatter(repmat(1, size(goa_mr.locval)), goa_mr.locval, 'r', 'filled');
scatter(repmat(2, size(goa_mr.velval)), goa_mr.velval, 'g', 'filled');
for i = 1:length(goa_mr.locval)
    plot([1, 2], [goa_mr.locval(i), goa_mr.velval(i)], 'k-');
end
[~, p] = ttest(goa_mr.locval, goa_mr.velval);
if p < 0.001
    significance = '***';
elseif p < 0.01
    significance = '**';
elseif p < 0.05
    significance = '*';
else
    significance = 'n.s.'; 
end
y = max([mean(goa_mr.locval),mean(goa_mr.velval)]) + 0.1 * range([mean(goa_mr.locval),mean(goa_mr.velval)]); 
plot([1, 2], [y, y], 'k-', 'LineWidth', 1.5); 
text(1.5, y + 0.05, significance, 'HorizontalAlignment', 'center', 'FontSize', 12);

text(2.2, y + 0.1, sprintf('p = %.3f', p), 'FontSize', 10, 'HorizontalAlignment', 'center');
title('non-PV:open arm onset');
ylabel(['regression coefficient'])
hold off;

b=bar([mean(roa_mr.locval),mean(roa_mr.velval)]);
b.FaceColor = 'flat';  
b.CData(1,:) = [1 1 0]; 
b.CData(2,:) = [0 0 1]; 
set(gca, 'xticklabel', {'Location', 'Velocity'});
hold on;
scatter(repmat(1, size(roa_mr.locval)), roa_mr.locval, 'r', 'filled');
scatter(repmat(2, size(roa_mr.velval)), roa_mr.velval, 'g', 'filled');
for i = 1:length(roa_mr.locval)
    plot([1, 2], [roa_mr.locval(i), roa_mr.velval(i)], 'k-');
end
[~, p] = ttest(roa_mr.locval, roa_mr.velval);
if p < 0.001
    significance = '***';
elseif p < 0.01
    significance = '**';
elseif p < 0.05
    significance = '*';
else
    significance = 'n.s.'; 
end
y = max([mean(roa_mr.locval),mean(roa_mr.velval)]) + 0.1 * range([mean(roa_mr.locval),mean(roa_mr.velval)]); 
plot([1, 2], [y, y], 'k-', 'LineWidth', 1.5); 
text(1.5, y + 0.05, significance, 'HorizontalAlignment', 'center', 'FontSize', 12);

text(2.2, y + 0.1, sprintf('p = %.3f', p), 'FontSize', 10, 'HorizontalAlignment', 'center');
title('PV:open arm onset');
ylabel(['regression coefficient'])
hold off;


b=bar([mean(gca_mr.locval),mean(gca_mr.velval)]);
b.FaceColor = 'flat';  
b.CData(1,:) = [1 1 0]; 
b.CData(2,:) = [0 0 1]; 
set(gca, 'xticklabel', {'Location', 'Velocity'});
hold on;
scatter(repmat(1, size(gca_mr.locval)), gca_mr.locval, 'r', 'filled');
scatter(repmat(2, size(gca_mr.velval)), gca_mr.velval, 'g', 'filled');
for i = 1:length(gca_mr.locval)
    plot([1, 2], [gca_mr.locval(i), gca_mr.velval(i)], 'k-');
end
[~, p] = ttest(gca_mr.locval, gca_mr.velval);
if p < 0.001
    significance = '***';
elseif p < 0.01
    significance = '**';
elseif p < 0.05
    significance = '*';
else
    significance = 'n.s.'; 
end
y = max([mean(gca_mr.locval),mean(gca_mr.velval)]) + 0.1 * range([mean(gca_mr.locval),mean(gca_mr.velval)]); 
plot([1, 2], [y, y], 'k-', 'LineWidth', 1.5); 
text(1.5, y + 0.05, significance, 'HorizontalAlignment', 'center', 'FontSize', 12);

text(2.2, y + 0.1, sprintf('p = %.3f', p), 'FontSize', 10, 'HorizontalAlignment', 'center');
title('non-PV:closed arm onset');
ylabel(['regression coefficient'])
hold off;


b=bar([mean(rca_mr.locval),mean(rca_mr.velval)]);
b.FaceColor = 'flat';  
b.CData(1,:) = [1 1 0]; 
b.CData(2,:) = [0 0 1]; 
set(gca, 'xticklabel', {'Location', 'Velocity'});
hold on;
scatter(repmat(1, size(rca_mr.locval)), rca_mr.locval, 'r', 'filled');
scatter(repmat(2, size(rca_mr.velval)), rca_mr.velval, 'g', 'filled');
for i = 1:length(rca_mr.locval)
    plot([1, 2], [rca_mr.locval(i), rca_mr.velval(i)], 'k-');
end
[~, p] = ttest(rca_mr.locval, rca_mr.velval);
if p < 0.001
    significance = '***';
elseif p < 0.01
    significance = '**';
elseif p < 0.05
    significance = '*';
else
    significance = 'n.s.'; 
end
y = max([mean(rca_mr.locval),mean(rca_mr.velval)]) + 0.1 * range([mean(rca_mr.locval),mean(rca_mr.velval)]); 
plot([1, 2], [y, y], 'k-', 'LineWidth', 1.5); 
text(1.5, y + 0.05, significance, 'HorizontalAlignment', 'center', 'FontSize', 12);

text(2.2, y + 0.1, sprintf('p = %.3f', p), 'FontSize', 10, 'HorizontalAlignment', 'center');
title('PV:closed arm onset');
ylabel(['regression coefficient'])
hold off;

