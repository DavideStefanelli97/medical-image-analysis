%% ============================= PROJECT OVERVIEW ==============================
%  GOAL:
%  This script segments a lesion from a contrast-enhanced MR breast image 
%  using the Malladi–Sethian level set evolution model.
%
%  PROCESS OVERVIEW:
%  • Load the DICOM image and pixel spacing.
%  • Preprocess the image via normalization and anisotropic diffusion.
%  • Compute an edge indicator based on gradient magnitude.
%  • Run Malladi–Sethian level set evolution from a user-defined seed.
%  • Visualize and report the segmented area (in mm²).
%
% =============================================================================

%% ------------------------- 1. INITIALIZATION & LOADING ------------------------
clc; clear; close all;

% Initialize project paths
scriptDir = fileparts(mfilename('fullpath'));
run(fullfile(scriptDir, '..', '..', 'setup.m'));

% Load the MR breast image
filename = 'MR_breast';
full_path = fullfile(PROJECT_ROOT, 'data', filename);

info = dicominfo(full_path);
I = double(dicomread(full_path));
ps = info.PixelSpacing;   % [dy, dx] in mm
image_viewer(I, 'MR_breast', true, ps)

% Print image information
fprintf('\n=== IMAGE INFORMATION ===\n');
fprintf('Size                   : %d × %d pixels\n', size(I,1), size(I,2));
fprintf('Pixel spacing          : %.3f × %.3f mm\n', ps(1), ps(2));

%% ------------------------- 2. PREPROCESSING ----------------------------------
% Normalize image to [0, 1]
I_norm = (I - min(I(:))) / (max(I(:)) - min(I(:)));

% Apply anisotropic diffusion
num_iter = 7; 
delta_t = 1/7; 
kappa = 7; 
option = 1;

I_filt = anisodiff2D(I_norm, num_iter, delta_t, kappa, option);
image_viewer(I_filt, 'MR_breast filtered', true, ps)

%% ------------------------- 3. LSF INITIALIZATION -----------------------------
% Interactive level set initialization
init_radius = 3;

[phi, X, Y, center] = computeLSF( ...
    'InputImage', I, ...
    'InteractiveCenter', true, ...
    'Radius', init_radius, ...
    'InsidePositive', false);

plotLSF(phi, X, Y, 'OverlayImage', I);

%% ------------------------- 4. EDGE INDICATOR FUNCTION ------------------------
% Compute gradient-based edge indicator
beta = 0.1; 
alpha = 2;

g = 1 ./ (1 + (Grad(I_filt) ./ beta)).^alpha;

% Visualize edge indicator and vector field
figure('Name','Edge Indicator Visualization');
imagesc(g); colormap gray; axis image off; hold on;
quiver(X, Y, -Dx(g), -Dy(g), 'g');
hold off;

%% ------------------------- 5. LEVEL SET EVOLUTION ----------------------------
maxIter = 1500; 
dt = 0.1; 
eps = 3; 
ni = 2;

fx = Dx(g); 
fy = Dy(g);

area_intime = zeros(maxIter, 1);

for i = 1:maxIter
    phi = phi + dt * g .* ((eps * K(phi) - 1) .* Grad(phi)) + ni .* Gup(phi, fx, fy);
    A = phi < 0;
    area_intime(i) = sum(A(:));

    if mod(i, 10) == 1
        figure(10); clf;
        imagesc(I_filt); colormap gray; axis image off; hold on;
        contour(phi, [0 0], 'm', 'LineWidth', 1.5);
        title(['Iteration: ', num2str(i)]);
        drawnow;
        hold off;
    end

    % Stop if area stabilizes
    if i > 140 && area_intime(i) == area_intime(i - 10)
        break;
    end
end

%% ------------------------- 6. FINAL REPORT & VISUALIZATION -------------------
finalArea = area_intime(i);
area_mm2 = finalArea * ps(1) * ps(2);

% Report to console
fprintf('\n========== FINAL SEGMENTATION REPORT ==========\n');
fprintf('Final Iteration                 : %d\n', i);
fprintf('Segmented Area (in pixels)      : %d px²\n', finalArea);
fprintf('Segmented Area (in mm²)         : %.2f mm²\n', area_mm2);
fprintf('Pixel Spacing                   : [%.3f mm, %.3f mm]\n', ps(1), ps(2));
fprintf('===============================================\n');

%% ------------------------- 7. ZOOMED VISUALIZATION ---------------------------
% Bounding box around lesion
mask = phi < 0;
props = regionprops(mask, 'BoundingBox', 'Centroid');
bbox = round(props.BoundingBox);
cx = round(props.Centroid(1)); cy = round(props.Centroid(2));

% Zoom ROI with padding
pad = 30;
x1 = max(bbox(1) - pad, 1);
y1 = max(bbox(2) - pad, 1);
x2 = min(x1 + bbox(3) + 2*pad, size(I,2));
y2 = min(y1 + bbox(4) + 2*pad, size(I,1));

% Display: full view + zoomed view
figure('Name', 'Final Segmentation - Overview and Zoomed View', 'Position', [100 100 1000 450]);

% --- Full Image ---
subplot(1,2,1);
imshow(I, []); colormap gray; axis image off; hold on;
contour(phi, [0 0], 'c', 'LineWidth', 2);
rectangle('Position', [x1, y1, x2 - x1, y2 - y1], ...
          'EdgeColor', 'y', ...
          'LineStyle', '--', ...
          'LineWidth', 1.0);
title('Full Image with Segmented Lesion');
legend('Segmented Contour');

% --- Zoomed View ---
subplot(1,2,2);
imshow(I(y1:y2, x1:x2), []); colormap gray; axis image off; hold on;
contour(phi(y1:y2, x1:x2), [0 0], 'c', 'LineWidth', 2);
text(10, 20, sprintf('Area = %.2f mm²', area_mm2), ...
     'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold', ...
     'BackgroundColor', 'black', 'Margin', 4);
title('Zoomed-in View of the Lesion');
