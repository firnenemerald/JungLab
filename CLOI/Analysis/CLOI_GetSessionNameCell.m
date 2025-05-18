%% Function to get specific session names for specified mice

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

% State = "All" for all states, "Baseline" for baseline, "Parkinson" for parkinsonian state
% ExpType = "Both" for both experiments, "CLOI" for CLOI experiment, "Random" for random experiment
function sessionNameCell = CLOI_GetSessionNameCell(defaultDir, sessionNameStruct, mouseState, expType)
    
    % Preallocate sessionNameCell
    sessionNameCell = {};

    % Iterate through each mouse name
    for mouseidx = 1:length(sessionNameStruct)
        snBaseCLOI = sessionNameStruct(mouseidx).sessionNameBaseCLOI';
        snBaseRAND = sessionNameStruct(mouseidx).sessionNameBaseRAND';
        snParkCLOI = sessionNameStruct(mouseidx).sessionNameParkCLOI';
        snParkRAND = sessionNameStruct(mouseidx).sessionNameParkRAND';
        
        % Check the state and experiment type to filter session names
        if strcmp(mouseState, "All")
            if strcmp(expType, "Both")
                sessionNameCell = [sessionNameCell, snBaseCLOI, snBaseRAND, snParkCLOI, snParkRAND];
            elseif strcmp(expType, "CLOI")
                sessionNameCell = [sessionNameCell, snBaseCLOI, snParkCLOI];
            elseif strcmp(expType, "Random")
                sessionNameCell = [sessionNameCell, snBaseRAND, snParkRAND];
            end
        elseif strcmp(mouseState, "Baseline")
            if strcmp(expType, "Both")
                sessionNameCell = [sessionNameCell, snBaseCLOI, snBaseRAND];
            elseif strcmp(expType, "CLOI")
                sessionNameCell = [sessionNameCell, snBaseCLOI];
            elseif strcmp(expType, "Random")
                sessionNameCell = [sessionNameCell, snBaseRAND];
            end
        elseif strcmp(mouseState, "Parkinson")
            if strcmp(expType, "Both")
                sessionNameCell = [sessionNameCell, snParkCLOI, snParkRAND];
            elseif strcmp(expType, "CLOI")
                sessionNameCell = [sessionNameCell, snParkCLOI];
            elseif strcmp(expType, "Random")
                sessionNameCell = [sessionNameCell, snParkRAND];
            end
        else
            error('Invalid mouse state or experiment type specified. Please check the input parameters.');
        end
    end
end