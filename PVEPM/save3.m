% 현재 열려 있는 figure의 핸들 가져오기
fig = gcf;

% 저장할 디렉토리 선택
saveDir = uigetdir(pwd, '저장할 디렉토리를 선택하세요');
if saveDir == 0
    disp('저장할 디렉토리가 선택되지 않았습니다.');
    return;
end

% 저장할 파일 이름 지정
filename = 'oaonset_event'; % 원하는 파일 이름으로 수정하세요

% 전체 경로 생성
fullPath = fullfile(saveDir, filename);

% .eps 형식으로 컬러 EPS 저장
saveas(fig, [fullPath, '.eps'], 'epsc');

% .fig 형식으로 저장
saveas(fig, [fullPath, '.fig']);

% .png 형식으로 저장
saveas(fig, [fullPath, '.png']);