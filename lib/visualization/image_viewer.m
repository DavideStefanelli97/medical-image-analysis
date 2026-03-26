function image_viewer(I, name, displayInfo, PixelSpacing)

%IMAGE_VIEWER Display image and histogram with optional diagnostic info
%
%   image_viewer(I, name, displayInfo, PixelSpacing)
%
%   INPUTS:
%   - I            : 2D image matrix (any numeric type)
%   - name         : string to be used as the figure title and subplot titles
%   - displayInfo  : (optional) true/false to print image diagnostics in command window (default: false)
%   - PixelSpacing : (optional) 1x2 vector with pixel spacing in mm (e.g. [0.7 0.7])
%
%   This function:
%   - Displays the image with proper aspect ratio and grayscale colormap
%   - Plots the histogram of the image intensity values
%   - Optionally prints diagnostic info such as size, min/max intensity, data type, and pixel spacing
%
%   EXAMPLE USAGE:
%   image_viewer(Image, 'Original DICOM', true, [0.7, 0.7]);
% Author: Davide Stefanelli

    % --- Set default values for optional arguments ---
    if nargin < 3 || isempty(displayInfo)
        displayInfo = false;
    end
    if nargin < 4 || isempty(PixelSpacing)
        PixelSpacing = [NaN NaN];  % Unknown spacing
    end

    % --- Display image and histogram in a single figure ---
    figure('Name', ['Image and Histogram: ' name], 'NumberTitle', 'off');

    % Subplot: Image visualization
    subplot(1,2,1);
    imagesc(I);
    colormap gray;
    axis image;
    axis on;
    colorbar;
    title(['Image - ' name], 'Interpreter', 'none');
    xlabel('X [pixels]');
    ylabel('Y [pixels]');

    % Subplot: Histogram of intensity values
    subplot(1,2,2);
    histogram(I(:), 100);
    title(['Histogram - ' name], 'Interpreter', 'none');
    xlabel('Intensity Values');
    ylabel('Pixel Count');
    grid on;

    % --- Optional console output ---
    if displayInfo
        [nx, ny] = size(I);
        fprintf('\n--- Image Analysis: %s ---\n', name);
        fprintf('Image type      : %s\n', class(I));
        fprintf('Image size      : %d x %d [pixels]\n', nx, ny);
        fprintf('Min intensity   : %.4f\n', min(I(:)));
        fprintf('Max intensity   : %.4f\n', max(I(:)));

        if ~any(isnan(PixelSpacing))
            fprintf('Pixel spacing   : %.4f x %.4f [mm]\n', PixelSpacing(1), PixelSpacing(2));
            area_mm2 = nx * ny * PixelSpacing(1) * PixelSpacing(2);
            fprintf('Total image area: %.2f mm²\n', area_mm2);
        else
            fprintf('Pixel spacing   : Unknown\n');
        end
    end
end



