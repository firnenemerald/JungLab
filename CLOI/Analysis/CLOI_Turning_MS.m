function [turnIpsiTimesMS, turnContraTimesMS] = CLOI_Turning_MS(turnIpsiEventDLC, turnContraEventDLC, minisessionIdx, rangeDownFrameMS, MvTime, DLCframe)

turnIpsiMS = [];
% Get ipsilateral turning event frame pairs
for i = 1:size(turnIpsiEventDLC, 1)
    if turnIpsiEventDLC(i, 1) >= rangeDownFrameMS{minisessionIdx}(1) && turnIpsiEventDLC(i, 2) <= rangeDownFrameMS{minisessionIdx}(2)
        turnIpsiMS = [turnIpsiMS; turnIpsiEventDLC(i, :)];
    end
end

if isempty(turnIpsiMS)
    turnIpsiTimesMS = 0; % If no ipsilateral events, return 0
else
    turnIpsiTimesMS = CLOI_Frame2Time(turnIpsiMS(:, 1), turnIpsiMS(:, 2), MvTime, DLCframe);
end

turnContraMS = [];
% Get contralateral turning event frame pairs
for i = 1:size(turnContraEventDLC, 1)
    if turnContraEventDLC(i, 1) >= rangeDownFrameMS{minisessionIdx}(1) && turnContraEventDLC(i, 2) <= rangeDownFrameMS{minisessionIdx}(2)
        turnContraMS = [turnContraMS; turnContraEventDLC(i, :)];
    end
end
if isempty(turnContraMS)
    turnContraTimesMS = 0; % If no contralateral events, return 0
else
    turnContraTimesMS = CLOI_Frame2Time(turnContraMS(:, 1), turnContraMS(:, 2), MvTime, DLCframe);
end
end