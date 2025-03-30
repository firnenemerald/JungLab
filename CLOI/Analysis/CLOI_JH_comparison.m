close all
clear

% Load compiled data
load('D:\CLOI_data\947_2dat.mat');
Totvdat2 = Totvdat;
load('D:\CLOI_data\947_3dat.mat');
Totvdat2 = [Totvdat2 Totvdat];

% Average dist, vel, loc for each mouse
cloi(1,:) = mean(cell2mat(Totvdat2(1:3, 1))); % ChAT_947-2_Baseline_CLOI
cloi(2,:) = mean(cell2mat(Totvdat2(4:6, 1))); % ChAT_947-2_Baseline_Random
cloi(3,:) = mean(cell2mat(Totvdat2(7:9, 1))); % ChAT_947-2_Parkinson_CLOI
cloi(4,:) = mean(cell2mat(Totvdat2(10:12, 1))); % ChAT_947-2_Parkinson_Random

cloi2(1,:) = mean(cell2mat(Totvdat2(1:3, 2))); % ChAT_947-3_Baseline_CLOI
cloi2(2,:) = mean(cell2mat(Totvdat2(4:6, 2))); % ChAT_947-3_Baseline_Random
cloi2(3,:) = mean(cell2mat(Totvdat2(7:9, 2))); % ChAT_947-3_Parkinson_CLOI
cloi2(4,:) = mean(cell2mat(Totvdat2(10:12, 2))); % ChAT_947-3_Parkinson_Random

% OFF vs ON comparison with total distance, mean velocity, locomotion index
iind = [1 3 4 6 7 9 10 12];

figure;
titles = {'Baseline_CLOI', 'Baseline_Random', 'Parkinson_CLOI', 'Parkinson_Random'};
subTitles = {'Total distance', 'Mean velocity', 'Locomotion event'};
for expType = 1:4
    % expType = 1: Baseline_CLOI
    % expType = 2: Baseline_Random
    % expType = 3: Parkinson_CLOI
    % expType = 4: Parkinson_Random
    data = [cell2mat(Totvdat2(iind(2*expType-1):iind(2*expType), 1)); ...
            cell2mat(Totvdat2(iind(2*expType-1):iind(2*expType), 2))];
    
    pairs = [1, 4; 2, 5; 3, 6];
    colors = {[0.8, 0.8, 0.8], [0, 1, 0]};
    
    % Iterate for each comparison
    for i = 1:3
        session_data = data(:, pairs(i,:));
        if i == 1 % Total distance
            session_data = session_data/1000;
        end
        
        % Using only first OFF session
        %means = mean(session_data([1 4 7 10 13 16], :));
        means = mean(session_data);
        %means(1) = mean(session_data([1 4 7 10 13 16],1));
        errors = std(session_data) ./ sqrt(size(session_data,1));
        %errors(1) = std(session_data([1 4 7 10 13 16],1)) ./ sqrt(size(session_data([1 4 7 10 13 16],1),1))
        
        % Create subplot placeholder
        subplot(4, 3, i + 3*(expType-1));
        hold on;
        
        % Bar graph with error bars
        bar_width = 0.6; % 바 너비 조정
        b1 = bar(1, means(1), bar_width, 'FaceColor', colors{1});
        b2 = bar(2, means(2), bar_width, 'FaceColor', colors{2});
        errorbar(1:2, means, errors, 'k', 'linestyle', 'none', 'linewidth', 1.5);
        
        % Scatter plot
        scatter(1 * ones(length(session_data)), session_data(:,1), 30, colors{1}, 'filled','MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
        scatter(2 * ones(length(session_data)), session_data(:,2), 30, colors{2}, 'filled','MarkerEdgeColor', 'k', 'LineWidth', 1, 'jitter', 'on', 'jitterAmount', 0.15);
        
        % Graph settings
        xticks(1:2);
        xticklabels({'OFF', 'ON'});
        ylabel(subTitles{i}, 'Interpreter', 'none');
        title(titles{expType}, 'Interpreter', 'none');
        grid on;
        hold off;
    end
end

%% total distance only comparison
% comparison with the total off session vs total on session
iind = [1 3 4 6 7 9 10 12];
tt = {'baseline-cloi', 'baseline-rand', 'parkinson-cloi', 'parkinson-rand'};
figure;
for expType = 1:4
    %baseline_CLOI
    data = [cell2mat(Totvdat2(iind(2*expType-1):iind(2*expType),1));cell2mat(Totvdat2(iind(2*expType-1):iind(2*expType),2))];
    pairs = [1 4; 2 5; 3 6];
    
    titles = {'Total distance', 'Mean velocity', 'Locomotive event'}; % 각 subplot 제목
    colors = {[0.8, 0.8, 0.8], [0, 1, 0]};
    % Figure 생성
    
    % 현재 비교할 두 열의 데이터 추출
    session_data = data(:, pairs(1,:));
    session_data = session_data/1000;
    
    
    % 평균 및 표준오차 계산
    means = mean(session_data);
    % (using the first off session)
    %means(1) = mean(session_data([1 4 7 10 13 16],1));
    errors = std(session_data) ./ sqrt(size(session_data,1));
    %errors(1) = std(session_data([1 4 7 10 13 16],1)) ./ sqrt(size(session_data([1 4 7 10 13 16],1),1))
    
    % 서브플롯 생성
    subplot(1,4,expType);
    hold on;
    
    % 바 그래프 생성
    bar_width = 0.6; % 바 너비 조정
    b1 = bar(1, means(1), bar_width, 'FaceColor', '#808080');
    b2 = bar(2, means(2), bar_width, 'FaceColor', '#ADEBB3');
    
    % 에러바 추가
    errorbar(1:2, means, errors, 'k', 'linestyle', 'none', 'linewidth', 1.5);
    
    % 개별 데이터 점 추가 (scatter)
    for j = 1:2
        x = j + randn(size(session_data,1),1) * 0.05; % 데이터 겹침 방지 (x좌표 랜덤 오프셋 추가)
        scatter(x, session_data(:,j), 30, cell2mat(colors(j)), 'filled','MarkerEdgeColor', 'k', 'LineWidth', 1.2);
    end
    
    
    
    % 그래프 설정
    xticks(1:2);
    xticklabels({'OFF', 'ON'});
    ylim([0 35]);
    ylabel('Value');
    title(tt{expType});
    grid on;
    hold off;
    
end

%% total distance only comparison
% comparison with the first off session vs first on session
iind = [1 3 4 6 7 9 10 12];
tt = {'baseline-cloi', 'baseline-rand', 'parkinson-cloi', 'parkinson-rand'};
figure;
for expType = 1:4
    %baseline_CLOI
    data = [cell2mat(Totvdat2(iind(2*expType-1):iind(2*expType),1));cell2mat(Totvdat2(iind(2*expType-1):iind(2*expType),2))];
    pairs = [1 4; 2 5; 3 6];
    
    titles = {'Total distance', 'Mean velocity', 'Locomotive event'}; % 각 subplot 제목
    colors = {[0.8, 0.8, 0.8], [0, 1, 0]};
    % Figure 생성
    
    % 현재 비교할 두 열의 데이터 추출
    session_data = data(:, pairs(1,:));
    session_data = session_data([1 4 7 10 13 16],:)/1000;
    
    
    % 평균 및 표준오차 계산
    means = mean(session_data);
    % (using the first off session)
    %means(1) = mean(session_data([1 4 7 10 13 16],1));
    errors = std(session_data) ./ sqrt(size(session_data,1));
    %errors(1) = std(session_data([1 4 7 10 13 16],1)) ./ sqrt(size(session_data([1 4 7 10 13 16],1),1))
    
    % 서브플롯 생성
    subplot(1,4,expType);
    hold on;
    
    % 바 그래프 생성
    bar_width = 0.6; % 바 너비 조정
    b1 = bar(1, means(1), bar_width, 'FaceColor', '#808080');
    b2 = bar(2, means(2), bar_width, 'FaceColor', '#ADEBB3');
    
    % 에러바 추가
    errorbar(1:2, means, errors, 'k', 'linestyle', 'none', 'linewidth', 1.5);
    
    % 개별 데이터 점 및 연결선 추가
    for j = 1:size(session_data,1) % 세션 개수만큼 반복
        y1 = session_data(j,1); % 첫 번째 그룹 값
        y2 = session_data(j,2); % 두 번째 그룹 값
        
        % 같은 세션의 두 값을 연결하는 선 그리기
        plot([1, 2], [y1, y2], 'k-', 'LineWidth', 1.2);
        
        % 개별 데이터 점 (scatter) 추가 (Jitter 제거)
        scatter(1, y1, 50, cell2mat(colors(1)), 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.2);
        scatter(2, y2, 50, cell2mat(colors(2)), 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.2);
    end
    
    % 그래프 설정
    xticks(1:2);
    xticklabels({'OFF', 'ON'});
    ylim([0 35]);
    ylabel('Mean Velocity');
    title(tt{expType});
    grid on;
    hold off;
    
end



%% total distance only comparison
% comparison with the first off session vs 2nd off vs 3rd off
iind = [1 3 4 6 7 9 10 12];
tt = {'baseline-cloi', 'baseline-rand', 'parkinson-cloi', 'parkinson-rand'};
figure;
for expType = 1:4
    %baseline_CLOI
    data = [cell2mat(Totvdat2(iind(2*expType-1):iind(2*expType),1));cell2mat(Totvdat2(iind(2*expType-1):iind(2*expType),2))];
    pairs = [1 4; 2 5; 3 6];
    
    titles = {'Total distance', 'Mean velocity', 'Locomotive event'}; % 각 subplot 제목
    colors = {[0.8, 0.8, 0.8], [0, 1, 0]};
    % Figure 생성
    
    % 현재 비교할 두 열의 데이터 추출
    session_data = data(:, pairs(1,:))/1000;
    session_data2(:,1) = session_data([1 4 7 10 13 16],1);
    session_data2(:,2) = session_data([1 4 7 10 13 16]+1,1);
    session_data2(:,3) = session_data([1 4 7 10 13 16]+2,1);
    
    session_data = session_data2;
    
    
    % 평균 및 표준오차 계산
    means = mean(session_data);
    % (using the first off session)
    %means(1) = mean(session_data([1 4 7 10 13 16],1));
    errors = std(session_data) ./ sqrt(size(session_data,1));
    %errors(1) = std(session_data([1 4 7 10 13 16],1)) ./ sqrt(size(session_data([1 4 7 10 13 16],1),1))
    
    % 서브플롯 생성
    subplot(1,4,expType);
    hold on;
    
    % 바 그래프 생성
    bar_width = 0.6; % 바 너비 조정
    b1 = bar(1, means(1), bar_width, 'FaceColor', '#808080');
    b2 = bar(2, means(2), bar_width, 'FaceColor', '#808080');
    b3 = bar(3, means(3), bar_width, 'FaceColor', '#808080');
    
    % 에러바 추가
    errorbar(1:3, means, errors, 'k', 'linestyle', 'none', 'linewidth', 1.5);
    
    % 개별 데이터 점 및 연결선 추가
    for j = 1:size(session_data,1) % 세션 개수만큼 반복
        y1 = session_data(j,1); % 첫 번째 그룹 값
        y2 = session_data(j,2); % 두 번째 그룹 값
        y3 = session_data(j,3); % 두 번째 그룹 값
        
        % 같은 세션의 두 값을 연결하는 선 그리기
        %         plot([1, 2], [y1, y2], 'k-', 'LineWidth', 1.2);
        
        % 개별 데이터 점 (scatter) 추가 (Jitter 제거)
        scatter(1, y1, 50, cell2mat(colors(1)), 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.2);
        scatter(2, y2, 50, cell2mat(colors(1)), 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.2);
        scatter(3, y3, 50, cell2mat(colors(1)), 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.2);
    end
    
    % 그래프 설정
    xticks(1:3);
    xticklabels({'1st', '2nd', '3rd'});
    ylim([0 35]);
    ylabel('Mean veloccity');
    title(tt{expType});
    grid on;
    hold off;
    
end



%% total distance only comparison
% session by session (off vs on)
iind = [1 3 4 6 7 9 10 12];
tt = {'baseline-cloi', 'baseline-rand', 'parkinson-cloi', 'parkinson-rand'};
figure;
for expType = 1:4
    %baseline_CLOI
    data = [cell2mat(Totvdat2(iind(2*expType-1):iind(2*expType),1));cell2mat(Totvdat2(iind(2*expType-1):iind(2*expType),2))];
    pairs = [1 4; 2 5; 3 6];
    
    titles = {'Total distance', 'Mean velocity', 'Locomotive event'}; % 각 subplot 제목
    colors = {[0.8, 0.8, 0.8], [0, 1, 0]};
    % Figure 생성
    
    % 현재 비교할 두 열의 데이터 추출
    session_data = data(:, pairs(1,:))/1000;
    session_data2(:,1) = session_data([1 4 7 10 13 16],1);
    session_data2(:,2) = session_data([1 4 7 10 13 16]+1,1);
    session_data2(:,3) = session_data([1 4 7 10 13 16]+2,1);
    
    session_data3(:,1) = session_data([1 4 7 10 13 16],2);
    session_data3(:,2) = session_data([1 4 7 10 13 16]+1,2);
    session_data3(:,3) = session_data([1 4 7 10 13 16]+2,2);
    
    session_data = session_data2;
    
    
    % 평균 및 표준오차 계산
    means2 = mean(session_data2);
    means3 = mean(session_data3);
    % (using the first off session)
    %means(1) = mean(session_data([1 4 7 10 13 16],1));
    errors2 = std(session_data2) ./ sqrt(size(session_data2,1));
    errors3 = std(session_data3) ./ sqrt(size(session_data3,1));
    %errors(1) = std(session_data([1 4 7 10 13 16],1)) ./ sqrt(size(session_data([1 4 7 10 13 16],1),1))
    
    % 서브플롯 생성
    subplot(1,4,expType);
    hold on;
    
    b = bar([means2', means3'], 'grouped');
    
    b(1).FaceColor = '#808080';  % Data 1은 파란색
    b(2).FaceColor = '#ADEBB3';
    
    x_positions1 = b(1).XEndPoints;  % data1의 중심 x 위치
    x_positions2 = b(2).XEndPoints;  % data2의 중심 x 위치
    
    errorbar(x_positions1, means2, errors2, 'k', 'LineStyle', 'none', 'CapSize', 10);  % Data 1의 오차막대
    errorbar(x_positions2, means3, errors3, 'k', 'LineStyle', 'none', 'CapSize', 10);  % Data 2의 오차막대
    
    x_positions1_scatter = repmat(x_positions1, 6, 1);  % x_positions1에 대해 6개의 데이터 포인트 반복
    x_positions2_scatter = repmat(x_positions2, 6, 1);  % x_positions2에 대해 6개의 데이터 포인트 반복
    
    scatter(x_positions1_scatter(:), session_data2(:), 50,  cell2mat(colors(1)), 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.2);  % Data 1 개별 데이터 (파란색)
    scatter(x_positions2_scatter(:), session_data3(:), 50,  cell2mat(colors(2)), 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.2);  % Data 2 개별 데이터 (빨간색)
    
    
    % 그래프 설정
    xticks(1:3);
    xticklabels({'1st', '2nd', '3rd'});
    ylim([0 35]);
    ylabel('Mean veloccity');
    title(tt{expType});
    grid on;
    hold off;
    
end
