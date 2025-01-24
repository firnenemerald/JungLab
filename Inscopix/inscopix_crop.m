baseDir = 'C:\\Users\\chanh\\Downloads\\Inscopix_crop';
expName = 'ChAT_853-1';
expDir = strcat(baseDir, '\\', expName);

% Check if it is already cropped
fileCropped = fullfile(expDir, strcat(expName, '_cropped*'));
croppedNum = length(dir(fileCropped));
if croppedNum > 0
    msg = 'The session is already cropped!';
    error(msg);
end

% Check number of files to crop and crop
filePattern = fullfile(expDir, strcat(expName, '_*.jpg'));
fileNum = length(dir(filePattern)) - 1;

for idx = 1:fileNum
    fileDir = strcat(expDir, '\\', expName, '_', num2str(idx), '.jpg');
    saveDir = strcat(expDir, '\\', expName, '_cropped_', num2str(idx), '.jpg');
    Im = imread(fileDir);
    Im2 = Im(170:935, 330:1560, :);
    imshow(Im2);
    imwrite(Im2, saveDir);
end

close all