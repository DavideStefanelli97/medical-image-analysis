%% ============================= PROJECT OVERVIEW ==============================
%  GOAL:
%  This script segments the endocardium of the left (LV) and right (RV)
%  ventricles from a short-axis DICOM image (SE06_IM194), including trabeculae,
%  using the Malladi–Sethian level set evolution model.
%
%  PROCESS OVERVIEW:
%  • Load the DICOM image and retrieve pixel spacing.
%  • Preprocess the image via normalization and anisotropic diffusion.
%  • Compute the edge indicator function based on gradient magnitude.
%  • Run Malladi–Sethian level set evolution separately for LV and RV.
%  • visualize the contours over the original image.
%  • Compute and report segmented areas (in mm²).
%
% =============================================================================

%% ========================= 1. INITIALIZATION & LOADING =======================
clc; clear; close all;

% Initialize project paths
scriptDir = fileparts(mfilename('fullpath'));
run(fullfile(scriptDir, '..', '..', 'setup.m'));

% Define image location and load
filename  = 'SE06_IM194';
full_path = fullfile(PROJECT_ROOT, 'data', filename);

% Load DICOM image and metadata
info_IM   = dicominfo(full_path);
Image_IM  = double(dicomread(full_path));
ps        = info_IM.PixelSpacing;  % Pixel spacing in mm

% Display the original image using custom viewer
image_viewer(Image_IM, 'Original Image — SE06\_IM194', true, ps);

%% ============================ 2. PREPROCESSING ===============================
% Normalize the intensity values to [0, 1]
Image_IM_norm = mat2gray(Image_IM);

% Apply anisotropic diffusion to reduce noise and preserve edges
% Parameters: iterations, time step, kappa (edge sensitivity), option
num_iter = 7;
delta_t  = 1/7;
kappa    = 7;
option   = 1;
Image_IM_filt = anisodiff2D(Image_IM_norm, num_iter, delta_t, kappa, option);

% Display the original image using custom viewer
image_viewer(Image_IM_filt, 'Diffused Image — SE06\_IM194', true, ps);

%% ===================== 3. EDGE INDICATOR FUNCTION ============================
% Edge indicator function: low values at edges, high in flat regions
beta  = 0.1;   % Gradient scaling parameter
alpha = 2;     % Steepness of edge function

g = 1 ./ (1 + (Grad(Image_IM_filt) ./ beta)).^alpha;

% Visualize edge indicator and gradient field
figure('Name','Edge Indicator Function'); 
imagesc(g); colormap gray; axis image off;
title('Edge Indicator and Gradient Vectors');
hold on; quiver(Dx(g), Dy(g), 'g'); hold off;

%% ================== 4. FIRST SEGMENTATION: LEFT VENTRICLE ====================
% Select initial seed for LV and create level-set function
radius = 10;
[phi1, X, Y, ~] = computeLSF('InputImage', Image_IM, ...
                             'InteractiveCenter', true, ...
                             'Radius', radius, ...
                             'InsidePositive', false);
plotLSF(phi1, X, Y, 'OverlayImage', Image_IM);

% Evolution parameters
maxIter = 1500;
dt      = 0.1;
eps     = 3;
ni      = 2;  % Advection weight (more aggressive than RV)
fx      = Dx(g);
fy      = Dy(g);

% Evolution loop for φ (LV)
area_intime1 = zeros(maxIter, 1);
for i = 1:maxIter
    phi1 = phi1 + dt * g .* ((eps * K(phi1) - 1) .* Grad(phi1)) + ni .* Gup(phi1, fx, fy);
    A = phi1 < 0;
    area_intime1(i) = sum(A(:));

    if mod(i, 10) == 1
        figure(10); clf;
        imagesc(Image_IM_filt); colormap gray; axis image off; hold on;
        contour(phi1, [0 0], 'g', 'LineWidth', 1.5);
        title(['LV — Iteration ', num2str(i)]); drawnow; hold off;
    end

    if i > 140 && area_intime1(i) == area_intime1(i - 10)
        break;
    end
end

% Compute segmented area in mm²
area1_mm2 = area_intime1(i) * prod(ps);
fprintf('\n================ LEFT VENTRICLE REPORT ===================\n');
fprintf('Final Iteration        : %d\n', i);
fprintf('Segmented Area (px²)   : %d\n', area_intime1(i));
fprintf('Segmented Area (mm²)   : %.2f\n', area1_mm2);
fprintf('Pixel Spacing          : [%.3f mm, %.3f mm]\n', ps(1), ps(2));
fprintf('===========================================================\n');

%% ================== 5. SECOND SEGMENTATION: RIGHT VENTRICLE ==================
% New seed for RV
[phi2, X, Y, ~] = computeLSF('InputImage', Image_IM, ...
                             'InteractiveCenter', true, ...
                             'Radius', radius, ...
                             'InsidePositive', false);
plotLSF(phi2, X, Y, 'OverlayImage', Image_IM);

ni = 0.8;  % Lower advection force for RV (more conservative)
area_intime2 = zeros(maxIter, 1);

for i = 1:maxIter
    phi2 = phi2 + dt * g .* ((eps * K(phi2) - 1) .* Grad(phi2)) + ni .* Gup(phi2, fx, fy);
    A = phi2 < 0;
    area_intime2(i) = sum(A(:));

    if mod(i, 10) == 1
        figure(10); clf;
        imagesc(Image_IM_filt); colormap gray; axis image off; hold on;
        contour(phi2, [0 0], 'g', 'LineWidth', 1.5);
        contour(phi1, [0 0], 'm', 'LineWidth', 2);
        title(['RV — Iteration ', num2str(i)]);
        drawnow; hold off;
    end

    if i > 140 && area_intime2(i) == area_intime2(i - 10)
        break;
    end
end

% Compute segmented area in mm²
area2_mm2 = area_intime2(i) * prod(ps);
fprintf('\n================ RIGHT VENTRICLE REPORT ==================\n');
fprintf('Final Iteration        : %d\n', i);
fprintf('Segmented Area (px²)   : %d\n', area_intime2(i));
fprintf('Segmented Area (mm²)   : %.2f\n', area2_mm2);
fprintf('Pixel Spacing          : [%.3f mm, %.3f mm]\n', ps(1), ps(2));
fprintf('===========================================================\n');

%% ========================= 6. FINAL VISUALIZATION ============================
figure('Name', 'Final Segmentation — LV & RV');
imshow(Image_IM, []); colormap gray; axis image off; hold on;
contour(phi1, [0 0], 'm', 'LineWidth', 2);  % LV in magenta
contour(phi2, [0 0], 'g', 'LineWidth', 2);  % RV in green
title('Final Segmentation — SE06\_IM194');
legend('LV Contour', 'RV Contour');

%% ====================== 7. COMMAND WINDOW SUMMARY ============================
fprintf('\n==================== SEGMENTATION SUMMARY ====================\n');
fprintf('✔ Left Ventricle Area     : %.2f mm²\n', area1_mm2);
fprintf('✔ Right Ventricle Area    : %.2f mm²\n', area2_mm2);
fprintf('✔ Total Segmented Area    : %.2f mm²\n', area1_mm2 + area2_mm2);
fprintf('===============================================================\n');
