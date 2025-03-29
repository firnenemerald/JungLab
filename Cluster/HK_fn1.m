function [correlationMatrix]=HK_fn1(data, PROPs)
% 데이터의 개수
numData = size(data, 2);
% 모든 2개 조합을 구함 (nchoosek 사용)
combinations = nchoosek(1:numData, 2);

% 결과를 저장할 변수
correlationMatrix = NaN(numData, 2);

% 모든 조합에 대해 상관계수 계산
for idx = 1:size(combinations, 1)
    i = combinations(idx, 1);
    j = combinations(idx, 2);
    
    % 각 쌍의 데이터에 대해 corrcoef 계산
    R = corrcoef(data(i, :), data(j, :));
    PROPsd = cell2mat(PROPs);
    dist = sqrt((PROPsd(i, 1) - PROPsd(j, 1))^2 + (PROPsd(i, 2) - PROPsd(j, 2))^2);

    correlationMatrix(idx, 1) = R(1, 2); % 상관계수는 R(1,2) 위치에 저장
    correlationMatrix(idx,2) = dist;

    % Distance

end
end

%%
% function [correlationMatrix] = fn1(data, PROPs)
%     % 데이터의 개수
%     numData = size(data, 2);
%     % 모든 2개 조합을 구함 (nchoosek 사용)
%     combinations = nchoosek(1:numData, 2);
% 
%     % 결과를 저장할 변수
%     correlationMatrix = NaN(size(combinations, 1), 2);  % 조합의 수에 맞게 크기 조정
% 
%     % 모든 조합에 대해 상관계수 계산
%     for idx = 1:size(combinations, 1)
%         i = combinations(idx, 1);
%         j = combinations(idx, 2);
% 
%         % 각 쌍의 데이터에 대해 corrcoef 계산
%         R = corrcoef(data(i, :), data(j, :));  % data가 2D 배열이라 가정
%         PROPsd = cell2mat(PROPs);  % cell 배열을 matrix로 변환
% 
%         % 각 데이터 포인트 간 거리 계산
%         dist = sqrt((PROPsd(i, 1) - PROPsd(j, 1))^2 + (PROPsd(i, 2) - PROPsd(j, 2))^2);
% 
%         correlationMatrix(idx, 1) = R(1, 2);  % 상관계수는 R(1,2) 위치에 저장
%         correlationMatrix(idx, 2) = dist;    % 거리 저장
%     end
% end
