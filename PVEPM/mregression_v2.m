clear all
load("onsetresults.mat");

data = struct2cell(results);

%% signal nan 처리
troa = [];
tgoa = [];
trca = [];
tgca = [];
for i = 1 : size(data,1)
    temp=data{i}.RCaMP_OAonsetsig(:,31:121);
    temp = temp(~any(isnan(temp), 2), :);
    roa{i,1} = temp;
    troa = [troa;temp];
    clear temp

    temp=data{i}.GCaMP_OAonsetsig(:,31:121);
    temp = temp(~any(isnan(temp), 2), :);
    goa{i,1} = temp;
    tgoa = [tgoa;temp];
    clear temp

    temp=data{i}.RCaMP_CAonsetsig(:,31:121);
    temp = temp(~any(isnan(temp), 2), :);
    rca{i,1} = temp;
    trca = [trca;temp];
    clear temp

    temp=data{i}.GCaMP_CAonsetsig(:,31:121);
    temp = temp(~any(isnan(temp), 2), :);
    gca{i,1} = temp;
    tgca = [tgca;temp];
    clear temp
end

%% mouse별로 평균
for i = 1 : size(gca,1)
    for j = 1 : size(gca{i},2)
        temp(1,j) = mean(gca{i}(:,j));
    end
    gca_mean(i,:) = temp;
    clear temp
end

for i = 1 : size(goa,1)
    for j = 1 : size(goa{i},2)
        temp(1,j) = mean(goa{i}(:,j));
    end
    goa_mean(i,:) = temp;
    clear temp
end

for i = 1 : size(rca,1)
    for j = 1 : size(rca{i},2)
        temp(1,j) = mean(rca{i}(:,j));
    end
    rca_mean(i,:) = temp;
    clear temp
end

for i = 1 : size(roa,1)
    for j = 1 : size(roa{i},2)
        temp(1,j) = mean(roa{i}(:,j));
    end
    roa_mean(i,:) = temp;
    clear temp
end

%% 속도 처리
toavel = [];
tcavel = [];
for i = 1 : size(data,1)
    temp=data{i}.OAonsetvel;
    temp = temp(~any(isnan(temp), 2), :);
    oavel{i,1} = temp;
    toavel = [toavel;temp];
    clear temp

    temp=data{i}.CAonsetvel;
    temp = temp(~any(isnan(temp), 2), :);
    cavel{i,1} = temp;
    tcavel = [tcavel;temp];
    clear temp
end

for i = 1 : size(oavel,1)
    for j = 1 : size(oavel{i},2)
        temp(1,j) = mean(oavel{i}(:,j));
    end
    oavel_mean(i,:) = temp;
    clear temp
end

for i = 1 : size(cavel,1)
    for j = 1 : size(cavel{i},2)
        temp(1,j) = mean(cavel{i}(:,j));
    end
    cavel_mean(i,:) = temp;
    clear temp
end

%% velocity upsampling
t1_60hz =linspace(0, 1, 60);
t1_30hz =linspace(0, 1, 30);
t05_60hz =linspace(0, 0.5, 30);
t05_30hz =linspace(0, 0.5, 15);

for i = 1 : size(oavel_mean)
    temp1 = interp1(t05_30hz,oavel_mean(i,1:15),t05_60hz,'linear');
    temp2 = interp1(t1_30hz,oavel_mean(i,17:46),t1_60hz,'linear');
    temp3 = [temp1,oavel_mean(i,16),temp2];
    oavel_us(i,:) = temp3;
    clear temp1 temp2 temp3
end

for i = 1 : size(cavel_mean)
    temp1 = interp1(t05_30hz,cavel_mean(i,1:15),t05_60hz,'linear');
    temp2 = interp1(t1_30hz,cavel_mean(i,17:46),t1_60hz,'linear');
    temp3 = [temp1,cavel_mean(i,16),temp2];
    cavel_us(i,:) = temp3;
    clear temp1 temp2 temp3
end

%%
calocation = [ones(1,30),zeros(1,61)];
oalocation = [zeros(1,30),ones(1,61)];

%%
for i = 1 : size(gca_mean,1)
    tempinput = [calocation',cavel_us(i,:)'];
    temp = fitglm(tempinput,gca_mean(i,:)');
    regressioncoefficient_gca(:,i)=temp.Coefficients.Estimate(2:3);
    distance1 = sum((gca_mean(i,:)' - predict(temp, tempinput)).^2);
    temp1 = fitglm(tempinput(:,2:end),gca_mean(i,:)');
    distance2 = sum((gca_mean(i,:)' - predict(temp1, tempinput(:,2:end))).^2);
    temp2 = fitglm(tempinput(:,1),gca_mean(i,:)');
    distance3 = sum((gca_mean(i,:)' - predict(temp2, tempinput(:,1))).^2);

    cpd_gca_loc(i,1) = distance2 - distance1;
    cpd_gca_vel(i,1) = distance3 - distance1;
    clear temp temp1 temp2 tempinput distance1 distance2 distance3
end

for i = 1 : size(goa_mean,1)
    tempinput = [oalocation',oavel_us(i,:)'];
    temp = fitglm(tempinput,goa_mean(i,:)');
    regressioncoefficient_goa(:,i)=temp.Coefficients.Estimate(2:3);
    distance1 = sum((goa_mean(i,:)' - predict(temp, tempinput)).^2);
    temp1 = fitglm(tempinput(:,2:end),goa_mean(i,:)');
    distance2 = sum((goa_mean(i,:)' - predict(temp1, tempinput(:,2:end))).^2);
    temp2 = fitglm(tempinput(:,1),goa_mean(i,:)');
    distance3 = sum((goa_mean(i,:)' - predict(temp2, tempinput(:,1))).^2);

    cpd_goa_loc(i,1) = distance2 - distance1;
    cpd_goa_vel(i,1) = distance3 - distance1;
    clear temp temp1 temp2 tempinput distance1 distance2 distance3
end

for i = 1 : size(rca_mean,1)
    tempinput = [calocation',cavel_us(i,:)'];
    temp = fitglm(tempinput,rca_mean(i,:)');
    regressioncoefficient_rca(:,i)=temp.Coefficients.Estimate(2:3);
    distance1 = sum((rca_mean(i,:)' - predict(temp, tempinput)).^2);
    temp1 = fitglm(tempinput(:,2:end),rca_mean(i,:)');
    distance2 = sum((rca_mean(i,:)' - predict(temp1, tempinput(:,2:end))).^2);
    temp2 = fitglm(tempinput(:,1),rca_mean(i,:)');
    distance3 = sum((rca_mean(i,:)' - predict(temp2, tempinput(:,1))).^2);

    cpd_rca_loc(i,1) = distance2 - distance1;
    cpd_rca_vel(i,1) = distance3 - distance1;
    clear temp temp1 temp2 tempinput distance1 distance2 distance3
end

for i = 1 : size(roa_mean,1)
    tempinput = [oalocation',oavel_us(i,:)'];
    temp = fitglm(tempinput,roa_mean(i,:)');
    regressioncoefficient_roa(:,i)=temp.Coefficients.Estimate(2:3);
    distance1 = sum((roa_mean(i,:)' - predict(temp, tempinput)).^2);
    temp1 = fitglm(tempinput(:,2:end),roa_mean(i,:)');
    distance2 = sum((roa_mean(i,:)' - predict(temp1, tempinput(:,2:end))).^2);
    temp2 = fitglm(tempinput(:,1),roa_mean(i,:)');
    distance3 = sum((roa_mean(i,:)' - predict(temp2, tempinput(:,1))).^2);

    cpd_roa_loc(i,1) = distance2 - distance1;
    cpd_roa_vel(i,1) = distance3 - distance1;
    clear temp temp1 temp2 tempinput distance1 distance2 distance3
end

%%
mean_values = [
    mean(cpd_goa_loc), mean(cpd_goa_vel);
    mean(cpd_roa_loc), mean(cpd_roa_vel);
    mean(cpd_gca_loc), mean(cpd_gca_vel);
    mean(cpd_rca_loc), mean(cpd_rca_vel)
];

figure;
b = bar(mean_values, 'grouped');
hold on;


x_offset = [-0.02, 0.02]; 
all_data = {cpd_goa_loc, cpd_goa_vel, cpd_roa_loc, cpd_roa_vel, cpd_gca_loc, cpd_gca_vel, cpd_rca_loc, cpd_rca_vel};

xticks([1, 2 , 3, 4]);
xticklabels({'non-PV:OA', 'PV:OA', 'non-pv:CA', 'PV:CA'});

for i = 1:4 
    for j = 1:2 
        x = b(j).XEndPoints(i) + x_offset(j);
        
        scatter(repmat(x, size(all_data{(i-1)*2 + j})), all_data{(i-1)*2 + j}, 'filled');
    end
end



ylabel('Values');
legend({'Location', 'Velocity'}, 'Location', 'northeast');
title('CPD');
grid on;
hold off;
%%
% gca_mean calocation cavel_us
% window = 0.1 -> 6 data
for i = 1 : size(gca_mean,1)
    vel = cavel_us(i,:);
    vel(31) = [];
    loc = calocation;
    loc(31) = [];
    sig = gca_mean(i,:);
    sig(31) = [];
    for j = 1 : 6
        tempinput1 = [loc((j-1)*15+1:j*15)',vel((j-1)*15+1:j*15)'];
        tempinput2 = sig((j-1)*15+1:j*15)';
        temp = glmfit(tempinput1,tempinput2);
        temploccoef(1,j) = temp.Coefficients.Estimate(2);
        tempvelcoef(1,j) = temp.Coefficients.Estimate(3);
        clear temp tempinput1 tempinput2
    end
    gca_loccoef(i,:) = temploccoef;
    gca_velcoef(i,:) = tempvelcoef;
    clear temploccoef tempvelcoef vel loc sig
end

for i = 1 : size(rca_mean,1)
    vel = cavel_us(i,:);
    vel(31) = [];
    loc = calocation;
    loc(31) = [];
    sig = rca_mean(i,:);
    sig(31) = [];
    for j = 1 : 6
        tempinput1 = [loc((j-1)*15+1:j*15)',vel((j-1)*15+1:j*15)'];
        tempinput2 = sig((j-1)*15+1:j*15)';
        temp = fitglm(tempinput1,tempinput2);
        temploccoef(1,j) = temp.Coefficients.Estimate(2);
        tempvelcoef(1,j) = temp.Coefficients.Estimate(3);
        clear temp tempinput1 tempinput2
    end
    rca_loccoef(i,:) = temploccoef;
    rca_velcoef(i,:) = tempvelcoef;
    clear temploccoef tempvelcoef vel loc sig
end

for i = 1 : size(goa_mean,1)
    vel = oavel_us(i,:);
    vel(31) = [];
    loc = oalocation;
    loc(31) = [];
    sig = goa_mean(i,:);
    sig(31) = [];
    for j = 1 : 6
        tempinput1 = [loc((j-1)*15+1:j*15)',vel((j-1)*15+1:j*15)'];
        tempinput2 = sig((j-1)*15+1:j*15)';
        temp = fitglm(tempinput1,tempinput2);
        temploccoef(1,j) = temp.Coefficients.Estimate(2);
        tempvelcoef(1,j) = temp.Coefficients.Estimate(3);
        clear temp tempinput1 tempinput2
    end
    goa_loccoef(i,:) = temploccoef;
    goa_velcoef(i,:) = tempvelcoef;
    clear temploccoef tempvelcoef vel loc sig
end

for i = 1 : size(roa_mean,1)
    vel = oavel_us(i,:);
    vel(31) = [];
    loc = oalocation;
    loc(31) = [];
    sig = roa_mean(i,:);
    sig(31) = [];
    for j = 1 : 6
        tempinput1 = [loc((j-1)*15+1:j*15)',vel((j-1)*15+1:j*15)'];
        tempinput2 = sig((j-1)*15+1:j*15)';
        temp = fitglm(tempinput1,tempinput2);
        temploccoef(1,j) = temp.Coefficients.Estimate(2);
        tempvelcoef(1,j) = temp.Coefficients.Estimate(3);
        clear temp tempinput1 tempinput2
    end
    roa_loccoef(i,:) = temploccoef;
    roa_velcoef(i,:) = tempvelcoef;
    clear temploccoef tempvelcoef vel loc sig
end

for i = 1 : size(gca_loccoef,2)
    gca_lcmean(1,i) = mean(gca_loccoef(:,i));
end

for i = 1 : size(gca_velcoef,2)
    gca_vcmean(1,i) = mean(gca_velcoef(:,i));
end

figure;
plot(gca_lcmean);
hold on
plot(gca_vcmean,'r')