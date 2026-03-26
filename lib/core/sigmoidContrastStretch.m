function Iout = sigmoidContrastStretch(Iin, inRange, outRange, k, showPlot)
%SIGMOIDCONTRASTSTRETCH Applies sigmoid-based contrast stretching
%
%   Iout = sigmoidContrastStretch(Iin, inRange, outRange, k, showPlot)
%
%   - Iin:       Input image (single or double)
%   - inRange:   [a b] → interval of interest to be mapped with sigmoid
%   - outRange:  [min_out max_out] → final intensity range (e.g. [0 256])
%   - k:         Steepness of sigmoid (e.g. 0.05–0.2 typical)
%   - showPlot:  true/false → diagnostic plots
%
%   Output: Iout → image with smooth intensity remapping
% Author: Davide Stefanelli

    if nargin < 3 || isempty(outRange)
        outRange = [0, 256];
    end
    if nargin < 4 || isempty(k)
        k = 0.05;  % default smoothness
    end
    if nargin < 5
        showPlot = false;
    end

    a = inRange(1);
    b = inRange(2);
    c = (a + b) / 2;

    % Sigmoid function centered at c, scaled to [0,1]
    S = 1 ./ (1 + exp(-k * (Iin - c)));

    % Normalize sigmoid output between 0 and 1
    Smin = 1 / (1 + exp(-k * (a - c)));
    Smax = 1 / (1 + exp(-k * (b - c)));
    S_norm = (S - Smin) / (Smax - Smin);

    % Clip outside [a,b]
    S_norm(Iin < a) = 0;
    S_norm(Iin > b) = 1;

    % Scale to output range
    Iout = S_norm * (outRange(2) - outRange(1)) + outRange(1);
    Iout = single(Iout);  % ensure consistent type

    % Optional plot
    if showPlot
        figure('Name','Sigmoid Contrast Stretching');
        subplot(1,2,1);
        histogram(Iin(:), 100); grid on;
        title('Original Histogram');
        xlabel('Intensity'); ylabel('Pixel Count');

        subplot(1,2,2);
        histogram(Iout(:), 100); grid on;
        title('Sigmoid-Stretched Histogram');
        xlabel('Intensity'); ylabel('Pixel Count');

        fprintf('\n--- Sigmoid Contrast Stretch ---\n');
        fprintf('Input range:     [%.2f, %.2f]\n', min(Iin(:)), max(Iin(:)));
        fprintf('Mapping range:   [%.2f, %.2f]\n', a, b);
        fprintf('Output range:    [%.2f, %.2f]\n', outRange(1), outRange(2));
        fprintf('Sigmoid gain k:  %.4f\n', k);
    end
end

