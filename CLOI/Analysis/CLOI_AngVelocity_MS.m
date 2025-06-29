function [angVelValMS, angVelPeakList] = CLOI_AngVelocity_MS(angularVelDLC, boolDownFrameMS, minisessionIdx)

angVelIdxMS = find(boolDownFrameMS{minisessionIdx}(2:end));
angVelValMS = abs(angularVelDLC(boolDownFrameMS{minisessionIdx}(2:end)));

% Find peaks in velocity data
[peaks, locs] = findpeaks(angVelValMS, 'MinPeakHeight', 0.1, 'MinPeakDistance', 5);
% Collect peak velocities
angVelPeakList = zeros(length(peaks), 1);
for i = 1:length(peaks)
    angVelPeakList(i) = peaks(i);
end

end