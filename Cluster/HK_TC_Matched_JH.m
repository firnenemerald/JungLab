%% HK_TC_Matched_JH.m

clear 
close all

% Load synced data
load("C:\Users\chanh\Downloads\ChAT_cluster\SyncedData.mat")

% Get baseline neural signals

% neuralsig = baselinechol.signal;
% neuralchol = cell2mat(neuralsig(2:end,:));
% neuralcholind = neuralsig(1,:); %index

% Get parkinson neural signals

%% Baseline - Parkinson Paired Neuron 추출
% 같은 neuron index
load("./sameneuronindex.mat")
sameneuronindex2 = {};
mouseNum = size(sameneuronindex, 1);
for m = 1:mouseNum
    pairs = {};
    ref = sameneuronindex{m, 2};
    for i = 1:size(ref, 1)
        if ~(isempty(ref{i, 1}) | isempty(ref{i, 2}))
            pairs = [pairs; ref(i, :)];
        end
    end
    sameneuronindex2{m, 1} = sameneuronindex{m, 1};
    sameneuronindex2{m, 2} = pairs;
end

baselineMatchSignal = [];
parkinsonMatchSignal = [];
for m = 1:6
    [neuralchol, neuralcholpark, neuralcholind, neuralcholindpark] = getNeuralSignal(m, synced_Chat_baseline, synced_Chat_parkinson);
    %mouseName = sameneuronindex2{m, 1};
    mouseMatch = sameneuronindex2{m, 2};
    for i = 1:size(mouseMatch, 1)
        c1 = mouseMatch{i, 1};
        c2 = mouseMatch{i, 2};
        
        bm = neuralchol(:, find(strcmp(neuralcholind, c1)));
        pm = neuralcholpark(:, find(strcmp(neuralcholindpark, c2)));
        baselineMatchSignal = [baselineMatchSignal; bm];
        parkinsonMatchSignal = [parkinsonMatchSignal; pm];
    end
end

% ind = {'C17' 'C36' 'C02' 'C35' 'C67' 'C04'}; % 514-2-4

neuralsigp_matched =[];
for k=1:length(ind)
    indices = find(strcmp(neuralcholindpark, ind(k)));
    neuralsigp_matched(:,k) = neuralcholpark(:,indices);
    CellPropsparkinson_matched(k,:) = CellPropsparkinson(indices,:);
end

% 514-2-4 C71이 없음
% neuralchol2 = neuralchol(:, [1 2 3 4 5 7]);
% for k=1:size(neuralchol2,2)
% neuralchol2z(:,k) = zscore(neuralchol2(:,k));
% end
% Cellpropsbaseline2 = CellPropsBaseline( [1 2 3 4 5 7],:);

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


