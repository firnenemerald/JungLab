function eossomTimesMS = CLOI_EOSSOM_MS(stopEventDLC, locoEventDLC, minisessionIdx, rangeDownFrameMS, MvTime, DLCframe)

% Get end of stop frames
endStopFrames = stopEventDLC(:, 2);
% Get start of movement frames
startMoveFrames = locoEventDLC(:, 1);

eossomPairs = []; % Initialize empty array for EOSSOM pairs
eossomFrames = [endStopFrames; startMoveFrames]; % Combine end stop and start move frames
% Sort eossomFrames
eossomFrames = sort(eossomFrames);

% Iterate through eossomFrames to find pairs
for i = 1:length(eossomFrames)-1
    % If the next frame is greater than the current frame and the current frame is in endStopFrames and next frame is in startMoveFrames
    if eossomFrames(i+1) > eossomFrames(i) && ...
       any(eossomFrames(i) == endStopFrames) && ...
       any(eossomFrames(i+1) == startMoveFrames)
        % Add this pair to eossomPairs
        eossomPairs = [eossomPairs; eossomFrames(i), eossomFrames(i+1)];
    end
end

% Get eossomPairs for the specific minisession
eossomPairsMS = eossomPairs(eossomPairs(:, 1) >= rangeDownFrameMS{minisessionIdx}(1) & ...
                            eossomPairs(:, 1) <= rangeDownFrameMS{minisessionIdx}(2), :);

% Calculate EOSSOM times
eossomTimesMS = CLOI_Frame2Time(eossomPairsMS(:, 1), eossomPairsMS(:, 2), MvTime, DLCframe);

end