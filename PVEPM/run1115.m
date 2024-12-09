clear all
load("onsetresults.mat");

data = struct2cell(results);

%imagesc(data{1}.GCaMP_CAonsetsig2)
%imagesc(tgca)
%imagesc(temp)
%imagesc(goa{1,1})
troa = [];
tgoa = [];
trca = [];
tgca = [];
for i = 1 : size(data,1)
    temp=data{i}.RCaMP_OAonsetsig2;
    temp = temp(~any(isnan(temp), 2), :);
    roa{i,1} = temp;
    troa = [troa;temp];
    clear temp

    temp=data{i}.GCaMP_OAonsetsig2;
    temp = temp(~any(isnan(temp), 2), :);
    goa{i,1} = temp;
    tgoa = [tgoa;temp];
    clear temp

    temp=data{i}.RCaMP_CAonsetsig2;
    temp = temp(~any(isnan(temp), 2), :);
    rca{i,1} = temp;
    trca = [trca;temp];
    clear temp

    temp=data{i}.GCaMP_CAonsetsig2;
    temp = temp(~any(isnan(temp), 2), :);
    gca{i,1} = temp;
    tgca = [tgca;temp];
    clear temp
end

% imagesc(tgca); imagesc(tgoa); imagesc(trca) ; imagesc(troa)
%%
OAonsetvel = [];
CAonsetvel = [];
for i = 1 : size(data,1)
    OAonsetvel =[OAonsetvel;data{i}.OAonsetvel];
    CAonsetvel = [CAonsetvel;data{i}.CAonsetvel];
end
%%
prepreonsetmean =[];
for i = 1 : size(tgca,1)
    prepreonsetmean = [prepreonsetmean,tgca(i,1:30)];
end
tgca2 = (tgca - mean(prepreonsetmean))/std(prepreonsetmean);

prepreonsetmean =[];
for i = 1 : size(trca,1)
    prepreonsetmean = [prepreonsetmean,trca(i,1:30)];
end
trca2 = (trca - mean(prepreonsetmean))/std(prepreonsetmean);

prepreonsetmean =[];
for i = 1 : size(tgoa,1)
    prepreonsetmean = [prepreonsetmean,tgoa(i,1:30)];
end
tgoa2 = (tgoa - mean(prepreonsetmean))/std(prepreonsetmean);

prepreonsetmean =[];
for i = 1 : size(troa,1)
    prepreonsetmean = [prepreonsetmean,troa(i,1:30)];
end
troa2 = (troa - mean(prepreonsetmean))/std(prepreonsetmean);

%%
onsetsigvelplot(tgca2,trca2,CAonsetvel,'closed arm onset');
onsetsigvelplot(tgoa2,troa2,OAonsetvel,'open arm onset');
%%

trca_z = [];
tgca_z = [];
troa_z = [];
tgoa_z = [];
for i = 1 : size(data,1)
    temp=data{i}.RCaMP_CAonsetsig;
    temp = temp(~any(isnan(temp), 2), :);
    trca_z = [trca_z;temp];
    clear temp

    temp=data{i}.GCaMP_CAonsetsig;
    temp = temp(~any(isnan(temp), 2), :);
    tgca_z = [tgca_z;temp];
    clear temp

    temp=data{i}.GCaMP_OAonsetsig;
    temp = temp(~any(isnan(temp), 2), :);
    tgoa_z = [tgoa_z;temp];
    clear temp

    temp=data{i}.RCaMP_OAonsetsig;
    temp = temp(~any(isnan(temp), 2), :);
    troa_z = [troa_z;temp];
    clear temp
end


x = -0.5:1/60:1 ;
%%
for i = 1 : size(tgoa_z,1)
    tgoamean(i,1) = mean(tgoa_z(i,61:120));
end

[~,sortind] = sort(tgoamean,'descend');

tgoa_z2 = tgoa_z(sortind,:);

tgoa_z3 = tgoa_z2(:,31:121);

figure;
imagesc(x, 1:size(tgoa_z3,1), tgoa_z3);
colorbar; 

xlabel('Time (s)');
ylabel('event no.');

hold on;
plot([0, 0], ylim, 'k--', 'LineWidth', 1.5);
hold off;

title('open arm onset:non-PV')
%%
for i = 1 : size(troa_z,1)
    troamean(i,1) = mean(troa_z(i,61:120));
end

[~,sortind] = sort(troamean,'descend');

troa_z2 = troa_z(sortind,:);

troa_z3 = troa_z2(:,31:121);

figure;
imagesc(x, 1:size(troa_z3,1), troa_z3);
colorbar; 

xlabel('Time (s)');
ylabel('event no.');

hold on;
plot([0, 0], ylim, 'k--', 'LineWidth', 1.5);
hold off;
title('open arm onset:PV')

%%
for i = 1 : size(tgca_z,1)
    tgcamean(i,1) = mean(tgca_z(i,61:120));
end

[~,sortind] = sort(tgcamean,'descend');

tgca_z2 = tgca_z(sortind,:);

tgca_z3 = tgca_z2(:,31:121);

figure;
imagesc(x, 1:size(tgca_z3,1), tgca_z3);
colorbar; 

xlabel('Time (s)');
ylabel('event no.');

hold on;
plot([0, 0], ylim, 'k--', 'LineWidth', 1.5);
hold off;
title('closed arm onset:non-PV')
%%
for i = 1 : size(trca_z,1)
    trcamean(i,1) = mean(trca_z(i,61:120));
end

[~,sortind] = sort(trcamean,'descend');

trca_z2 = trca_z(sortind,:);

trca_z3 = trca_z2(:,31:121);

figure;
imagesc(x, 1:size(trca_z3,1), trca_z3);
colorbar; 

xlabel('Time (s)');
ylabel('event no.');

hold on;
plot([0, 0], ylim, 'k--', 'LineWidth', 1.5);
hold off;
title('closed arm onset:PV')

%%
