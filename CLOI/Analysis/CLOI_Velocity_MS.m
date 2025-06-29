function [velValMS, velocityPeakList] = CLOI_Velocity_MS(bodyVelDLC, boolDownFrameMS, minisessionIdx)

velIdxMS = find(boolDownFrameMS{minisessionIdx}(2:end));
velValMS = bodyVelDLC(boolDownFrameMS{minisessionIdx}(2:end));

% Find peaks in velocity data
[peaks, locs] = findpeaks(velValMS, 'MinPeakHeight', 0.1, 'MinPeakDistance', 10);
% Filter peaks based on peak value > 10
newpeaks = peaks(peaks > 10);
newlocs = locs(peaks > 10);
% Collect peak velocities
velocityPeakList = zeros(length(newpeaks), 1);
for i = 1:length(newpeaks)
    velocityPeakList(i) = newpeaks(i);
end

end