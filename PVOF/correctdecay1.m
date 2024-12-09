clear all
load("errorfixed.mat");
data = struct2cell(errorfixed_doric);
dataname = fieldnames(errorfixed_doric);

for i = 1 : size(data,1)
    %%
    cD = data{i};
    dname = dataname{i};
    decaycorrected.(dname) = asdf(cD);
    %%
end

save('decaycorrected.mat','decaycorrected');

function result = asdf(cD)

gcamp = cD.GCaMP;
rcamp = cD.RCaMP;
time = [0:1/60.241:(1/60.241)*(size(rcamp,1)-1)]';

fixed_gcamp = PV_MsacSignal(time, gcamp, 200, 0.001);
fixed_rcamp = PV_MsacSignal(time, rcamp, 200, 0.001);

figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);
subplot(2,1,1);
plot(gcamp,'g');
title('non-fixed');

subplot(2,1,2);
plot(fixed_gcamp,'g');
title('fixed');

qans1 = questdlg('choose','choose','non-fixed','fixed','non-fixed');

switch qans1
    case 'non-fixed'
        result.GCaMP = gcamp;
    case 'fixed'
        result.GCaMP = fixed_gcamp;
end
close all

figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);
subplot(2,1,1);
plot(rcamp,'r');
title('non-fixed');

subplot(2,1,2);
plot(fixed_rcamp,'r');
title('fixed');

qans2 = questdlg('choose','choose','non-fixed','fixed','non-fixed');

switch qans2
    case 'non-fixed'
        result.RCaMP = rcamp;
    case 'fixed'
        result.RCaMP = fixed_rcamp;
end

close all
end