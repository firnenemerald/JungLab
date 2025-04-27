function plotCorrVsDistance(distance, correlation)
    % 거리 데이터 범위 설정 (0~1000, bin size = 25)
    binEdges = 0:5:500;
    binCenters = binEdges(1:end-1) + 12.5; % 각 bin의 중심값

    % 각 bin에 대한 평균 및 표준편차 계산
    meanCorr = zeros(1, length(binCenters));
    stdCorr = zeros(1, length(binCenters));
    
    for i = 1:length(binEdges)-1
        binIdx = (distance >= binEdges(i)) & (distance < binEdges(i+1));
        if sum(binIdx) > 0
            meanCorr(i) = mean(correlation(binIdx));
            stdCorr(i) = std(correlation(binIdx));
        else
            meanCorr(i) = NaN;
            stdCorr(i) = NaN;
        end
    end

    % 그래프 그리기
    figure;
    hold on;
    
    % 원래 데이터 scatter plot (개별 데이터 점)
    scatter(distance, correlation, 20, 'k', 'filled', 'MarkerFaceAlpha', 0.5);
    
    % Shading을 위한 상하 경계 계산
    upperBound = meanCorr + stdCorr;
    lowerBound = meanCorr - stdCorr;

    % NaN 제거 (fill 사용 시 필요)
    validIdx = ~isnan(meanCorr);
    binCentersValid = binCenters(validIdx);
    upperBoundValid = upperBound(validIdx);
    lowerBoundValid = lowerBound(validIdx);
    meanCorrValid = meanCorr(validIdx);

    % Shading (표준편차 영역)
    fill([binCentersValid fliplr(binCentersValid)], ...
         [upperBoundValid fliplr(lowerBoundValid)], ...
         'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % 평균 선 플롯
    plot(binCentersValid, meanCorrValid, 'r', 'LineWidth', 2);

    % 그래프 스타일 조정
    xlabel('Distance');
    ylabel('Correlation Coefficient');
    title('Correlation vs Distance (with Shading)');
    xlim([0 500]);
    ylim([-0.4 0.8]); % correlation coefficient 범위 고려
    grid on;
    
    hold off;
end
