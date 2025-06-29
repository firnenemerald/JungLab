function filtered_data = fn_gaussian_RNN(data, window_size, sigma)
    % Define the Gaussian kernel
    half_window = (window_size - 1) / 2;
    x = -half_window:half_window;
    gaussian_kernel = exp(-(x.^2) / (2 * sigma^2));
    gaussian_kernel = gaussian_kernel / sum(gaussian_kernel); % Normalize

    % Apply Gaussian filter using convolution
    filtered_data = conv(data, gaussian_kernel, 'same');
end