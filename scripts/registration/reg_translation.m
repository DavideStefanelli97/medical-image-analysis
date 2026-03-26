%% ========================= PROJECT OVERVIEW =============================
%  GOAL:
%  This script performs translational registration of multimodal medical
%  images (MRI_T2, MRI_DWI, PET) to align them on a common anatomical space.
%
%  PROCESS OVERVIEW:
%  • Load and inspect DICOM images (T2, DWI, PET).
%  • Resample DWI and PET to match MRI_T2 spatial resolution.
%  • Apply zero-padding to match image sizes.
%  • Perform exhaustive 2D grid search to find best translation using SSD and NCC.
%  • Apply optimal shifts and visualize results with checkerboard and metric maps.
%  • Evaluate registration quality.
%
%  REFERENCE:
%  The MRI_T2 image is used as the fixed reference due to its superior
%  anatomical detail and resolution.
% =========================================================================

%% ============== 1. INITIALIZATION & SETUP ===============================

clc; clear; close all;

% Initialize project paths
scriptDir = fileparts(mfilename('fullpath'));
run(fullfile(scriptDir, '..', '..', 'setup.m'));

%% ============== 2. LOAD DICOM IMAGES ====================================

% Load T2-weighted MRI image and metadata
info_T2 = dicominfo(fullfile(PROJECT_ROOT, 'data', 'MRI_T2.dcm'));
I_T2 = dicomread(info_T2);

% Load diffusion-weighted MRI image and metadata
info_DWI = dicominfo(fullfile(PROJECT_ROOT, 'data', 'MRI_DWI.dcm'));
I_DWI = dicomread(info_DWI);

% Load PET image and metadata
info_PET = dicominfo(fullfile(PROJECT_ROOT, 'data', 'PET.dcm'));
I_PET = squeeze(dicomread(info_PET));  % Remove singleton dimension if present

% Display image dimensions for validation
disp('--- Image Sizes (rows x cols) ---');
disp(['MRI T2       : ', num2str(size(I_T2,1)), ' x ', num2str(size(I_T2,2))]);
disp(['MRI DWI      : ', num2str(size(I_DWI,1)), ' x ', num2str(size(I_DWI,2))]);
disp(['PET          : ', num2str(size(I_PET,1)), ' x ', num2str(size(I_PET,2))]);
fprintf('=============================================================\n\n');

%% ============== 3. PIXEL SPACING & SCALING FACTORS ======================

% Extract Pixel Spacing [dy, dx] for each modality
ps_T2  = info_T2.PixelSpacing;
ps_DWI = info_DWI.PixelSpacing;
ps_PET = info_PET.PixelSpacing;

% Visualize che images:
image_viewer(I_T2,'T2: reference', false, ps_T2)
image_viewer(I_DWI,'DWI', false, ps_DWI)
image_viewer(I_PET,'PET', false, ps_PET)

% Display pixel spacing for all input images
disp('--- Pixel Spacing (dy, dx) ---');
disp(['MRI T2       : [', num2str(ps_T2(1)), ', ', num2str(ps_T2(2)), ']']);
disp(['MRI DWI      : [', num2str(ps_DWI(1)), ', ', num2str(ps_DWI(2)), ']']);
disp(['PET          : [', num2str(ps_PET(1)), ', ', num2str(ps_PET(2)), ']']);
fprintf('=============================================================\n\n');

% Compute scalar scaling factors (only dy component is used)
scale_DWI = ps_DWI(1) / ps_T2(1);
scale_PET = ps_PET(1) / ps_T2(1);

% Display scale factors
disp('--- Scaling Factors (DWI and PET → MRI T2) ---');
fprintf('DWI  scale factor: %.4f\n', scale_DWI);
fprintf('PET  scale factor: %.4f\n', scale_PET);
fprintf('=============================================================\n\n');

% Rescale DWI and PET images to match MRI_T2 resolution
I_DWI_scaled = imresize(I_DWI, scale_DWI);
I_PET_scaled = imresize(I_PET, scale_PET);
I_T2_scaled  = I_T2;  % Reference image remains unchanged

% Display image sizes after scaling
disp('--- Image Sizes After Scaling ---');
fprintf('MRI T2         : %d x %d (reference, unchanged)\n', size(I_T2_scaled,1), size(I_T2_scaled,2));
fprintf('MRI DWI scaled : %d x %d\n', size(I_DWI_scaled,1), size(I_DWI_scaled,2));
fprintf('PET scaled     : %d x %d\n', size(I_PET_scaled,1), size(I_PET_scaled,2));
fprintf('=============================================================\n\n');

% Store rescaled images for visualization
scaled_images = {I_T2_scaled, I_DWI_scaled, I_PET_scaled};
scaled_titles = {'MRI T2', 'MRI DWI (scaled)', 'PET (scaled)'};
scaled_ps = {ps_T2, ps_DWI, ps_PET};

%% ============== 4. SCALING & PADDING ====================================

% Pad all images to match the dimensions of the scaled PET image
I_T2_padded  = zeroPadding(I_T2_scaled, I_PET_scaled);
I_DWI_padded = zeroPadding(I_DWI_scaled, I_PET_scaled);
I_PET_padded = zeroPadding(I_PET_scaled, I_PET_scaled);  % Already target size

% Store padded images and labels
padded_images = {I_T2_padded, I_DWI_padded, I_PET_padded};
padded_titles = {'MRI T2 (padded)', 'MRI DWI (padded)', 'PET (padded)'};

%% ============== 5. VISUALIZATION: SCALING & PADDING =====================

figure('Name', 'Rescaling and Padding Overview', 'NumberTitle', 'off');

% Top row: Scaled images
for i = 1:3
    subplot(2,3,i);
    imagesc(scaled_images{i});
    axis image off; colormap gray; colorbar;
    sz = size(scaled_images{i});
    ps = ps_T2;
    title(sprintf('%s\nResolution: %.3f × %.3f mm/pixel', ...
        scaled_titles{i}, ps(1), ps(2)), ...
        'FontSize', 10, 'FontWeight', 'bold');
    text(10, sz(1)-10, ...
         sprintf('Size: %d × %d px', sz(1), sz(2)), ...
         'Color', 'yellow', 'FontSize', 9, ...
         'BackgroundColor', 'black', 'VerticalAlignment', 'bottom');
end

% Bottom row: Padded images
for i = 1:3
    subplot(2,3,i+3);
    imagesc(padded_images{i});
    axis image off; colormap gray; colorbar;
    sz = size(padded_images{i});
    title(sprintf('%s\nResolution: %.3f × %.3f mm/pixel', ...
        padded_titles{i}, ps(1), ps(2)), ...
        'FontSize', 10, 'FontWeight', 'bold');
    text(10, sz(1)-10, ...
         sprintf('Size: %d × %d px', sz(1), sz(2)), ...
         'Color', 'yellow', 'FontSize', 9, ...
         'BackgroundColor', 'black', 'VerticalAlignment', 'bottom');
end

%% ============== 6. REGISTRATION: GRID SEARCH ============================

shift = 20;
range = -shift:shift;
N = length(range);

SSD_DWI = zeros(N, N);
NCC_DWI = zeros(N, N);
MI_DWI  = zeros(N, N);

SSD_PET = zeros(N, N);
NCC_PET = zeros(N, N);
MI_PET  = zeros(N, N);

for ix = 1:N
    for iy = 1:N
        dx = range(ix);
        dy = range(iy);
        translation = [dy, dx];

        % Apply translation
        trans_DWI = imtranslate(I_DWI_padded, translation, 'FillValues', 0);
        trans_PET = imtranslate(I_PET_padded, translation, 'FillValues', 0);

        % Compute similarity metrics
        SSD_DWI(iy, ix) = SSD(I_T2_padded, trans_DWI);
        NCC_DWI(iy, ix) = NCC(I_T2_padded, trans_DWI);
        MI_DWI(iy, ix)  = MI(I_T2_padded, trans_DWI);

        SSD_PET(iy, ix) = SSD(I_T2_padded, trans_PET);
        NCC_PET(iy, ix) = NCC(I_T2_padded, trans_PET);
        MI_PET(iy, ix)  = MI(I_T2_padded, trans_PET);
    end
end

%% ============== 7. SELECT BEST TRANSLATION (NCC, SSD, MI) ===============

% --- DWI: best shifts ---
[~, idx_ncc_DWI] = max(NCC_DWI(:));
[dy_ncc_DWI, dx_ncc_DWI] = ind2sub(size(NCC_DWI), idx_ncc_DWI);
best_shift_NCC_DWI = [range(dy_ncc_DWI), range(dx_ncc_DWI)];

[~, idx_ssd_DWI] = min(SSD_DWI(:));
[dy_ssd_DWI, dx_ssd_DWI] = ind2sub(size(SSD_DWI), idx_ssd_DWI);
best_shift_SSD_DWI = [range(dy_ssd_DWI), range(dx_ssd_DWI)];

[~, idx_mi_DWI] = max(MI_DWI(:));
[dy_mi_DWI, dx_mi_DWI] = ind2sub(size(MI_DWI), idx_mi_DWI);
best_shift_MI_DWI = [range(dy_mi_DWI), range(dx_mi_DWI)];

% --- PET: best shifts ---
[~, idx_ncc_PET] = max(NCC_PET(:));
[dy_ncc_PET, dx_ncc_PET] = ind2sub(size(NCC_PET), idx_ncc_PET);
best_shift_NCC_PET = [range(dy_ncc_PET), range(dx_ncc_PET)];

[~, idx_ssd_PET] = min(SSD_PET(:));
[dy_ssd_PET, dx_ssd_PET] = ind2sub(size(SSD_PET), idx_ssd_PET);
best_shift_SSD_PET = [range(dy_ssd_PET), range(dx_ssd_PET)];

[~, idx_mi_PET] = max(MI_PET(:));
[dy_mi_PET, dx_mi_PET] = ind2sub(size(MI_PET), idx_mi_PET);
best_shift_MI_PET = [range(dy_mi_PET), range(dx_mi_PET)];

% --- Console output ---
fprintf('=============================================================\n');
fprintf('--- Optimal Translations (2D Grid Search Results) ---\n');
fprintf('=============================================================\n');
fprintf('>> DWI Registration:\n');
fprintf('   - NCC-based shift : [%d, %d] (dx, dy)\n', best_shift_NCC_DWI(2), best_shift_NCC_DWI(1));
fprintf('   - SSD-based shift : [%d, %d] (dx, dy)\n', best_shift_SSD_DWI(2), best_shift_SSD_DWI(1));
fprintf('   - MI-based shift  : [%d, %d] (dx, dy)\n', best_shift_MI_DWI(2), best_shift_MI_DWI(1));
fprintf('=============================================================\n');
fprintf('>> PET Registration:\n');
fprintf('   - NCC-based shift : [%d, %d] (dx, dy)\n', best_shift_NCC_PET(2), best_shift_NCC_PET(1));
fprintf('   - SSD-based shift : [%d, %d] (dx, dy)\n', best_shift_SSD_PET(2), best_shift_SSD_PET(1));
fprintf('   - MI-based shift  : [%d, %d] (dx, dy)\n', best_shift_MI_PET(2), best_shift_MI_PET(1));
fprintf('=============================================================\n\n');

% --- Apply registration using selected metric (default = NCC) ---

% Use NCC-based shift (default)
I_DWI_registered = imtranslate(I_DWI_padded, best_shift_NCC_DWI, 'FillValues', 0);
I_PET_registered = imtranslate(I_PET_padded, best_shift_NCC_PET, 'FillValues', 0);

% % Use SSD-based shift
% I_DWI_registered = imtranslate(I_DWI_padded, best_shift_SSD_DWI, 'FillValues', 0);
% I_PET_registered = imtranslate(I_PET_padded, best_shift_SSD_PET, 'FillValues', 0);

% % Use MI-based shift
% I_DWI_registered = imtranslate(I_DWI_padded, best_shift_MI_DWI, 'FillValues', 0);
% I_PET_registered = imtranslate(I_PET_padded, best_shift_MI_PET, 'FillValues', 0);

%% ============== 8. VISUALIZATION: CHECKERBOARD & JOINT HISTOGRAMS =======

% Compute joint histograms
numBins = 128;
H_DWI = compute_joint_histogram(I_T2_padded, I_DWI_registered, numBins);
H_PET = compute_joint_histogram(I_T2_padded, I_PET_registered, numBins);

% Create tiled layout
fig = figure('Name', 'Checkerboard & Joint Histograms', 'NumberTitle', 'off');
tlo = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- Checkerboard: T2 vs DWI ---
ax1 = nexttile;
checkerboard_view(double(I_T2_padded), double(I_DWI_registered), 20);
title('Checkerboard: T2 vs DWI (Registered)', 'FontWeight', 'bold');

% --- Checkerboard: T2 vs PET ---
ax2 = nexttile;
checkerboard_view(double(I_T2_padded), double(I_PET_registered), 20);
title('Checkerboard: T2 vs PET (Registered)', 'FontWeight', 'bold');

% --- Joint Histogram: T2 vs DWI ---
ax3 = nexttile;
imagesc(ax3, log(H_DWI + 1));
colormap(ax3, hot);
colorbar(ax3);
title('Joint Histogram: T2 vs DWI (Registered)', 'FontWeight', 'bold');
xlabel('Intensity values in DWI');
ylabel('Intensity values in T2');

% --- Joint Histogram: T2 vs PET ---
ax4 = nexttile;
imagesc(ax4, log(H_PET + 1));
colormap(ax4, hot);
colorbar(ax4);
title('Joint Histogram: T2 vs PET (Registered)', 'FontWeight', 'bold');
xlabel('Intensity values in PET');
ylabel('Intensity values in T2');

% --- Global title (optional) ---
sgtitle('Checkerboard Comparison & Joint Histograms', 'FontWeight', 'bold');

%% ============== 9. VISUALIZATION: 2D METRIC HEATMAPS ====================

% --- DWI peak indices ---
[~, idx_max_ncc_dwi] = max(NCC_DWI(:));
[~, idx_min_ssd_dwi] = min(SSD_DWI(:));
[~, idx_max_mi_dwi]  = max(MI_DWI(:));
[row_ncc_dwi, col_ncc_dwi] = ind2sub(size(NCC_DWI), idx_max_ncc_dwi);
[row_ssd_dwi, col_ssd_dwi] = ind2sub(size(SSD_DWI), idx_min_ssd_dwi);
[row_mi_dwi,  col_mi_dwi]  = ind2sub(size(MI_DWI),  idx_max_mi_dwi);

% --- PET peak indices ---
[~, idx_max_ncc_pet] = max(NCC_PET(:));
[~, idx_min_ssd_pet] = min(SSD_PET(:));
[~, idx_max_mi_pet]  = max(MI_PET(:));
[row_ncc_pet, col_ncc_pet] = ind2sub(size(NCC_PET), idx_max_ncc_pet);
[row_ssd_pet, col_ssd_pet] = ind2sub(size(SSD_PET), idx_min_ssd_pet);
[row_mi_pet,  col_mi_pet]  = ind2sub(size(MI_PET),  idx_max_mi_pet);

% --- Visualization style ---
bright_cyan = [0 0.8 1];

figure('Name', '2D Heatmaps of Registration Metrics', 'NumberTitle', 'off');

% --- SSD: T2 vs DWI ---
subplot(2,3,1);
imagesc(range, range, SSD_DWI); axis image; colormap hot; colorbar;
title('SSD T2 vs DWI');
xlabel('dx'); ylabel('dy'); set(gca, 'YDir', 'normal'); hold on;
plot(range(col_ssd_dwi), range(row_ssd_dwi), '.', 'Color', bright_cyan, 'MarkerSize', 25);

% --- NCC: T2 vs DWI ---
subplot(2,3,2);
imagesc(range, range, NCC_DWI); axis image; colormap hot; colorbar;
title('NCC T2 vs DWI');
xlabel('dx'); ylabel('dy'); set(gca, 'YDir', 'normal'); hold on;
plot(range(col_ncc_dwi), range(row_ncc_dwi), '.', 'Color', bright_cyan, 'MarkerSize', 25);

% --- MI: T2 vs DWI ---
subplot(2,3,3);
imagesc(range, range, MI_DWI); axis image; colormap hot; colorbar;
title('MI T2 vs DWI');
xlabel('dx'); ylabel('dy'); set(gca, 'YDir', 'normal'); hold on;
plot(range(col_mi_dwi), range(row_mi_dwi), '.', 'Color', bright_cyan, 'MarkerSize', 25);

% --- SSD: T2 vs PET ---
subplot(2,3,4);
imagesc(range, range, SSD_PET); axis image; colormap hot; colorbar;
title('SSD T2 vs PET');
xlabel('dx'); ylabel('dy'); set(gca, 'YDir', 'normal'); hold on;
plot(range(col_ssd_pet), range(row_ssd_pet), '.', 'Color', bright_cyan, 'MarkerSize', 25);

% --- NCC: T2 vs PET ---
subplot(2,3,5);
imagesc(range, range, NCC_PET); axis image; colormap hot; colorbar;
title('NCC T2 vs PET');
xlabel('dx'); ylabel('dy'); set(gca, 'YDir', 'normal'); hold on;
plot(range(col_ncc_pet), range(row_ncc_pet), '.', 'Color', bright_cyan, 'MarkerSize', 25);

% --- MI: T2 vs PET ---
subplot(2,3,6);
imagesc(range, range, MI_PET); axis image; colormap hot; colorbar;
title('MI T2 vs PET');
xlabel('dx'); ylabel('dy'); set(gca, 'YDir', 'normal'); hold on;
plot(range(col_mi_pet), range(row_mi_pet), '.', 'Color', bright_cyan, 'MarkerSize', 25);

%% ============== 10. VISUALIZATION: 3D METRIC SURFACES ===================

[X, Y] = meshgrid(range, range);
bright_cyan = [0 0.8 1];

figure('Name', '3D Surfaces of Registration Metrics (NCC, SSD, MI)', 'NumberTitle', 'off');

% === NCC ===
subplot(3,2,1);
surf(X, Y, NCC_DWI, 'EdgeColor', 'none'); hold on;
xlabel('dx'); ylabel('dy'); zlabel('NCC');
title('NCC between T2 and DWI');
colormap hot; colorbar; view(45, 30); grid on;
plot3(range(col_ncc_dwi), range(row_ncc_dwi), NCC_DWI(row_ncc_dwi, col_ncc_dwi), ...
    '.', 'Color', bright_cyan, 'MarkerSize', 25);

subplot(3,2,2);
surf(X, Y, NCC_PET, 'EdgeColor', 'none'); hold on;
xlabel('dx'); ylabel('dy'); zlabel('NCC');
title('NCC between T2 and PET');
colormap hot; colorbar; view(45, 30); grid on;
plot3(range(col_ncc_pet), range(row_ncc_pet), NCC_PET(row_ncc_pet, col_ncc_pet), ...
    '.', 'Color', bright_cyan, 'MarkerSize', 25);

% === SSD ===
subplot(3,2,3);
surf(X, Y, SSD_DWI, 'EdgeColor', 'none'); hold on;
xlabel('dx'); ylabel('dy'); zlabel('SSD');
title('SSD between T2 and DWI');
colormap hot; colorbar; view(45, 30); grid on;
plot3(range(col_ssd_dwi), range(row_ssd_dwi), SSD_DWI(row_ssd_dwi, col_ssd_dwi), ...
    '.', 'Color', bright_cyan, 'MarkerSize', 25);

subplot(3,2,4);
surf(X, Y, SSD_PET, 'EdgeColor', 'none'); hold on;
xlabel('dx'); ylabel('dy'); zlabel('SSD');
title('SSD between T2 and PET');
colormap hot; colorbar; view(45, 30); grid on;
plot3(range(col_ssd_pet), range(row_ssd_pet), SSD_PET(row_ssd_pet, col_ssd_pet), ...
    '.', 'Color', bright_cyan, 'MarkerSize', 25);

% === MI ===
subplot(3,2,5);
surf(X, Y, MI_DWI, 'EdgeColor', 'none'); hold on;
xlabel('dx'); ylabel('dy'); zlabel('MI');
title('MI between T2 and DWI');
colormap hot; colorbar; view(45, 30); grid on;
plot3(range(col_mi_dwi), range(row_mi_dwi), MI_DWI(row_mi_dwi, col_mi_dwi), ...
    '.', 'Color', bright_cyan, 'MarkerSize', 25);

subplot(3,2,6);
surf(X, Y, MI_PET, 'EdgeColor', 'none'); hold on;
xlabel('dx'); ylabel('dy'); zlabel('MI');
title('MI between T2 and PET');
colormap hot; colorbar; view(45, 30); grid on;
plot3(range(col_mi_pet), range(row_mi_pet), MI_PET(row_mi_pet, col_mi_pet), ...
    '.', 'Color', bright_cyan, 'MarkerSize', 25);

%% ============== 11. FINAL REPORT: REGISTRATION QUALITY ==================

generate_registration_report(I_T2_padded, I_DWI_padded, I_DWI_registered, 'T2-DWI', 128);
generate_registration_report(I_T2_padded, I_PET_padded, I_PET_registered, 'T2-PET', 128);

%% ============== 12. BAR CHART: METRIC SUMMARY ===========================

% DWI
mi_dwi_before  = MI(I_T2_padded, I_DWI_padded);
ncc_dwi_before = NCC(I_T2_padded, I_DWI_padded);
ssd_dwi_before = SSD(I_T2_padded, I_DWI_padded);
mi_dwi_after   = MI(I_T2_padded, I_DWI_registered);
ncc_dwi_after  = NCC(I_T2_padded, I_DWI_registered);
ssd_dwi_after  = SSD(I_T2_padded, I_DWI_registered);

% PET
mi_pet_before  = MI(I_T2_padded, I_PET_padded);
ncc_pet_before = NCC(I_T2_padded, I_PET_padded);
ssd_pet_before = SSD(I_T2_padded, I_PET_padded);
mi_pet_after   = MI(I_T2_padded, I_PET_registered);
ncc_pet_after  = NCC(I_T2_padded, I_PET_registered);
ssd_pet_after  = SSD(I_T2_padded, I_PET_registered);

% === Data to plot ===
values_MI  = [mi_dwi_before, mi_dwi_after; mi_pet_before, mi_pet_after];
values_NCC = [ncc_dwi_before, ncc_dwi_after; ncc_pet_before, ncc_pet_after];
values_SSD = [ssd_dwi_before, ssd_dwi_after; ssd_pet_before, ssd_pet_after];

% === labels ===
modality_names = {'DWI', 'PET'};

% === Plot ===
figure('Name', 'Registration Metrics by Type (Before vs After)', 'NumberTitle', 'off');

% -- MI
subplot(1,3,1);
b1 = bar(values_MI, 'grouped');
b1(1).FaceColor = [0.85 0.33 0.1];   % Before = dark orange
b1(2).FaceColor = [0.93 0.69 0.13];  % After  = yellow
set(gca, 'XTickLabel', modality_names);
ylabel('Mutual Information');
title('MI: Before vs After');
grid on;

% -- NCC
subplot(1,3,2);
b2 = bar(values_NCC, 'grouped');
b2(1).FaceColor = [0.3 0.75 0.93];   % Before = light blue
b2(2).FaceColor = [0.2 0.5 0.8];     % After  = dark blue
set(gca, 'XTickLabel', modality_names);
ylabel('Normalized Cross Correlation');
title('NCC: Before vs After');
grid on;

% -- SSD
subplot(1,3,3);
b3 = bar(values_SSD, 'grouped');
b3(1).FaceColor = [0.5 0.5 0.5];     % Before = grey
b3(2).FaceColor = [0.1 0.7 0.3];     % After  = green
set(gca, 'XTickLabel', modality_names);
ylabel('Sum of Squared Differences');
title('SSD: Before vs After');
grid on;
