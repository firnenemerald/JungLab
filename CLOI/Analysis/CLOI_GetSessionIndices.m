%% Find the indices of sessions in the sessionData struct based on the sessionNameRegex

% SPDX-FileCopyrightText: © 2025 Chanhee Jeong <chanheejeong@snu.ac.kr>
% SPDX-License-Identifier: GPL-3.0-or-later

function sessionIndices = CLOI_GetSessionIndices(sessionData, sessionNameRegex)

switch sessionNameRegex
    case 'basepark_cloirand'
        mouseIDs = {'947-2', '947-3', '946-2', '967-2'}; mousePattern = strjoin(mouseIDs, '|');
        conditions = {'Baseline', 'Parkinson'}; conditionPattern = strjoin(conditions, '|');
        % conditions = {'Parkinson'}; conditionPattern = strjoin(conditions, '|');
        protocols = {'CLOI', 'Random'}; protocolPattern = strjoin(protocols, '|');
        % protocols = {'Random'}; protocolPattern = strjoin(protocols, '|');
        sessionNameRegex = sprintf('^ChAT_(%s)_(%s)_(%s)_.*$', mousePattern, conditionPattern, protocolPattern);
    case 'preset2'
        mouseIDs = {'967-3', '971-3', '971-4'}; mousePattern = strjoin(mouseIDs, '|');
        conditions = {'Baseline'}; conditionPattern = strjoin(conditions, '|');
        protocols = {'CLOI', 'Random', 'CONT'}; protocolPattern = strjoin(protocols, '|');
        sessionNameRegex = sprintf('^ChAT_(%s)_(%s)_(%s)_.*$', mousePattern, conditionPattern, protocolPattern);
    case 'preset3'
        mouseIDs = {'946-2', '967-1', '967-3', '971-3', '971-4'}; mousePattern = strjoin(mouseIDs, '|');
        conditions = {'Baseline'}; conditionPattern = strjoin(conditions, '|');
        protocols = {'FREQ'}; protocolPattern = strjoin(protocols, '|');
        sessionNameRegex = sprintf('^ChAT_(%s)_(%s)_(%s)_.*$', mousePattern, conditionPattern, protocolPattern);
    case 'preset4'
        mouseIDs = {'946-2'}; mousePattern = strjoin(mouseIDs, '|');
        conditions = {'Baseline'}; conditionPattern = strjoin(conditions, '|');
        protocols = {'FREQ'}; protocolPattern = strjoin(protocols, '|');
        sessionNameRegex = sprintf('^ChAT_(%s)_(%s)_(%s)_.*$', mousePattern, conditionPattern, protocolPattern);
    case 'base_cloi'
        mouseIDs = {'947-2', '947-3', '946-2', '967-2'}; mousePattern = strjoin(mouseIDs, '|');
        conditions = {'Baseline'}; conditionPattern = strjoin(conditions, '|');
        protocols = {'CLOI'}; protocolPattern = strjoin(protocols, '|');
        sessionNameRegex = sprintf('^ChAT_(%s)_(%s)_(%s)_.*$', mousePattern, conditionPattern, protocolPattern);
    case 'base_rand'
        mouseIDs = {'947-2', '947-3', '946-2', '967-2'}; mousePattern = strjoin(mouseIDs, '|');
        conditions = {'Baseline'}; conditionPattern = strjoin(conditions, '|');
        protocols = {'Random'}; protocolPattern = strjoin(protocols, '|');
        sessionNameRegex = sprintf('^ChAT_(%s)_(%s)_(%s)_.*$', mousePattern, conditionPattern, protocolPattern);
    case 'park_cloi'
        mouseIDs = {'947-2', '947-3', '946-2', '967-2'}; mousePattern = strjoin(mouseIDs, '|');
        conditions = {'Parkinson'}; conditionPattern = strjoin(conditions, '|');
        protocols = {'CLOI'}; protocolPattern = strjoin(protocols, '|');
        sessionNameRegex = sprintf('^ChAT_(%s)_(%s)_(%s)_.*$', mousePattern, conditionPattern, protocolPattern);
    case 'park_rand'
        mouseIDs = {'947-2', '947-3', '946-2', '967-2'}; mousePattern = strjoin(mouseIDs, '|');
        conditions = {'Parkinson'}; conditionPattern = strjoin(conditions, '|');
        protocols = {'Random'}; protocolPattern = strjoin(protocols, '|');
        sessionNameRegex = sprintf('^ChAT_(%s)_(%s)_(%s)_.*$', mousePattern, conditionPattern, protocolPattern);

end

% Find session indices that match the regex pattern
sessionIndices = find(cellfun(@(x) ~isempty(regexp(x, sessionNameRegex, 'once')), {sessionData.sessionName}));

end