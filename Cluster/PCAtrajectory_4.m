close all
clear

clear 
close all

load('C:\Users\neosj\Dropbox\Studies\Jung_lab\CIN study\Codingv2-20250316T050213Z-001\Codingv2\PCmatrix.mat')
load('C:\Users\neosj\Dropbox\MATLAB\ODPCC\color_setting\color_set.mat');


%% 데이터 예제 (이미 data1, data2가 준비되었다고 가정)
 data1= ForwardSig_Chatbaseline;
 data2 = CturnSig_Chatbaseline;
 data3 = IturnSig_Chatbaseline;
 data4 = StopSig_Chatbaseline;

%% Joint PCA를 이용한 Ensemble Trajectory 분석 (한 그룹, 4 이벤트)
% 데이터 형식: data: [T x N x K]
% T: timebins (예: 41), N: neuron 수 (81), K: 이벤트 수 (4)
T = 81;                
N = 81;                
K = 2;                 
time = linspace(-1, 1, T);  % 각 이벤트의 시간 벡터 (-1초 ~ 1초)

%% 1. 예시 데이터 생성


data(:,:,1) = data1(:,21:end);
data(:,:,2) = data2(:,21:end);
data(:,:,3) = data3(:,21:end);
data(:,:,4) = data4(:,21:end);

%% 전체 그림 구성
nRow = 6;
nCol = 6;
fHandle = figure('PaperUnits','centimeters','PaperPosition',[0 0 17.4*2 17.4*2],'Renderer','Painters');
%% 1. 상단 2x2 heatmap: 각 이벤트의 neural ensemble (81개 뉴런의 상관관계 행렬)
nEvents = size(data, 3);
nncol = [[1:3];[4:6];[1:3];[4:6]];
nnRow = [[1:2];[1:2];[3:4];[3:4]];
for i = 1:nEvents
    % 각 이벤트 데이터 추출 (크기: 81 x timebin_i)
    eventData = data(:,:,i);
    % 뉴런 간 상관관계 행렬 계산 (뉴런이 행에 있으므로 transpose)
    corrMat = corrcoef(eventData');
   
    h = axes('Position',axpt(nCol,nRow,nncol(i,:),nnRow(i,:),[],wideInterval));
%     hold on 
    imagesc(corrMat);
    colormap(jet)
    colorbar;
    title(sprintf('Event %d Correlation', i));
    xlabel('Neuron');
    ylabel('Neuron');
end

%% 데이터 예제 (이미 data1, data2가 준비되었다고 가정)
 data1= ForwardSig_Chatbaseline;
 data2 = CturnSig_Chatbaseline;
 data3 = IturnSig_Chatbaseline;
 data4 = StopSig_Chatbaseline;
 
data=[];
data(:,:,1) = data1(:,21:61);
data(:,:,2) = data2(:,21:61);
data(:,:,3) = data3(:,21:61);
data(:,:,4) = data4(:,21:61);

%% data: 81 x 61 x 4 (81 neurons, 61 time points, 4 events)
   h = axes('Position',axpt(nCol,nRow,1:2,5:6,[],wideInterval));
hold on;
colors = lines(4);  % 4개 이벤트에 대한 색상 지정
windowSize = 5;     % smoothing을 위한 윈도우 크기 (필요에 따라 조정)

for ev = [1 4]
    % 각 이벤트 데이터 추출 (뉴런 x 타임포인트)
    eventData = data(:,:,ev);
    
    % 각 시간 포인트를 하나의 샘플로 보고 PCA 수행 (행: 타임포인트, 열: 뉴런)
    [coeff, score, ~] = pca(eventData');  % score: 61 x numVariables, 첫 3개가 PC1, PC2, PC3
    
    % 첫 3개 주성분에 대해 smoothing 적용
    score_smoothed1 = smoothdata(score(:,1), 'movmean', windowSize);
    score_smoothed2 = smoothdata(score(:,2), 'movmean', windowSize);
    score_smoothed3 = smoothdata(score(:,3), 'movmean', windowSize);
    
    % 3D trajectory 플롯 (plot3: x=PC1, y=PC2, z=PC3)
    plot3(score_smoothed1, score_smoothed2, score_smoothed3, 'Color', colors(ev,:), 'LineWidth', 2);
    % 첫 번째 포인트: 파란색 점
    scatter3(score_smoothed1(1), score_smoothed2(1), score_smoothed3(1), 50, 'b', 'filled');
    % 20번째 포인트: 검은색 점
    scatter3(score_smoothed1(20), score_smoothed2(20), score_smoothed3(20), 50, 'k', 'filled');
    % 마지막 포인트: 빨간색 점
    scatter3(score_smoothed1(end), score_smoothed2(end), score_smoothed3(end), 50, 'r', 'filled');

    
    % 시작점과 종료점 표시
    scatter3(score_smoothed1(1), score_smoothed2(1), score_smoothed3(1), 50, colors(ev,:), 'filled');
    scatter3(score_smoothed1(end), score_smoothed2(end), score_smoothed3(end), 50, colors(ev,:), 'd', 'filled');
end

xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
title('Smoothed 3D Neural Trajectories for 4 Events');
grid on;
view(3);
hold off;

h = axes('Position',axpt(nCol,nRow,3:4,5:6,[],wideInterval));
hold on
for ev = [1 2]
    % 각 이벤트 데이터 추출 (뉴런 x 타임포인트)
    eventData = data(:,:,ev);
    
    % 각 시간 포인트를 하나의 샘플로 보고 PCA 수행 (행: 타임포인트, 열: 뉴런)
    [coeff, score, ~] = pca(eventData');  % score: 61 x numVariables, 첫 3개가 PC1, PC2, PC3
    
    % 첫 3개 주성분에 대해 smoothing 적용
    score_smoothed1 = smoothdata(score(:,1), 'movmean', windowSize);
    score_smoothed2 = smoothdata(score(:,2), 'movmean', windowSize);
    score_smoothed3 = smoothdata(score(:,3), 'movmean', windowSize);
    
    % 3D trajectory 플롯 (plot3: x=PC1, y=PC2, z=PC3)
    plot3(score_smoothed1, score_smoothed2, score_smoothed3, 'Color', colors(ev,:), 'LineWidth', 2);
    % 첫 번째 포인트: 파란색 점
    scatter3(score_smoothed1(1), score_smoothed2(1), score_smoothed3(1), 50, 'b', 'filled');
    % 20번째 포인트: 검은색 점
    scatter3(score_smoothed1(20), score_smoothed2(20), score_smoothed3(20), 50, 'k', 'filled');
    % 마지막 포인트: 빨간색 점
    scatter3(score_smoothed1(end), score_smoothed2(end), score_smoothed3(end), 50, 'r', 'filled');

    
    % 시작점과 종료점 표시
    scatter3(score_smoothed1(1), score_smoothed2(1), score_smoothed3(1), 50, colors(ev,:), 'filled');
    scatter3(score_smoothed1(end), score_smoothed2(end), score_smoothed3(end), 50, colors(ev,:), 'd', 'filled');
end

xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
title('Smoothed 3D Neural Trajectories for 4 Events');
grid on;
view(3);
hold off;

h = axes('Position',axpt(nCol,nRow,5:6,5:6,[],wideInterval));
hold on
for ev = [2 3]
    % 각 이벤트 데이터 추출 (뉴런 x 타임포인트)
    eventData = data(:,:,ev);
    
    % 각 시간 포인트를 하나의 샘플로 보고 PCA 수행 (행: 타임포인트, 열: 뉴런)
    [coeff, score, ~] = pca(eventData');  % score: 61 x numVariables, 첫 3개가 PC1, PC2, PC3
    
    % 첫 3개 주성분에 대해 smoothing 적용
    score_smoothed1 = smoothdata(score(:,1), 'movmean', windowSize);
    score_smoothed2 = smoothdata(score(:,2), 'movmean', windowSize);
    score_smoothed3 = smoothdata(score(:,3), 'movmean', windowSize);
    
    % 3D trajectory 플롯 (plot3: x=PC1, y=PC2, z=PC3)
    plot3(score_smoothed1, score_smoothed2, score_smoothed3, 'Color', colors(ev,:), 'LineWidth', 2);
    % 첫 번째 포인트: 파란색 점
    scatter3(score_smoothed1(1), score_smoothed2(1), score_smoothed3(1), 50, 'b', 'filled');
    % 20번째 포인트: 검은색 점
    scatter3(score_smoothed1(20), score_smoothed2(20), score_smoothed3(20), 50, 'k', 'filled');
    % 마지막 포인트: 빨간색 점
    scatter3(score_smoothed1(end), score_smoothed2(end), score_smoothed3(end), 50, 'r', 'filled');

    
    % 시작점과 종료점 표시
    scatter3(score_smoothed1(1), score_smoothed2(1), score_smoothed3(1), 50, colors(ev,:), 'filled');
    scatter3(score_smoothed1(end), score_smoothed2(end), score_smoothed3(end), 50, colors(ev,:), 'd', 'filled');
end

xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
title('Smoothed 3D Neural Trajectories for 4 Events');
grid on;
view([-69.0583 23.7001]);
hold off;
pause
% baseline
close
%% parkinson

 data1p = ForwardSig_Chatparkinson;
%  data2p = CturnSig_Chatparkinson';
 data3p = IturnSig_Chatparkinson;
 data4p = StopSig_Chatparkinson;

%% Joint PCA를 이용한 Ensemble Trajectory 분석 (한 그룹, 4 이벤트)
% 데이터 형식: data: [T x N x K]
% T: timebins (예: 41), N: neuron 수 (81), K: 이벤트 수 (4)
T = 81;                
N = 29;                
K = 2;                 
time = linspace(-1, 1, T);  % 각 이벤트의 시간 벡터 (-1초 ~ 1초)

datap=[];
datap(:,:,1) = data1p(:,1:end);
% datap(:,:,2) = data2p(:,21:end);
datap(:,:,2) = data3p(:,1:end);
datap(:,:,3) = data4p(:,1:end);

%% 전체 그림 구성
nRow = 2;
nCol = 3;
fHandle = figure('PaperUnits','centimeters','PaperPosition',[0 0 17.4*2 17.4*(6/5)],'Renderer','Painters');
% 1. 상단 2x2 heatmap: 각 이벤트의 neural ensemble (81개 뉴런의 상관관계 행렬)
nEvents = size(datap, 3);

% nncol = [[1:3];[4:6];[1:3];[4:6]];
% nnRow = [[1:2];[1:2];[3:4];[3:4]];
for i = 1:nEvents
    % 각 이벤트 데이터 추출 (크기: 81 x timebin_i)
    eventData = datap(:,:,i);
    % 뉴런 간 상관관계 행렬 계산 (뉴런이 행에 있으므로 transpose)
    corrMat = corrcoef(eventData');
   
    h = axes('Position',axpt(nCol,nRow,i,1,[],wideInterval));
%     hold on 
    imagesc(corrMat);
    colormap(jet)
    caxis([-0.5 1]);
    colorbar;
    title(sprintf('Event %d Correlation', i));
    xlabel('Neuron');
    ylabel('Neuron');
end
%% data: 81 x 61 x 4 (81 neurons, 61 time points, 4 events)

datap=[];
datap(:,:,1) = data1p(:,21:61);
% datap(:,:,2) = data2p(:,21:end);
datap(:,:,2) = data3p(:,21:61);
datap(:,:,3) = data4p(:,21:61);

   h = axes('Position',axpt(nCol,nRow,1,2,[],wideInterval));
hold on;
colors = lines(4);  % 4개 이벤트에 대한 색상 지정
windowSize = 20;     % smoothing을 위한 윈도우 크기 (필요에 따라 조정)

for ev = [1 3]
    % 각 이벤트 데이터 추출 (뉴런 x 타임포인트)
    eventData = datap(:,:,ev);
    
    % 각 시간 포인트를 하나의 샘플로 보고 PCA 수행 (행: 타임포인트, 열: 뉴런)
    [coeff, score, ~] = pca(eventData');  % score: 61 x numVariables, 첫 3개가 PC1, PC2, PC3
    
    % 첫 3개 주성분에 대해 smoothing 적용
    score_smoothed1 = smoothdata(score(:,1), 'movmean', windowSize);
    score_smoothed2 = smoothdata(score(:,2), 'movmean', windowSize);
    score_smoothed3 = smoothdata(score(:,3), 'movmean', windowSize);
    
    % 3D trajectory 플롯 (plot3: x=PC1, y=PC2, z=PC3)
    plot3(score_smoothed1, score_smoothed2, score_smoothed3, 'Color', colors(ev,:), 'LineWidth', 2);
    % 첫 번째 포인트: 파란색 점
    scatter3(score_smoothed1(1), score_smoothed2(1), score_smoothed3(1), 50, 'b', 'filled');
    % 20번째 포인트: 검은색 점
    scatter3(score_smoothed1(20), score_smoothed2(20), score_smoothed3(20), 50, 'k', 'filled');
    % 마지막 포인트: 빨간색 점
    scatter3(score_smoothed1(end), score_smoothed2(end), score_smoothed3(end), 50, 'r', 'filled');

    
    % 시작점과 종료점 표시
    scatter3(score_smoothed1(1), score_smoothed2(1), score_smoothed3(1), 50, colors(ev,:), 'filled');
    scatter3(score_smoothed1(end), score_smoothed2(end), score_smoothed3(end), 50, colors(ev,:), 'd', 'filled');
end

xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
title('Smoothed 3D Neural Trajectories for 4 Events');
grid on;
view(3);
hold off;

h = axes('Position',axpt(nCol,nRow,2,2,[],wideInterval));
hold on
for ev = [1 2]
    % 각 이벤트 데이터 추출 (뉴런 x 타임포인트)
    eventData = datap(:,:,ev);
    
    % 각 시간 포인트를 하나의 샘플로 보고 PCA 수행 (행: 타임포인트, 열: 뉴런)
    [coeff, score, ~] = pca(eventData');  % score: 61 x numVariables, 첫 3개가 PC1, PC2, PC3
    
    % 첫 3개 주성분에 대해 smoothing 적용
    score_smoothed1 = smoothdata(score(:,1), 'movmean', windowSize);
    score_smoothed2 = smoothdata(score(:,2), 'movmean', windowSize);
    score_smoothed3 = smoothdata(score(:,3), 'movmean', windowSize);
    
    % 3D trajectory 플롯 (plot3: x=PC1, y=PC2, z=PC3)
    plot3(score_smoothed1, score_smoothed2, score_smoothed3, 'Color', colors(ev,:), 'LineWidth', 2);
    % 첫 번째 포인트: 파란색 점
    scatter3(score_smoothed1(1), score_smoothed2(1), score_smoothed3(1), 50, 'b', 'filled');
    % 20번째 포인트: 검은색 점
    scatter3(score_smoothed1(20), score_smoothed2(20), score_smoothed3(20), 50, 'k', 'filled');
    % 마지막 포인트: 빨간색 점
    scatter3(score_smoothed1(end), score_smoothed2(end), score_smoothed3(end), 50, 'r', 'filled');

    
    % 시작점과 종료점 표시
    scatter3(score_smoothed1(1), score_smoothed2(1), score_smoothed3(1), 50, colors(ev,:), 'filled');
    scatter3(score_smoothed1(end), score_smoothed2(end), score_smoothed3(end), 50, colors(ev,:), 'd', 'filled');
end

xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
title('Smoothed 3D Neural Trajectories for 4 Events');
grid on;
view(3);
hold off;

h = axes('Position',axpt(nCol,nRow,3,2,[],wideInterval));
hold on
for ev = [2 3]
    % 각 이벤트 데이터 추출 (뉴런 x 타임포인트)
    eventData = datap(:,:,ev);
    
    % 각 시간 포인트를 하나의 샘플로 보고 PCA 수행 (행: 타임포인트, 열: 뉴런)
    [coeff, score, ~] = pca(eventData');  % score: 61 x numVariables, 첫 3개가 PC1, PC2, PC3
    
    % 첫 3개 주성분에 대해 smoothing 적용
    score_smoothed1 = smoothdata(score(:,1), 'movmean', windowSize);
    score_smoothed2 = smoothdata(score(:,2), 'movmean', windowSize);
    score_smoothed3 = smoothdata(score(:,3), 'movmean', windowSize);
    
    % 3D trajectory 플롯 (plot3: x=PC1, y=PC2, z=PC3)
    plot3(score_smoothed1, score_smoothed2, score_smoothed3, 'Color', colors(ev,:), 'LineWidth', 2);
    % 첫 번째 포인트: 파란색 점
    scatter3(score_smoothed1(1), score_smoothed2(1), score_smoothed3(1), 50, 'b', 'filled');
    % 20번째 포인트: 검은색 점
    scatter3(score_smoothed1(20), score_smoothed2(20), score_smoothed3(20), 50, 'k', 'filled');
    % 마지막 포인트: 빨간색 점
    scatter3(score_smoothed1(end), score_smoothed2(end), score_smoothed3(end), 50, 'r', 'filled');

    
    % 시작점과 종료점 표시
    scatter3(score_smoothed1(1), score_smoothed2(1), score_smoothed3(1), 50, colors(ev,:), 'filled');
    scatter3(score_smoothed1(end), score_smoothed2(end), score_smoothed3(end), 50, colors(ev,:), 'd', 'filled');
end

xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
title('Smoothed 3D Neural Trajectories for 4 Events');
grid on;
view([-69.0583 23.7001]);
hold off;;

pause
% parkinson
close

