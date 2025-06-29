function filtered_data = fn_butterworth_RNN(data, sample_rate, cutoff_freq, filter_order)
    % Design a Butterworth filter
    [b, a] = butter(filter_order, cutoff_freq/(sample_rate/2));
    
    % Apply the filter
    filtered_data = filtfilt(b, a, data);
end