function [cellBaseSignal, cellParkSignal, cellBaseIdx, cellParkIdx] = getNeuralSignal(mouse, synced_Chat_baseline, synced_Chat_parkinson)
    switch mouse
        case 1
            baseSession = "ChAT_514_2_3_24_02_05_16_42_21_OF";
            parkSession = "ChAT_514_2_3_24_04_04_14_56_55_OF";
        case 2
            baseSession = "ChAT_514_2_4_24_01_29_16_04_16_OF";
            parkSession = "ChAT_514_2_4_24_02_20_13_31_20_OF";
        case 3
            baseSession = "ChAT_515_1_24_02_06_13_37_15_OF";
            parkSession = "ChAT_515_1_24_04_08_15_45_00_OF";
        case 4
            baseSession = "ChAT_853_3_24_04_15_15_24_32_OF";
            parkSession = "ChAT_853_3_24_05_02_13_58_10_OF";
        case 5
            baseSession = "ChAT_925_2_24_07_18_13_56_02_OF";
            parkSession = "ChAT_925_2_24_09_10_11_39_48_OF";
        case 6
            baseSession = "ChAT_925_3_24_08_08_12_03_46_OF";
            parkSession = "ChAT_925_3_24_09_19_14_10_41_OF";
        case 7
            baseSession = "ChAT_853_1_24_04_18_15_24_09_OF";
            parkSession = "";
    end
    cellBaseSignal_table = synced_Chat_baseline.(baseSession).signal;
    cellParkSignal_table = synced_Chat_parkinson.(parkSession).signal;
    cellBaseIdx = cellBaseSignal_table(1,:);
    cellParkIdx = cellParkSignal_table(1,:);
    cellBaseSignal = cell2mat(cellBaseSignal_table(2:end,:));
    cellParkSignal = cell2mat(cellParkSignal_table(2:end,:));
end