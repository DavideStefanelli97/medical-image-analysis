%% ============================= PROJECT OVERVIEW ==============================
%  GOAL:
%  This script performs kidney and medulla segmentation from two axial CT
%  DICOM scans: one acquired with contrast agent and one without. The goal is
%  to compute the anatomical areas (in mm²) of both structures.
%
%  Minor patient movements between acquisitions are corrected via a
%  translation-based registration step using a manually selected ROI and
%  similarity metric (Normalized Cross-Correlation).
%
%  Segmentation is performed using the Chan–Vese active contour model,
%  preceded by preprocessing (normalization, enhancement, smoothing),
%  followed by post-processing for contour refinement.
%
%  PROCESS OVERVIEW:
%  • Load DICOM data (CT with and without contrast)
%  • Perform registration using translation and NCC over ROI
%  • Preprocess the registered image (normalization, sigmoid, smoothing)
%  • Segment the kidney (outer boundary) via Chan–Vese
%  • Segment the medulla region (internal structures) via Chan–Vese
%  • Visualize results and report final areas in mm²
%
% =============================================================================

%% ============================= 1. DATA LOADING ===================================

% Clear workspace and close all figures
clc; clear; close all;

% Initialize project paths
scriptDir = fileparts(mfilename('fullpath'));
run(fullfile(scriptDir, '..', '..', 'setup.m'));

% Load DICOM metadata and pixel data
info_contrast = dicominfo(fullfile(PROJECT_ROOT, 'data', 'IM3696'));       % Image with contrast (used as fixed)
IM_con = double(dicomread(info_contrast));
info_nocontrast = dicominfo(fullfile(PROJECT_ROOT, 'data', 'IM1883'));     % Image without contrast (to be registered)
IM_nocon = double(dicomread(info_nocontrast));
% Retrieve pixel spacing (used for area computation)
ps = info_nocontrast.PixelSpacing;

%% ============================= 2. REGISTRATION =======================================

% Display the fixed image and ask user to select a rectangular ROI
figure; imshow(IM_con, []); 
title('Select ROI for registration (on contrast-enhanced image)');
roi_rect = round(getrect()); 
close;

% Crop selected ROI from both images
CROP_con    = imcrop(IM_con, roi_rect);        % From fixed (contrast)
CROP_nocon  = imcrop(IM_nocon, roi_rect);      % From moving (non-contrast)

% Perform translation-only registration using Normalized Cross-Correlation (NCC)
[~, best_params, ~] = smartRegister(CROP_con, CROP_nocon, ...
    'trasl', ...
    'metric', 'NCC', ...
    'verbose', true, ...
    'max_shift', 10);

% Extract optimal translation vector [dy, dx]
translation_vector = best_params.translation;

% Apply translation to full moving image (non-contrast)
IM_nocon = imtranslate(IM_nocon, translation_vector, ...
    'FillValues', 0);  % Fill out-of-bound regions with 0

% Visualize aligned images
image_viewer(IM_con,   'IM1 - Fixed (With Contrast Agent)', true, ps);
image_viewer(IM_nocon, 'IM2 - Registered (Without Contrast Agent)', true, ps);

%% ============================= 3. PREPROCESSING ======================================

% Ask user to select ROI for segmentation (on contrast-enhanced image)
figure; imshow(IM_con, []);
title('Select ROI for segmentation');
roi_seg = getrect(); 
close;

% Convert ROI to valid pixel coordinates
x_start = max(1, floor(roi_seg(1)));
y_start = max(1, floor(roi_seg(2)));
x_end   = min(size(IM_con, 2), ceil(roi_seg(1) + roi_seg(3)) - 1);
y_end   = min(size(IM_con, 1), ceil(roi_seg(2) + roi_seg(4)) - 1);

roi_width  = x_end - x_start + 1;
roi_height = y_end - y_start + 1;

% Apply cropping to both images (fixed and registered)
CROP_con    = IM_con(y_start:y_end, x_start:x_end);
CROP_nocon  = IM_nocon(y_start:y_end, x_start:x_end);

% Display cropped regions and ROI positioning
figure('Name', 'Crop Validation', 'NumberTitle', 'off');
tiledlayout(2,2, 'Padding', 'compact', 'TileSpacing', 'compact');

% Original image with ROI
nexttile;
imshow(IM_con, []); hold on;
rectangle('Position', [x_start, y_start, roi_width, roi_height], ...
          'EdgeColor', 'g', 'LineWidth', 1.5);
title('Fixed Image (With Contrast)');
axis image; colorbar;

nexttile;
imshow(IM_nocon, []); hold on;
rectangle('Position', [x_start, y_start, roi_width, roi_height], ...
          'EdgeColor', 'm', 'LineWidth', 1.5);
title('Registered Image (Without Contrast)');
axis image; colorbar;

% Cropped images
nexttile;
imshow(CROP_con, []);
title('Cropped Region — Fixed Image');
axis image; colorbar;

nexttile;
imshow(CROP_nocon, []);
title('Cropped Region — Registered Image');
axis image; colorbar;

% Print crop info to console
fprintf('📐 Segmentation ROI:\n- Top-left: (x=%d, y=%d)\n- Size: %dx%d\n\n', ...
        x_start, y_start, roi_width, roi_height);

% --------------------- INTENSITY NORMALIZATION [0, 1] ---------------------
CROP_con   = mat2gray(CROP_con);
CROP_nocon = mat2gray(CROP_nocon);

image_viewer(CROP_con,   'Cropped (With Contrast) — Normalized', true);
image_viewer(CROP_nocon, 'Cropped (No Contrast) — Normalized', true);

% --------------------- SIGMOID CONTRAST ENHANCEMENT -----------------------
sigmoid_center    = 0.65;
sigmoid_sharpness = 20;
sigmoid_func      = @(x) 1 ./ (1 + exp(-sigmoid_sharpness * (x - sigmoid_center)));

CROP_con_sigm   = sigmoid_func(CROP_con);
CROP_nocon_sigm = sigmoid_func(CROP_nocon);

% --------------------- GAUSSIAN SMOOTHING ---------------------------------
gauss_sigma = 1.0;

CROP_con_gauss   = imgaussfilt(CROP_con_sigm, gauss_sigma);
image_viewer(CROP_con_gauss, 'Cropped (With Contrast) — Gaussian Smoothing', true);

% --------------------- ANISOTROPIC DIFFUSION ------------------------------
n_iter       = 15;
delta_t      = 1/7;
kappa        = 30;
diff_option  = 1;

CROP_nocon_anis = anisodiff2D(CROP_nocon_sigm, n_iter, delta_t, kappa, diff_option);
image_viewer(CROP_nocon_anis, 'Cropped (No Contrast) — Anisotropic Diffusion', true);

%% ============================= 4. FIRST SEGMENTATION ================================

% Select preprocessed image for segmentation (non-contrast + anisotropic diffusion)
Image = CROP_nocon_anis;

% ---------------- INITIALIZE LEVEL-SET FUNCTION (LSF) -------------------
initial_radius = 30;

% Interactive seed point selection and initial φ computation
[phi, X, Y, center_seed] = computeLSF('InputImage', Image, ...
    'InteractiveCenter', true, ...
    'Radius', initial_radius, ...
    'InsidePositive', false);

% Display φ contour over original image
plotLSF(phi, X, Y, 'OverlayImage', Image);

% ---------------- CHAN-VESE EVOLUTION LOOP -----------------------------
mu      = 0.5;      % curvature weight
lambda1 = 30;       % inside fidelity
lambda2 = -30;      % outside fidelity
ni      = 0.0;      % balloon force
max_iterations = 200;
time_step      = 0.1;
epsilon        = 0.1;

segmented_area = zeros(1, max_iterations);

for i = 1:max_iterations
    % Compute curvature
    [phi_x, phi_y] = gradient(phi);
    normGrad = sqrt(phi_x.^2 + phi_y.^2 + epsilon);
    Nx = phi_x ./ normGrad;
    Ny = phi_y ./ normGrad;
    curvature = divergence(Nx, Ny);

    % Compute mean intensities inside and outside φ
    inside  = (phi < 0);
    outside = ~inside;

    c1 = sum(Image(inside)) / (sum(inside(:)) + epsilon);
    c2 = sum(Image(outside)) / (sum(outside(:)) + epsilon);

    % Update φ
    phi = phi + time_step * (mu * curvature + ni + ...
          lambda1 * (Image - c1).^2 + lambda2 * (Image - c2).^2);

    % Track area for early stopping
    segmented_area(i) = nnz(phi < 0);

    % Visualize φ every 2 iterations
    if mod(i, 2) == 1
        figure(100); imagesc(Image); colormap gray; axis image; hold on;
        contour(phi, [0 0], 'r', 'LineWidth', 1);
        title(sprintf('Chan-Vese Iteration %d', i)); drawnow;
    end

    % Check for area convergence
    if i > 5
        delta_area = abs(segmented_area(i) - segmented_area(i - 5)) / ...
                     (segmented_area(i) + epsilon);
        if delta_area < 0.01
            fprintf('✓ Early stop: area change = %.4f%% at iteration %d\n', ...
                    delta_area * 100, i);
            break;
        end
    end
end

% ---------------- POST-PROCESSING MASK -------------------------------
% Raw binary mask
BW = phi < 0;

% Create marker at selected seed position
marker = false(size(BW));
x0 = round(center_seed(1));
y0 = round(center_seed(2));

if x0 >= 1 && x0 <= size(BW,2) && y0 >= 1 && y0 <= size(BW,1)
    marker(y0, x0) = true;
else
    warning('⚠️ Seed point is outside ROI bounds.');
end

% Morphological reconstruction from seed and hole filling
reconstructed_mask = imreconstruct(marker, BW);
mask_kidney = imfill(reconstructed_mask, 'holes');

% Compute area (in mm²)
pixel_area_count = sum(mask_kidney(:));
area_mm2_kidney = pixel_area_count * ps(1) * ps(2);
fprintf('📏 Kidney segmented area: %.2f mm²\n', area_mm2_kidney);

% Store final φ and contour coordinates
phi_kidney = phi;
[x_phi_kidney, y_phi_kidney] = meshgrid(0:roi_width-1, 0:roi_height-1);
x_phi_kidney = x_phi_kidney + x_start;
y_phi_kidney = y_phi_kidney + y_start;

%% ============================= 5. SECOND SEGMENTATION ===============================

% Select preprocessed contrast-enhanced image (Gaussian smoothed)
Image = CROP_con_gauss;

% ---------------- INITIALIZE LEVEL-SET FUNCTION --------------------------
max_iterations = 200;
time_step      = 0.1;
epsilon        = 0.1;
initial_radius = 5;

[phi, X, Y, center_seed] = computeLSF('InputImage', Image, ...
    'InteractiveCenter', true, ...
    'Radius', initial_radius, ...
    'InsidePositive', false);

plotLSF(phi, X, Y, 'OverlayImage', Image);

% ---------------- CHAN-VESE EVOLUTION LOOP -------------------------------
mu      = 0.5;
lambda1 = 30;
lambda2 = -30;
ni      = 0.0;

segmented_area = zeros(1, max_iterations);

for i = 1:max_iterations
    % Compute curvature
    [phi_x, phi_y] = gradient(phi);
    normGrad = sqrt(phi_x.^2 + phi_y.^2 + epsilon);
    Nx = phi_x ./ normGrad;
    Ny = phi_y ./ normGrad;
    curvature = divergence(Nx, Ny);

    % Compute mean intensities
    inside  = (phi < 0);
    outside = ~inside;

    c1 = sum(Image(inside)) / (sum(inside(:)) + epsilon);
    c2 = sum(Image(outside)) / (sum(outside(:)) + epsilon);

    % Update φ
    phi = phi + time_step * (mu * curvature + ni + ...
          lambda1 * (Image - c1).^2 + lambda2 * (Image - c2).^2);

    segmented_area(i) = nnz(phi < 0);

    % Visualize evolution
    if mod(i, 2) == 1
        figure(100); imagesc(Image); colormap gray; axis image; hold on;
        contour(phi, [0 0], 'r', 'LineWidth', 1);
        title(sprintf('Chan-Vese Iteration %d', i)); drawnow;
    end

    % Early stopping
    if i > 5
        delta_area = abs(segmented_area(i) - segmented_area(i - 5)) / ...
                     (segmented_area(i) + epsilon);
        if delta_area < 0.01
            fprintf('✓ Early stop: area change = %.4f%% at iteration %d\n', ...
                    delta_area * 100, i);
            break;
        end
    end
end

% ---------------- MEDULLA MASK REFINEMENT --------------------------------
% Binary mask from φ
mask_medulla = phi < 0;

% Erode kidney mask (to remove the outher border)
mask_kidney_copy = imerode(mask_kidney, strel('disk', 5));

% Combine: keep only medulla 
mask_medulla = ~(mask_medulla | ~mask_kidney_copy);

% Optional: extract cortex by subtraction
mask_cortex = mask_kidney & ~mask_medulla;

%% ============================= 6. FINAL REPORT =======================================

% ---------------- AREA CALCULATION ---------------------------------------
area_px_kidney       = nnz(mask_kidney);
area_px_medulla      = nnz(mask_medulla);

area_mm2_kidney      = area_px_kidney * prod(ps);
area_mm2_medulla_ext = area_px_medulla * prod(ps);
area_cortex          = area_mm2_kidney - area_mm2_medulla_ext;

% ---------------- VISUALIZATION PANEL -----------------------------------
figure('Name','Final Segmentation Report — Kidney & Medulla', ...
       'Units','normalized', 'Position',[0.2, 0.2, 0.7, 0.65]);

t = tiledlayout(1,2, 'TileSpacing','compact', 'Padding','compact');
title(t, 'Final Segmentation Report: Kidney & Medulla', ...
      'FontSize', 16, 'FontWeight', 'bold');

% === LEFT TILE: Overlay of all contours ===
nexttile;
imshow(IM_con, []); hold on; axis image; colormap gray;
title('Segmented Kidney + Medulla + Cortex');

contour(x_phi_kidney, y_phi_kidney, double(mask_medulla), 'm', 'LineWidth', 1.5);
contour(x_phi_kidney, y_phi_kidney, double(mask_kidney), 'g', 'LineWidth', 1.5);
title('Full Image (Registered) — Kidney + Medulla');
axis image off;

% === RIGHT TILE: Textual summary of area results ===
nexttile;
axis off;
xlim([0 1]); ylim([0 1]);

text(0.05, 0.85, 'SEGMENTATION RESULTS:', ...
     'FontSize', 13, 'FontWeight', 'bold', 'Interpreter','none');

dy = 0.07; y = 0.7;

text(0.05, y, 'Kidney Area:', 'FontWeight', 'bold', 'FontSize',11);
text(0.55, y, sprintf('%.2f mm²', area_mm2_kidney), 'FontSize',11); y = y - dy;

text(0.05, y, 'Medulla Area:', 'FontWeight', 'bold', 'FontSize',11);
text(0.55, y, sprintf('%.2f mm²', area_mm2_medulla_ext), 'FontSize',11); y = y - dy;

text(0.05, y, 'Cortex Area (Kidney - Medulla):', 'FontWeight', 'bold', 'FontSize',11);
text(0.55, y, sprintf('%.2f mm²', area_cortex), 'FontSize',11);  

% ---------------- COMMAND WINDOW REPORT ----------------------------------
fprintf('\n================= FINAL SEGMENTATION REPORT =================\n');
fprintf('✔ Kidney Area      : %.2f mm²\n', area_mm2_kidney);
fprintf('✔ Medulla Area     : %.2f mm²\n', area_mm2_medulla_ext);
fprintf('✔ Cortex Area      : %.2f mm²\n', area_cortex);
fprintf('==============================================================\n');
