function filtered_data = fn_savgol_RNN(data, poly_order, window_size)
    % Apply Savitzky-Golay filter
    filtered_data = sgolayfilt(data, poly_order, window_size);
end