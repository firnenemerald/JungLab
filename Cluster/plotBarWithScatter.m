function plotBarWithScatter(group1, group2, group3, group4)

colorBlue = [0 0 0.8];
    colorBlue = [0,0.600000000000000,0.890196078431373];
    colorRed = [0.8 0 0 ];
    colorRed = [0.929411764705882,0.196078431372549,0.203921568627451];
    colorlBlue = [0.874509803921569,0.937254901960784,0.988235294117647];
    colorlRed = [0.949019607843137,0.541176470588235,0.509803921568627];
    colors = {colorlBlue colorlRed};
    
data = {group1, group2, group3, group4}; % 데이터 그룹화
    numGroups = length(data);
    
    % 평균 및 표준오차(SEM) 계산
    means = cellfun(@mean, data);
    sems = cellfun(@(x) std(x)/sqrt(length(x)), data);

    % 바 그래프 그리기
    figure;
    hold on;
    barColors = [0 0 1; 1 0 0; 0 1 0; 1 0.5 0]; % 파랑, 빨강, 초록, 주황
    
    for i = 1:numGroups
        bar(i, means(i), 'FaceColor', barColors(i, :), 'EdgeColor', 'k', 'LineWidth', 1.5);
    end
    
    % 오류 막대 추가
    errorbar(1:numGroups, means, sems, 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
    
    % 개별 데이터 점 그리기 (jitter 추가)
    jitterAmount = 0.15; % 데이터가 너무 겹치지 않도록 살짝 퍼트림
    for i = 1:numGroups
        xJitter = i + (rand(size(data{i})) - 0.5) * jitterAmount;
        scatter(xJitter, data{i}, 50, 'k', 'filled', 'MarkerFaceAlpha', 0.7);
    end
    
    % 그래프 스타일 조정
    xlim([0.5 numGroups + 0.5]);
    xticks(1:numGroups);
    xticklabels({'Group 1', 'Group 2', 'Group 3', 'Group 4'});
    ylabel('Value');
    title('Bar Graph with Individual Data Points');
    
    hold off;
end