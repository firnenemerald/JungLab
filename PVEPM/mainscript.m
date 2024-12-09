%% fileread
clear all
EXPname = 'EPM';
filepathfinder;

filereader_doric;
filereader_video;

%% preprocessing
sync_dlc;
clear all

smooth_dlc;
clear all

fixerror_doric;
clear all

%% Analysis
da_arearange;
clear all

da_normhmap;
clear all

%% plot
plot_normhmap;
clear all

plot_onset;
clear all


