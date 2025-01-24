%% GetSyncTime.m (ver 1.0.240923)
% Helper function to get experiment session's synctime

% Copyright (C) 2024 Chanhee Jeong

% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.

% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.

function syncTime = GetSyncTime(gpioArray, pulseIndex)
    arguments
        gpioArray (:, 2) double
        pulseIndex = 1
    end

    gpioTime = gpioArray(:, 1);
    gpioSignal = gpioArray(:, 2);
    gpioMax = max(gpioSignal);

    pulseNum = length(find(diff(gpioSignal) > 0.5 * gpioMax));
    if pulseIndex > pulseNum
        ME = MException('MATLAB:outofbounds', 'pulseIndex %d is larger than total pulse number %d', pulseIndex, pulseNum);
        throw(ME)
    end

    syncTime = gpioTime(pulseNum(pulseIndex));

end