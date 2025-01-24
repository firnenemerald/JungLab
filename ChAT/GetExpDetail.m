%% GetExpDetail.m (ver 1.0.240918)
% Helper function to get experiment session's details
% Input is experiment session's name
% Output is mouse name (name) OR session timestamp (time) OR experiment type (type)

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

function [result] = GetExpDetail(expName, part)

expNameSplit = split(expName, '_');
switch part
    case 'name'
        result = string(expNameSplit(1)) + '_' + string(expNameSplit(2));
    case 'time'
        result = string(expNameSplit(3));
    case 'type'
        result = string(expNameSplit(4));
    otherwise
        msg = 'second argument is limited to name, time, or type';
        error(msg);
end