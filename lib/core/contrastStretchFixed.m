function Iout = contrastStretchFixed(Iin, outRange, showPlot)
%CONTRASTSTRETCHFIXED Stretch image contrast to a fixed output range.
%
%   Iout = contrastStretchFixed(Iin, [min_out max_out], showPlot)
%
%   - Iin:       Input image (any numeric type)
%   - outRange:  [min_out, max_out] → default [0, 256] if not specified
%   - showPlot:  true/false → whether to show histogram and info (default: false)
%
%   Output:
%   - Iout: image scaled into the desired range, as 'single'
% Author: Davide Stefanelli

    % Set default output range
    if nargin < 2 || isempty(outRange)
        outRange = [0, 256];
    end

    % Set default for showPlot
    if nargin < 3
        showPlot = false;
    end

    % Compute 5th and 95th percentile to avoid outliers
    pLow = prctile(Iin(:), 5);
    pHigh = prctile(Iin(:), 95);

    % Prevent degenerate stretch
    if abs(pHigh - pLow) < eps
        warning('Input image has low dynamic range. Skipping stretching.');
        Iout = single(Iin);
        return;
    end

    % Linear stretching
    Iout = (Iin - pLow) * ((outRange(2) - outRange(1)) / (pHigh - pLow));
    
    % Clipping
    Iout(Iin <= pLow) = outRange(1);
    Iout(Iin >= pHigh) = outRange(2);

    % Convert to single precision
    Iout = single(Iout);

    % Optional diagnostic plot
    if showPlot
        figure('Name','Contrast Stretching');
        subplot(1,2,1);
        histogram(Iin(:), 100);
        title('Original Histogram');
        xlabel('Intensity'); ylabel('Pixel Count');
        grid on;

        subplot(1,2,2);
        histogram(Iout(:), 100);
        title('Stretched Histogram');
        xlabel('Intensity'); ylabel('Pixel Count');
        grid on;

        % Console log
        fprintf('\n--- Contrast Stretch Report ---\n');
        fprintf('Input range: [%.2f, %.2f] (p5-p95)\n', pLow, pHigh);
        fprintf('Output range: [%.2f, %.2f]\n', outRange(1), outRange(2));
        fprintf('Final min: %.2f, max: %.2f\n', min(Iout(:)), max(Iout(:)));
    end
end

