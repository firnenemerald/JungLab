function plotCorrVsDistanceLinearFit(distance, correlation)
    % 거리 데이터 범위 설정 (0~1000, bin size = 25)
    binEdges = 0:25:1000;
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

    % NaN 제거
    validIdx = ~isnan(meanCorr);
    binCentersValid = binCenters(validIdx);
    meanCorrValid = meanCorr(validIdx);
    stdCorrValid = stdCorr(validIdx);

    % Linear Fit (y = mx + b) using polyfit
    coeffs = polyfit(binCentersValid, meanCorrValid, 1); % 1차 다항식 (선형)
    m = coeffs(1); % 기울기
    b = coeffs(2); % y절편

    % 부드러운 곡선 생성
    smoothX = linspace(0, 1000, 200);
    smoothY = m * smoothX + b; % y = mx + b

    % 상관 계수 (R) 및 p-value 계산
%     [R, P] = corrcoef(binCentersValid, meanCorrValid); 
    [R, P] = corrcoef(distance, correlation); 
    R_value = R(1,2); % Pearson correlation coefficient
    P_value = P(1,2); % p-value

    % Shading 영역 계산 (표준편차 적용)
    smoothUpper = smoothY + interp1(binCentersValid, stdCorrValid, smoothX, 'linear', 'extrap');
    smoothLower = smoothY - interp1(binCentersValid, stdCorrValid, smoothX, 'linear', 'extrap');

    % 그래프 그리기
    hold on;

    % 원래 데이터 scatter plot (개별 데이터 점)
    scatter(distance, correlation, 20, 'k', 'filled', 'MarkerFaceAlpha', 0.3);

%     % Shading (표준편차 영역)
%     fill([smoothX fliplr(smoothX)], [smoothUpper fliplr(smoothLower)], ...
%          'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % Linear Fit 곡선 플롯
    plot(smoothX, smoothY, 'b', 'LineWidth', 2);

    % R값과 p-value를 그래프에 표시
    text(50, 0.8, sprintf('R = %.3f\np = %.3g', R_value, P_value), ...
         'FontSize', 8, 'FontWeight', 'bold', 'Color', 'k');

    % 그래프 스타일 조정
    xlabel('Distance');
    ylabel('Correlation Coefficient');
    title('Linear Fit: Correlation vs Distance');
    xlim([0 1000]);
    ylim([-0.6 0.8]); % correlation coefficient 범위 고려
    grid on;

    hold off;
end
