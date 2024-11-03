sourceFolder = uigetdir([], 'Select the folder containing ZIP files');

destinationFolder = uigetdir([], 'Select the destination folder to extract ZIP files');

zipFiles = dir(fullfile(sourceFolder, '*.zip'));

for i = 1:length(zipFiles)
    zipFilePath = fullfile(sourceFolder, zipFiles(i).name);
    
    unzip(zipFilePath, destinationFolder);
    
    fprintf('Unzipped: %s\n', zipFiles(i).name);
end