%%
clear 
close all

% CodingV2에서 Data Load
% 원하는 쥐 data를 load (514-2-4)
% 514-2-4 Baseline ChAT Neuron

load('C:\Users\user\Dropbox\Studies\Jung_lab\CIN study\Codingv2-20250316T050213Z-001\Codingv2\SyncedData250325.mat')
load('D:\CodingV2\matFiles\PCmatrix.mat')
load('D:\CodingV2\matFiles\BehaviorClustered_JK.mat')
% 853-1 temporary remove

%% correlation ChaT baseline
Tot_corr={}; data=[];
for index = 1:7;
T = fieldnames(synced_Chat_baseline);
field_name = T{index}; 
baselinechol = getfield(synced_Chat_baseline,field_name);

T2 = fieldnames(BehaviorClustered_Chat_baseline);
f2 = T2{index}; 
baselinecholbehav = getfield(BehaviorClustered_Chat_baseline,f2);

neuralsig = baselinechol.signal;
neuralchol = cell2mat(neuralsig(2:end,:));
neuralcholind = neuralsig(1,:); %index
CellProps = baselinechol.location; %Cell Number is included
CellPropsBaseline = CellProps(:, 2:3); 
NTime = baselinechol.Instime;
DLC = baselinechol.DLC;
DLCTime = baselinechol.DLCtime;

% Total
data = neuralchol;
for k=1:size(data,2)
    [temptime tempdata] = downsample_nn(NTime, zscore(data(:,k)),3);
    data_d(:,k) = tempdata;
end
PROPs = CellPropsBaseline;
[corrm1] = fn_corrcoef_simple(data_d, PROPs);  % fn1 호출

% behavioral cluster
% mobile
tm = baselinecholbehav.mobile;
for k=1:size(data,2)
for kk=1:length(tm)
    ttrace = zscore(data(:,k));    
    %convert DLC time to inscopix time
    window = [DLCTime(tm(kk,1)) DLCTime(tm(kk,2))]; [~, sind]=min(abs(window-NTime));    
    temp_mb = ttrace(sind(1):sind(2));temp_NT = NTime(sind(1):sind(2));
    [tempt tempmb] = downsample_nn(temp_NT, temp_mb,3);
    ttempmb(kk,:) = {tempmb};
    tttempmb = cell2mat(ttempmb);
end
    tmbtrace(:,k) = tttempmb; tmbmean(k,1) = mean(tttempmb);
    tttempmb=[];
end
[corrmb1] = fn_corrcoef_simple(tmbtrace, PROPs);  % fn1 호출
actmb = tmbmean;
clear tm ttrace window temp_mb sind temp_NT tempt tempmb ttempmb tmbtrace tmbmean
% stop
tm = baselinecholbehav.stop;
for k=1:size(data,2)
for kk=1:length(tm)
    ttrace = zscore(data(:,k));    
    %convert DLC time to inscopix downtime
    window = [DLCTime(tm(kk,1)) DLCTime(tm(kk,2))]; [~, sind]=min(abs(window-NTime));    
    temp_mb = ttrace(sind(1):sind(2));temp_NT = NTime(sind(1):sind(2));
    [tempt tempmb] = downsample_nn(temp_NT, temp_mb,3);
        mdstop = mean([sind(1) sind(2)]);
    temp_mb2 = ttrace(sind(1):mdstop);temp_NT2 = NTime(sind(1):mdstop); % early stop
    [tempt2 tempmb2] = downsample_nn(temp_NT2, temp_mb2,3);
    temp_mb3 = ttrace(mdstop:sind(2));temp_NT3 = NTime(mdstop:sind(2)); % all stop window
    [tempt3 tempmb3] = downsample_nn(temp_NT3, temp_mb3,3);
    ttempmb(kk,:) = {tempmb};ttempmb2(kk,:) = {tempmb2};ttempmb3(kk,:) = {tempmb3};
    tttempmb = cell2mat(ttempmb);tttempmb2 = cell2mat(ttempmb2);tttempmb3 = cell2mat(ttempmb3);
end
    tmbtrace(:,k) = tttempmb;tmbmean(k,1) = mean(tttempmb);
    tmbtrace2(:,k) = tttempmb2;tmbmean2(k,1) = mean(tttempmb2);
    tmbtrace3(:,k) = tttempmb3;tmbmean3(k,1) = mean(tttempmb3);
    tttempmb = []; tttempmb2 = []; tttempmb3 = [];
end
[corrst1] = fn_corrcoef_simple(tmbtrace, PROPs);  % fn1 호출
[corrst1_early] = fn_corrcoef_simple(tmbtrace2, PROPs);  % fn1 호출
[corrst1_late] = fn_corrcoef_simple(tmbtrace3, PROPs);  % fn1 호출
actst = tmbmean;actst_early = tmbmean2;actst_late = tmbmean3;
clear tm ttrace window temp_mb sind temp_NT tempt tempmb ttempmb tmbtrace tmbmean tmbmean2 tmbmean3 ttempmb3 ttempmb2
clear tempt2 tempmb2 temp_NT2 temp_mb2 tttempmb2 tmbtrace2
clear tempt3 tempmb3 temp_NT3 temp_mb3 tttempmb3 tmbtrace3
% forward
tm = baselinecholbehav.forward;
for k=1:size(data,2)
for kk=1:length(tm)
    ttrace = zscore(data(:,k));    
    %convert DLC time to inscopix time
    window = [DLCTime(tm(kk,1)) DLCTime(tm(kk,2))]; [~, sind]=min(abs(window-NTime));    
    temp_mb = ttrace(sind(1):sind(2));temp_NT = NTime(sind(1):sind(2));
    [tempt tempmb] = downsample_nn(temp_NT, temp_mb,3);
    ttempmb(kk,:) = {tempmb};
    tttempmb = cell2mat(ttempmb);
end
    tmbtrace(:,k) = tttempmb;tmbmean(k,1) = mean(tttempmb);
    tttempmb=[];
end
[corrf1] = fn_corrcoef_simple(tmbtrace, PROPs);  % fn1 호출
actfw = tmbmean;
clear tm ttrace window temp_mb sind temp_NT tempt tempmb ttempmb tmbtrace tmbmean
%  ipsiturn
tm = baselinecholbehav.ipsiturn;
for k=1:size(data,2)
for kk=1:length(tm)
    ttrace = zscore(data(:,k));    
    %convert DLC time to inscopix time
    window = [DLCTime(tm(kk,1)) DLCTime(tm(kk,2))]; [~, sind]=min(abs(window-NTime));    
    temp_mb = ttrace(sind(1):sind(2));temp_NT = NTime(sind(1):sind(2)); % all stop window
    [tempt tempmb] = downsample_nn(temp_NT, temp_mb,3);
     ttempmb(kk,:) = {tempmb};
    tttempmb = cell2mat(ttempmb);
end
    tmbtrace(:,k) = tttempmb;tmbmean(k,1) = mean(tttempmb);
    tttempmb=[];
end
[corripsi1] = fn_corrcoef_simple(tmbtrace, PROPs);  % fn1 호출
actipsi = tmbmean;
clear tm ttrace window temp_mb sind temp_NT tempt tempmb ttempmb tmbtrace tmbmean
% contraturn
tm = baselinecholbehav.contraturn;
for k=1:size(data,2)
for kk=1:length(tm)
    ttrace = zscore(data(:,k));    
    %convert DLC time to inscopix time
    window = [DLCTime(tm(kk,1)) DLCTime(tm(kk,2))]; [~, sind]=min(abs(window-NTime));    
    temp_mb = ttrace(sind(1):sind(2));temp_NT = NTime(sind(1):sind(2));
    [tempt tempmb] = downsample_nn(temp_NT, temp_mb,3);
    ttempmb(kk,:) = {tempmb};
    tttempmb = cell2mat(ttempmb);
end
    tmbtrace(:,k) = tttempmb;tmbmean(k,1) = mean(tttempmb);
    tttempmb=[];
end
[corrcont1] = fn_corrcoef_simple(tmbtrace, PROPs);  % fn1 호출
actcontra = tmbmean;
clear tm ttrace window temp_mb sind temp_NT tempt tempmb ttempmb tmbtrace tmbmean
% correlation
Tot_corr(index,1) = corrm1;Tot_corr(index,2) = corrmb1; Tot_corr(index,3) = corrf1;  Tot_corr(index,4) = corripsi1; Tot_corr(index,5) = corrcont1; Tot_corr(index,6) = corrst1;Tot_corr(index,7) = corrst1_early;Tot_corr(index,8) = corrst1_late;
Tot_act(index,1) = {[actmb actfw actcontra actipsi actst actst_early actst_late]};
% if size(corrm1{:,1},1) >1
% Tot_corr(index,2) = {nanmean(corrm1{:,1})}; 
% else
%   Tot_corr(index,2) = {(corrm1{:,1})};
% end
clear corrm1 corrmb1 corrf1 corripsi1 corrcont1 corrst1 actmb actfw actcontra actipsi actst tempdata temptime data data_d 
clear corrst1 corrst1_early corrst1_late
end

%% correlation ChaT parkinson
Tot_corrp={};
for index = 1:6;

Tp = fieldnames(synced_Chat_parkinson);
field_name = Tp{index}; 
parkchol = getfield(synced_Chat_parkinson, field_name);

T2 = fieldnames(BehaviorClustered_Chat_parkinson);
f2 = T2{index}; 
parkinsoncholbehav = getfield(BehaviorClustered_Chat_parkinson,f2);

neuralsigp = parkchol.signal;
neuralcholpark = cell2mat(neuralsigp(2:end,:));
neuralcholindpark = neuralsigp(1,:); %index
CellPropsp = parkchol.location; %Cell Number is included
CellPropsparkinson = CellPropsp(:, 2:3); 
NTimep = parkchol.Instime;
DLCp = parkchol.DLC;
DLCTimep = parkchol.DLCtime;

% Total
datap = neuralcholpark;
for k=1:size(datap,2)
    
    [temptimep tempdatap] = downsample_nn(NTimep, zscore(datap(:,k)),3);
    data_dp(:,k) = tempdatap;
end
PROPsp = CellPropsparkinson;
[corrm1] = fn_corrcoef_simple(data_dp, PROPsp);  % fn1 호출

% behavioral cluster
% mobile
tm = parkinsoncholbehav.mobile;
for k=1:size(datap,2)
for kk=1:length(tm)
    ttrace = zscore(datap(:,k));    
    %convert DLC time to inscopix time
    window = [DLCTimep(tm(kk,1)) DLCTimep(tm(kk,2))]; [~, sind]=min(abs(window-NTimep));    
    temp_mb = ttrace(sind(1):sind(2));temp_NT = NTimep(sind(1):sind(2));
    [tempt tempmb] = downsample_nn(temp_NT, temp_mb,3);
    ttempmb(kk,:) = {tempmb};
    tttempmb = cell2mat(ttempmb);
end
    tmbtrace(:,k) = tttempmb; tmbmean(k,1) = mean(tttempmb);
    tttempmb=[];
end
[corrmb1] = fn_corrcoef_simple(tmbtrace, PROPsp);  % fn1 호출
actmb = tmbmean;
clear tm ttrace window temp_mb sind temp_NT tempt tempmb ttempmb tmbtrace tmbmean tttempmb
% stop
tm = parkinsoncholbehav.stop;
for k=1:size(datap,2)
for kk=1:length(tm)
    ttrace = zscore(datap(:,k));    
    %convert DLC time to inscopix time
    window = [DLCTimep(tm(kk,1)) DLCTimep(tm(kk,2))]; [~, sind]=min(abs(window-NTimep));    
    temp_mb = ttrace(sind(1):sind(2));temp_NT = NTimep(sind(1):sind(2));
    [tempt tempmb] = downsample_nn(temp_NT, temp_mb,3);
            mdstop = mean([sind(1) sind(2)]);
    temp_mb2 = ttrace(sind(1):mdstop);temp_NT2 = NTimep(sind(1):mdstop); % early stop
    [tempt2 tempmb2] = downsample_nn(temp_NT2, temp_mb2,3);
    temp_mb3 = ttrace(mdstop:sind(2));temp_NT3 = NTimep(mdstop:sind(2)); % all stop window
    [tempt3 tempmb3] = downsample_nn(temp_NT3, temp_mb3,3);
    ttempmb(kk,:) = {tempmb};ttempmb2(kk,:) = {tempmb2};ttempmb3(kk,:) = {tempmb3};
    tttempmb = cell2mat(ttempmb);tttempmb2 = cell2mat(ttempmb2);tttempmb3 = cell2mat(ttempmb3);
end
    tmbtrace(:,k) = tttempmb;tmbmean(k,1) = mean(tttempmb);
    tmbtrace2(:,k) = tttempmb2;tmbmean2(k,1) = mean(tttempmb2);
    tmbtrace3(:,k) = tttempmb3;tmbmean3(k,1) = mean(tttempmb3);
    tttempmb = []; tttempmb2 = []; tttempmb3 = [];
end
[corrst1] = fn_corrcoef_simple(tmbtrace, PROPsp);  % fn1 호출
[corrst1_early] = fn_corrcoef_simple(tmbtrace2, PROPsp);  % fn1 호출
[corrst1_late] = fn_corrcoef_simple(tmbtrace3, PROPsp);  % fn1 호출
actst = tmbmean;actst_early = tmbmean2;actst_late = tmbmean3;
clear tm ttrace window temp_mb sind temp_NT tempt tempmb ttempmb tmbtrace tmbmean tmbmean2 tmbmean3 ttempmb3 ttempmb2
clear tempt2 tempmb2 temp_NT2 temp_mb2 tttempmb2 tmbtrace2
clear tempt3 tempmb3 temp_NT3 temp_mb3 tttempmb3 tmbtrace3

% forward
tm = parkinsoncholbehav.forward;
for k=1:size(datap,2)
for kk=1:length(tm)
    ttrace = zscore(datap(:,k));    
    %convert DLC time to inscopix time
    window = [DLCTimep(tm(kk,1)) DLCTimep(tm(kk,2))]; [~, sind]=min(abs(window-NTimep));    
    temp_mb = ttrace(sind(1):sind(2));temp_NT = NTimep(sind(1):sind(2));
    [tempt tempmb] = downsample_nn(temp_NT, temp_mb,3);
    ttempmb(kk,:) = {tempmb};
    tttempmb = cell2mat(ttempmb);
end
    tmbtrace(:,k) = tttempmb;tmbmean(k,1) = mean(tttempmb);
    tttempmb=[];
end
[corrf1] = fn_corrcoef_simple(tmbtrace, PROPsp);  % fn1 호출
actfw = tmbmean;
clear tm ttrace window temp_mb sind temp_NT tempt tempmb ttempmb tmbtrace tmbmean tttempmb
% stop
tm = parkinsoncholbehav.ipsiturn;
for k=1:size(datap,2)
for kk=1:length(tm)
    ttrace = zscore(datap(:,k));    
    %convert DLC time to inscopix time
    window = [DLCTimep(tm(kk,1)) DLCTimep(tm(kk,2))]; [~, sind]=min(abs(window-NTimep));    
    temp_mb = ttrace(sind(1):sind(2));temp_NT = NTimep(sind(1):sind(2));
    [tempt tempmb] = downsample_nn(temp_NT, temp_mb,3);
    ttempmb(kk,:) = {tempmb};
    tttempmb = cell2mat(ttempmb);
end
    tmbtrace(:,k) = tttempmb;tmbmean(k,1) = mean(tttempmb);
    tttempmb=[];
end
[corripsi1] = fn_corrcoef_simple(tmbtrace, PROPsp);  % fn1 호출
actipsi = tmbmean;
clear tm ttrace window temp_mb sind temp_NT tempt tempmb ttempmb tmbtrace tmbmean tttempmb
% contraturn
tm = parkinsoncholbehav.contraturn;
if isempty(tm) <1;
for k=1:size(datap,2)
for kk=1:length(tm)
    ttrace = zscore(datap(:,k));    
    %convert DLC time to inscopix time
    window = [DLCTimep(tm(kk,1)) DLCTimep(tm(kk,2))]; [~, sind]=min(abs(window-NTimep));    
    temp_mb = ttrace(sind(1):sind(2));temp_NT = NTimep(sind(1):sind(2));
    [tempt tempmb] = downsample_nn(temp_NT, temp_mb,3);
    ttempmb(kk,:) = {tempmb};
    tttempmb = cell2mat(ttempmb);
end
    tmbtrace(:,k) = tttempmb;tmbmean(k,1) = mean(tttempmb);
    tttempmb=[];
end
[corrcont1] = fn_corrcoef_simple(tmbtrace, PROPsp);  % fn1 호출
actcontra = tmbmean;
else
corrcont1={[-100 -100 -100 -100]};actcontra=[ones(length(actmb),1)*(-100)];
end
clear tm ttrace window temp_mb sind temp_NT tempt tempmb ttempmb tmbtrace tmbmean tttempmb
% correlation
Tot_corrp(index,1) = corrm1;Tot_corrp(index,2) = corrmb1; Tot_corrp(index,3) = corrf1;  Tot_corrp(index,4) = corripsi1; Tot_corrp(index,5) = corrcont1; Tot_corrp(index,6) = corrst1;Tot_corrp(index,7) = corrst1_early;Tot_corrp(index,8) = corrst1_late;
Tot_actp(index,1) = {[actmb actfw actcontra actipsi actst actst_early actst_late]};
% if size(corrm1{:,1},1) >1
% Tot_corr(index,2) = {nanmean(corrm1{:,1})}; 
% else
%   Tot_corr(index,2) = {(corrm1{:,1})};
% end
clear corrm1 corrmb1 corrf1 corripsi1 corrcont1 corrst1 actmb actfw actcontra actipsi actst tempdata temptime data data_d 
clear corrst1 corrst1_early corrst1_late
% if size(corrmp1{:,1},1)>1
%     Tot_corrp(index,2) = {nanmean(corrmp1{:,1})};
% else
%       Tot_corrp(index,2) = {(corrmp1{:,1})};
% end
clear tempdata tempdatap temptime temptimep PROPsp data_dp data_d
clear corrm1 corrmp1 data data_d PROPs PROPsp data_dp NTime NTimep

end
%% Chat Parkinson

for k=1:6
    Bloc(k,:) = Tot_Nvdata{k,1}(1,:); % baseline loc
    Bstop(k,:) = Tot_Nvdata{k,1}(2,:); % baseline stop
    Bstop2(k,:) = Tot_Nvdata{k,1}(3,:); % baseline stop2

    Ploc(k,:) = Tot_Nvdata{k,1}(4,:); % parkinson loc  
    Pstop(k,:) = Tot_Nvdata{k,1}(5,:); % parkinson stop
    Pstop2(k,:) = Tot_Nvdata{k,1}(6,:); % parkinson stop2
end

num_timepoints = 51;
mean_speed = mean(Bloc, 1);
sem_speed = std(Bstop, 0, 1) / sqrt(6); % SEM 계산

mean_speedp = mean(Ploc, 1);
sem_speedp = std(Pstop, 0, 1) / sqrt(6); % SEM 계산

% x축 정의 (1~51)
x = 1:num_timepoints;

% 그림 그리기
figure;
hold on;
shadedErrorBar(x, mean_speed, sem_speed, 'lineProps', {'b', 'LineWidth', 2}); % 평균 + SEM 시각화
plot(x, mean_speed, 'b', 'LineWidth', 2); % 평균 속도 선

shadedErrorBar(x, mean_speedp, sem_speedp, 'lineProps', {'r', 'LineWidth', 2}); % 평균 + SEM 시각화
plot(x, mean_speedp, 'r', 'LineWidth', 2); % 평균 속도 선

% x=20에 수직 점선 추가
xline(20, '--k', 'LineWidth', 1.5);
xlim([10 40])
% 그래프 설정
xlabel('Time');
ylabel('Speed');

for k=2:7
flattened_data = [];
data = Tot_Nvdata(:,k);
for i = 1:length(data)
    inner_cell = data{i};  % 내부 cell 배열 (예: 4x1, 13x1 등)
    for ii = 1:length(inner_cell)
        temp = inner_cell{ii};
        inner_cell2(ii,:) = mean(temp(2:end,:));
    end
    % cell을 double로 변환하고 추가
    flattened_data = [flattened_data; inner_cell2];
    inner_cell2=[];
end
 TNdat(k-1,1) = {flattened_data};
end

num_timepoints = 101;
mean_speed = mean(TNdat{1}, 1);
sem_speed = std(TNdat{3}, 0, 1) / sqrt(size(TNdat{1},2)); % SEM 계산

mean_speedp = mean(TNdat{4}, 1);
sem_speedp = std(TNdat{6}, 0, 1) / sqrt(size(TNdat{4},2)); % SEM 계산

% x축 정의 (1~51)
x = 1:num_timepoints;

% 그림 그리기
figure;
hold on;
shadedErrorBar(x, mean_speed, sem_speed, 'lineProps', {'b', 'LineWidth', 2}); % 평균 + SEM 시각화
plot(x, mean_speed, 'b', 'LineWidth', 2); % 평균 속도 선

shadedErrorBar(x, mean_speedp, sem_speedp, 'lineProps', {'r', 'LineWidth', 2}); % 평균 + SEM 시각화
plot(x, mean_speedp, 'r', 'LineWidth', 2); % 평균 속도 선

% x=20에 수직 점선 추가
xline(40, '--k', 'LineWidth', 1.5);
xlim([20 80])
% 그래프 설정
xlabel('Time');
ylabel('Speed');


%% Baseline - Parkinson Paired Neuron 추출
% 같은 neuron index
sameneuronindex = {};
ind = {'C17' 'C36' 'C02' 'C35' 'C67' 'C04'}; % 514-2-4

neuralsigp_matched =[];
for k=1:length(ind)
    indices = find(strcmp(neuralcholindpark, ind(k)));
    neuralsigp_matched(:,k) = neuralcholpark(:,indices);
    CellPropsparkinson_matched(k,:) = CellPropsparkinson(indices,:);
end

% 514-2-4 C71이 없음
neuralchol2 = neuralchol(:, [1 2 3 4 5 7]);
for k=1:size(neuralchol2,2)
neuralchol2z(:,k) = zscore(neuralchol2(:,k));
end
Cellpropsbaseline2 = CellPropsBaseline( [1 2 3 4 5 7],:);

% location 
CellProps = baselinechol.location;
CellPropsBaseline = CellProps(:, 2:3); 

%% Mean Correlation Coefficient를 구하기

% 514-2-4 Parkinson 데이터 처리
data = neuralsigp_matched;
PROPs = CellPropsparkinson_matched;
[corrm1] = HK_fn1(data, PROPs);  % fn1 호출

% 514-2-4 Baseline 데이터 처리
synced = neuralchol2;
PROPs1 = Cellpropsbaseline2;
[corrm2] = HK_fn1(synced, PROPs1);  % fn1 호출

subplot(1,3,1)
d = [mean(corrm2(:,1)) mean(corrm1(:,1))]
bar(d)
subplot(1,3,2)
scatter(corrm2(:,2),corrm2(:,1), 'o')
subplot(1,3,3)
scatter(corrm1(:,2),corrm1(:,1), 'o')

%% Onset전후의 corrcoef 변화 구하기 (514-2-4)

% mobile vs immobile 찾기
% DLC -> velocity 구하기

DLCv=smoothdata(diff(DLCb)); % baseline velocity
DLCpv=smoothdata(diff(DLCp)); % Parkinson velocity

for k=1:length(DLCv);
    DLCv2(k,1) = abs(DLCv(k,1) + i*DLCv(k,2));
     DLCpv2(k,1) = abs(DLCpv(k,1) + i*DLCpv(k,2));
end

% median filter
Cv = medfilt1(DLCv2);Cvp = medfilt1(DLCpv2);

DLCv2z = smoothdata(zscore(DLCv2)); % baseline velocity Z-score
DLCpv2z = smoothdata(zscore(DLCpv2)); % Parkinson velocity Z-score
 
mobindx = DLCv2z > 1; % baseline mobile index

[coeff score latent] = pca(neuralchol2)

plot(score(:,1), score(:,2), '.')

hold on
plot(score(mobindx,1), score(mobindx,2),'.','Color','b') % mobile
plot(score(mobindx==0,1), score(mobindx==0,2),'.','Color','r') % immobile

mobindxp = DLCpv2 > 2; % Parkinson mobile index


[coeff score latent] = pca(neuralchol2)

for k=1:size(score,2)
score2(:,k) = zscore(score(:,k));
end
score = score2 % normalized PC score

plot(score(:,1), score(:,2), '.')

hold on
plot(score(mobindxp,1), score(mobindxp,2),'.','Color','b') % mobile
plot(score(mobindxp==0,1), score(mobindxp==0,2),'.','Color','r') % immobile

%% onset => mobindex가 시작되는 시점 onset을 찾는다.
% 0.1s 기준
% mobindx에서 0에서 1로 바뀐 지점 찾기
changes = find(diff(mobindx) == 1);  % 514-2-4 baseline
changest = find(diff(mobindx) == -1);  % 514-2-4 baseline
change = [changes changest changest-changes];
% 1초이상 움직인 window만 고르기
change = change(change(:,3)>9,:);

% mobindx에서 0에서 1로 바뀐 지점 찾기
changesp = find(diff(mobindxp) == 1);  % 514-2-4 Parkinson


%% onset 전후로 -1초부터 2초까지의 PCA score를 구한다. (score)
% 514-2-4 baseline
tempdat = {};
for t=1:length(changes)
ex = changes(t)*2; % 0.1s로 찾은 onset을 neural signal에 적용하기 위해서는 0.05s scale로 바꿔야 해서 x2배
timebin = ex-10:ex+20;
tempdat_pc1(t,:) = score(timebin,1);
tempdat_pc2(t,:) = score(timebin,2);
end

%% onset 전후로 -1초부터 2초까지의 neural activity 변화를 구한다.
% 514-2-4 baseline
tempdat = {};tempdata_na1=[];
for kk=1:size(neuralchol2,2)
for t=1:length(change)
ex = change(t,1)*2; % 0.1s로 찾은 onset을 neural signal에 적용하기 위해서는 0.05s scale로 바꿔야 해서 x2배
timebin = ex-10:ex+20;
tempdat_na1(t,:) = neuralchol2z(timebin,kk);
end
tempdat_naz(kk,:) = mean(tempdat_na1); % start
end

% 514-2-4 baseline
tempdat = {};tempdata_na1=[];
for kk=1:size(neuralchol2,2)
for t=1:length(change)
ex = change(t,2)*2; % 0.1s로 찾은 onset을 neural signal에 적용하기 위해서는 0.05s scale로 바꿔야 해서 x2배
timebin = ex-10:ex+20;
tempdat_na2(t,:) = neuralchol2z(timebin,kk);
end
tempdat_nazs(kk,:) = mean(tempdat_na2); % stop
end



% 514-2-4 Parkinson
tempdatp = {};
for t=1:length(changesp)
ex = changesp(t);
timebin = ex-10:ex+20;
tempdatp_pc1(t,:) = score(timebin,1);
tempdatp_pc2(t,:) = score(timebin,2);
end

hold on
% baseline과 parkinson의 onset전후의 PC변화
plot(mean(tempdat_pc1),mean(tempdat_pc2)); 
% parkinson


% ex = 200; % Example
% timebin = ex-10:ex+20;
% plot(score(timebin,1),score(timebin,2)) 

%% 모든 onset의 mean값으로 baseline, parkinson 그려보기
% 514-2-4 Baseline
% onset 찾기: mobindx 값이 0에서 1로 변하는 시점을 찾음
onset_idx = find(mobindx >= 0.99, 1);  % mobindex가 1에 근접하는 첫 번째 인덱스

% onset에서의 mean corrcoeff 값
onset_corrcoeff = corrm2(onset_idx);

% mobindx와 corrm2 길이가 같은지 확인
if length(mobindx) ~= length(corrm2)
    error('mobindx와 corrm2 벡터의 길이가 동일해야 합니다.');
end

figure; 
plot(mobindx, corrm2, '-o', 'LineWidth', 2); 
hold on;
plot(mobindx(onset_idx), corrm2(onset_idx), 'ro', 'MarkerFaceColor', 'r'); 
grid on;
legend('Corrm2', 'Onset Point');

% 853-1


%% sliding correlation을 구해보자
%이전 HK_fn1은 전체 time에 대한 correlation이었음. (:,k) 이런식으로
% 그런데 시간에 따른 correlation의 변화를 보기 위해서는 (: ==> 1,2,3이렇게 바뀌어야 함)
% correlation을 구할 window 크기를 정하고, step 수도 정하고
% ex> 5개를 합치면 0.5s 1개씩 전진한다면 0.1s씩 전진

%% behavior cluster

 thstopind = find(Cv10 <= (mean(Cv10)-0.5*std(Cv10) & Nv10 <=(mean(Nv10)-0.5*std(Nv10)) & Tv10 <=(mean(Tv10)-0.5*std(Tv10))));
 thstopend = thstopind(find(diff(thstopind)>1));
 thstopstr = thstopind(find(diff(thstopind)>1)+1);
 thstopstr = [thstopind(1);thstopstr(1:end-1)];



