clear 
close all
load('C:\Users\neosj\Dropbox\Studies\Jung_lab\CIN study\Codingv2-20250316T050213Z-001\Codingv2\Corrdat.mat')
load('C:\Users\neosj\Dropbox\MATLAB\ODPCC\color_setting\color_set.mat');
tt = cell2mat(Tot_act(:,1));
Mtot_act = mean(tt);

ttp = cell2mat(Tot_actp(:,1));
for k=1:7
    ttt = ttp(:,k);
    Mtot_actp(k) = mean(ttt(ttt>-100));
end

% mouse별 index
Numind = [];baselineind = [];
for kk=1:7
    Numind(kk) = size(Tot_act{kk},1);
    baselineind = [baselineind; ones(Numind(kk),1)*kk];
    act_baseline(kk,:) = mean(Tot_act{kk});
end

Numind = [];parkinsonind = [];
for kk=1:6
    Numind(kk) = size(Tot_actp{kk},1)
    parkinsonind = [parkinsonind; ones(Numind(kk),1)*kk];
    act_parkinson(kk,:) = mean(Tot_actp{kk});
end

for k=1:size(act_parkinson,2)
    ttt = act_parkinson(:,k);
    m_act_parkinson(k) = mean(ttt(ttt>-100));
end
   
% Forward, Contraturn, Ipsiturn, Stop 에 대한 overall activity 비교
% mouse별 비교
%comparison에서는 853-1은 제외
act_baseline(4,:)=[]; 
% CLOI comparison 이용해서 그리기
data = [mean(act_baseline) ; m_act_parkinson];
bar(data')
close
% neuron 별 비교
data2 = [Mtot_act;Mtot_actp];
bar(data2')

for k=1:5
    ttt = act_parkinson(:,k);
    m_act_parkinson(k) = mean(ttt(ttt>-100));
end

%% correlation coefficient 비교
for k=1:8
    for kk=[1 2 3 5 6 7]
ttr = cell2mat(Tot_corr(kk,k));
Mtot_corr(k,kk) = mean(ttr(:,1)); % total correlation
ttr=[];
    end
end
Mtot_corr(:,4)=[];

m_Mtot_corr = mean(Mtot_corr,2);

for k=1:8
    for kk=1:6
ttpr = cell2mat(Tot_corrp(kk,k));
if length(ttpr(:,1))>1
Mtot_corrp(k,kk) = mean(ttpr(:,1));
else
 Mtot_corrp(k,kk) = (ttpr(:,1));   
ttr=[];
    end
    end
end

for i=1:8
   ttt = Mtot_corrp(i,:);
    m_Mtot_corrp(i) = mean(ttt(ttt>-50));
end

close

nRow = 3;
nCol = 4;
fHandle = figure('PaperUnits','centimeters','PaperPosition',[0 0 17.4*2 17.4*(6/5)],'Renderer','Painters');
h = axes('Position',axpt(nCol,nRow,1,1,[],wideInterval));

% Total correlation
D1 = [0.00958867792035496,0.0168725720867045,0.00839322085172315,0.0528728376241850];
A2a = [0.0143887360068749,0.0176073925057984,0.00320770107660880,0.00391816734415867,0.00382943028200146];
BaseChol = [Mtot_corr(1,:)];
ParkChol = [Mtot_corrp(1,:)];



% means = [mean(D1), mean(A2a), ...
%          mean(BaseChol), mean(ParkChol)];
% sems  = [std(D1)/sqrt(length(D1)), ...
%          std(A2a)/sqrt(length(A2a)), ...
%          std(BaseChol)/sqrt(length(BaseChol)), ...
%          std(ParkChol)/sqrt(length(ParkChol))];
     
     means = [mean(D1), mean(A2a), ...
         mean(BaseChol)];
sems  = [std(D1)/sqrt(length(D1)), ...
         std(A2a)/sqrt(length(A2a)), ...
         std(BaseChol)/sqrt(length(BaseChol))];

x = [1, 2, 3];

colors = {colorGreen colorPurple colorBlue colorRed}; 

hold on;

b = bar(x, means, 0.4, 'FaceColor', 'flat');
b.CData(1,:) = colors{1};
b.CData(2,:) = colors{2};
b.CData(3,:) = colors{3};
% b.CData(4,:) = colors{4};

errorbar(x, means, sems, 'k', 'LineStyle', 'none', 'LineWidth', 1.2)

jitter = 0; % 점이 겹치지 않도록 이동
for i = 1:length(D1)
    x1_jittered = 1 + (rand(length(D1),1) - 0.5) * jitter;
    % 개별 데이터 점 그리기
    scatter(x1_jittered(i), D1(i), 30, colorGreen, 'filled', 'MarkerEdgeColor', 'k'); % 파란색 (Group 1)
end

jitter = 0; % 점이 겹치지 않도록 이동
for i = 1:length(A2a)
    x1_jittered = 2 + (rand(length(A2a),1) - 0.5) * jitter;
    % 개별 데이터 점 그리기
    scatter(x1_jittered(i), A2a(i), 30, colorPurple, 'filled', 'MarkerEdgeColor', 'k'); % 파란색 (Group 1)
end

jitter = 0; % 점이 겹치지 않도록 이동
for i = 1:length(BaseChol)
    x1_jittered = 3 + (rand(length(BaseChol),1) - 0.5) * jitter;
    % 개별 데이터 점 그리기
    scatter(x1_jittered(i), BaseChol(i), 30, colorlBlue, 'filled', 'MarkerEdgeColor', 'k'); % 파란색 (Group 1)
end

% jitter = 0; % 점이 겹치지 않도록 이동
% for i = 1:length(ParkChol)
%     x1_jittered = 4 + (rand(length(ParkChol),1) - 0.5) * jitter;
%     % 개별 데이터 점 그리기
%     scatter(x1_jittered(i), ParkChol(i), 30, colorlRed, 'filled', 'MarkerEdgeColor', 'k'); % 파란색 (Group 1)
% end
set(gca, 'XLim', [0.5 3.5], 'XTick',[1:3],'XTickLabel',{'D1','A2a','ChaT'})

h = axes('Position',axpt(nCol,nRow,2,1,[],wideInterval));
% bar_paired_m(Mtot_corr([2 3 4 6 7 8],:)', Mtot_corrp([2 3 4 6 7 8],:)')

% corrdat = [m_Mtot_corr';m_Mtot_corrp];
% bar(corrdat')
Tot_corr(4,:)=[];

t1 = cell2mat(Tot_corr(:,1));
t2 = cell2mat(Tot_corr(:,2));
t3 = cell2mat(Tot_corr(:,3));
t4 = cell2mat(Tot_corr(:,4));
t5 = cell2mat(Tot_corr(:,5));
t6 = cell2mat(Tot_corr(:,6));
t7 = cell2mat(Tot_corr(:,7));
t8 = cell2mat(Tot_corr(:,8));

t1p = cell2mat(Tot_corrp(:,1));
t2p = cell2mat(Tot_corrp(:,2));
t3p = cell2mat(Tot_corrp(:,3));
t4p = cell2mat(Tot_corrp(:,4));
t5p = cell2mat(Tot_corrp(:,5));
t6p = cell2mat(Tot_corrp(:,6));
t7p = cell2mat(Tot_corrp(:,7));
t8p = cell2mat(Tot_corrp(:,8));

bar_violin(t1(:,1), t1p(:,1))
[h p1] = ttest2(t1(:,1), t1p(:,1));

h = axes('Position',axpt(nCol,nRow,3:4,1,[],wideInterval));
tb = [t3(:,1) t4(:,1) t5(:,1) t6(:,1)]; % forward, ipsiturn, stop

tbp = [t3p(:,1) t4p(:,1) t6p(:,1)];
bar_violin(tb, tbp)

[h p2] = ttest2(t2(:,1), t2p(:,1));
[h p3] = ttest2(t3(:,1), t3p(:,1));
[h p4] = ttest2(t4(:,1), t4p(:,1));
[h p6] = ttest2(t6(:,1), t6p(:,1));
%Tot, mobile, forward, ipsi, contra, stop

h = axes('Position',axpt(nCol,nRow,1,2,[],wideInterval));
plotCorrVsDistanceSmooth(t1(:,2),t1(:,1))

h = axes('Position',axpt(nCol,nRow,2,2,[],wideInterval));
plotCorrVsDistanceSmooth(t3(:,2),t3(:,1))

h = axes('Position',axpt(nCol,nRow,3,2,[],wideInterval));
plotCorrVsDistanceSmooth(t4(:,2),t4(:,1))

h = axes('Position',axpt(nCol,nRow,4,2,[],wideInterval));
plotCorrVsDistanceSmooth(t6(:,2),t6(:,1))

h = axes('Position',axpt(nCol,nRow,1,3,[],wideInterval));
plotCorrVsDistanceSmooth(t1p(:,2),t1p(:,1))

h = axes('Position',axpt(nCol,nRow,2,3,[],wideInterval));
plotCorrVsDistanceSmooth(t3p(:,2),t3p(:,1))

h = axes('Position',axpt(nCol,nRow,3,3,[],wideInterval));
plotCorrVsDistanceSmooth(t4p(:,2),t4p(:,1))

h = axes('Position',axpt(nCol,nRow,4,3,[],wideInterval));
plotCorrVsDistanceSmooth(t6p(:,2),t6p(:,1))

pause
% close
%%

ttp = cell2mat(Tot_actp(:,1));
for k=1:7
    ttt = ttp(:,k);
    Mtot_actp(k) = mean(ttt(ttt>-100));
end

% mouse별 index
Numind = [];baselineind = [];
for kk=1:7
    Numind(kk) = size(Tot_act{kk},1);
    baselineind = [baselineind; ones(Numind(kk),1)*kk];
    act_baseline(kk,:) = mean(Tot_act{kk});
end

Numind = [];parkinsonind = [];
for kk=1:6
    Numind(kk) = size(Tot_actp{kk},1)
    parkinsonind = [parkinsonind; ones(Numind(kk),1)*kk];
    act_parkinson(kk,:) = mean(Tot_actp{kk});
end

for k=1:size(act_parkinson,2)
    ttt = act_parkinson(:,k);
    m_act_parkinson(k) = mean(ttt(ttt>-100));
end


% Forward, Contraturn, Ipsiturn, Stop 에 대한 overall activity 비교
% mouse별 비교
%comparison에서는 853-1은 제외
act_baseline(4,:)=[]; 
% CLOI comparison 이용해서 그리기
data = [mean(act_baseline) ; m_act_parkinson];
bar(data')

% neuron 별 비교
data2 = [Mtot_act;Mtot_actp];
bar(data2')

