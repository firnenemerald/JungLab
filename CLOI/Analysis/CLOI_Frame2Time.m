function time = CLOI_Frame2Time(frameArray1, frameArray2, MvTime, DLCframe)
    % Convert frameArray indices to time
    % frameArray1: [N × 1] array of frame indices for the first set
    % frameArray2: [N × 1] array of frame indices for the second set
    % MvTime: [M × 1] array of time corresponding to each frame
    % DLCframe: [M × 1] array of frame indices corresponding to MvTime
    % Returns:
    % time: [N × 1] array of time differences corresponding to frameArray1 and frameArray2

    % Find the time corresponding to each frame in frameArray1 and frameArray2
    time1 = MvTime(DLCframe(frameArray1)+1);
    time2 = MvTime(DLCframe(frameArray2)+1);
    % Calculate the time differences
    time = time2 - time1;
    % If time is empty, return an empty array
    if isempty(time)
        time = [];
    end
end