%% =================== PROJECT: ROTATIONAL REGISTRATION ===================
%  GOAL:
%  This script aligns two images (MRI_T2 and its rotated version) using
%  rotation-only registration, optimizing similarity metrics (NCC, SSD).
%
%  PROCESS OVERVIEW:
%  • Load original and rotated DICOM images.
%  • Sweep rotation angles and compute metrics (NCC, SSD, MI).
%  • Identify best angle for alignment.
%  • Apply rotation and compare results.
%
%  NOTE:
%  This example focuses on rigid rotation registration only.
%  ========================================================================

%% ============== 1. INITIALIZATION =======================================

clc; clear; close all;

% Initialize project paths
scriptDir = fileparts(mfilename('fullpath'));
run(fullfile(scriptDir, '..', '..', 'setup.m'));

%% ============== 2. LOAD DICOM IMAGES ====================================

% Load fixed T2-weighted MRI image
info_T2 = dicominfo(fullfile(PROJECT_ROOT, 'data', 'MRI_T2.dcm'));
I_T2 = dicomread(info_T2);

% Load rotated version of T2 image
info_T2_rot = dicominfo(fullfile(PROJECT_ROOT, 'data', 'MRI_T2_rot.dcm'));
I_T2_rot = dicomread(info_T2_rot);

% Extract pixel spacing
ps_T2 = info_T2.PixelSpacing;

% Display dimensions
fprintf('--- Image Sizes ---\n');
fprintf('T2        : %d × %d\n', size(I_T2,1), size(I_T2,2));
fprintf('T2_rot    : %d × %d\n\n', size(I_T2_rot,1), size(I_T2_rot,2));

% Visualize input images
image_viewer(I_T2, 'MRI T2 (Fixed)', false, ps_T2);
image_viewer(I_T2_rot, 'MRI T2 (Rotated)', false, ps_T2);

%% ============== 3. ROTATION PARAMETER SWEEP =============================

rotation_step = 0.5;                      % in degrees
angles = 0:rotation_step:359.5;           % full sweep
N = length(angles);

SSD_rot = zeros(1, N);
NCC_rot = zeros(1, N);
MI_rot  = zeros(1, N);

for i = 1:N
    angle = angles(i);
    rotated = imrotate(I_T2_rot, angle, 'bilinear', 'crop');
    SSD_rot(i) = SSD(I_T2, rotated);
    NCC_rot(i) = NCC(I_T2, rotated);
    MI_rot(i)  = MI(I_T2, rotated);
end

%% ============== 4. OPTIMAL ROTATION SELECTION ===========================

[~, idx_max_ncc] = max(NCC_rot);
[~, idx_min_ssd] = min(SSD_rot);
[~, idx_max_mi]  = max(MI_rot);

best_angle_ncc = angles(idx_max_ncc);
best_angle_ssd = angles(idx_min_ssd);
best_angle_mi  = angles(idx_max_mi);

% Apply optimal rotation (e.g., based on NCC)
I_T2_rot_registered = imrotate(I_T2_rot, best_angle_ncc, 'bilinear', 'crop');

% Display summary
fprintf('===========================================================\n');
fprintf('Best rotation angle (NCC): %.1f°\n', best_angle_ncc);
fprintf('Best rotation angle (SSD): %.1f°\n', best_angle_ssd);
fprintf('Best rotation angle (MI) : %.1f°\n', best_angle_mi);
fprintf('===========================================================\n\n');

%% ============== 5. PLOT METRICS ACROSS ROTATION ANGLES ==================

figure('Name', 'Metric Trends Across Rotation Angles', 'NumberTitle', 'off');

% -- MI
subplot(1,3,1);
plot(angles, MI_rot, 'Color', [0.93 0.69 0.13], 'LineWidth', 2); hold on; % yellow
plot(best_angle_mi, MI_rot(idx_max_mi), 'o', 'MarkerSize', 8, 'LineWidth', 1.5, 'Color', [0.85 0.33 0.1]); % orange
title('Mutual Information');
xlabel('Rotation Angle (°)'); ylabel('MI');
grid on;

% -- NCC
subplot(1,3,2);
plot(angles, NCC_rot, 'Color', [0.2 0.5 0.8], 'LineWidth', 2); hold on;   % dark blue
plot(best_angle_ncc, NCC_rot(idx_max_ncc), 'o', 'MarkerSize', 8, 'LineWidth', 1.5, 'Color', [0.3 0.75 0.93]); % light blue
title('Normalized Cross-Correlation');
xlabel('Rotation Angle (°)'); ylabel('NCC');
grid on;

% -- SSD
subplot(1,3,3);
plot(angles, SSD_rot, 'Color', [0.1 0.7 0.3], 'LineWidth', 2); hold on;   % green
plot(best_angle_ssd, SSD_rot(idx_min_ssd), 'o', 'MarkerSize', 8, 'LineWidth', 1.5, 'Color', [0.5 0.5 0.5]);   % grey
title('Sum of Squared Differences');
xlabel('Rotation Angle (°)'); ylabel('SSD');
grid on;

%% ============== 6. FINAL VISUAL COMPARISON ==============================

generate_registration_report(I_T2, I_T2_rot, I_T2_rot_registered, 'T2 vs Rotated T2', 128);

%% ============== 7. BAR CHART: METRIC SUMMARY BEFORE vs AFTER ============

% === Compute metrics ===
mi_before  = MI(I_T2, I_T2_rot);
ncc_before = NCC(I_T2, I_T2_rot);
ssd_before = SSD(I_T2, I_T2_rot);

mi_after   = MI(I_T2, I_T2_rot_registered);
ncc_after  = NCC(I_T2, I_T2_rot_registered);
ssd_after  = SSD(I_T2, I_T2_rot_registered);

% === Labels ===
xtick_label = {'T2 vs T2_{rot}'};
legend_labels = {'Before', 'After'};

figure('Name', 'Registration Metrics: Before vs After', 'NumberTitle', 'off');

% === MI ===
subplot(1,3,1);
b1 = bar([mi_before, mi_after], 'grouped');
b1.FaceColor = 'flat';
b1.CData = [0.85 0.33 0.1;  % Before = dark orange
            0.93 0.69 0.13]; % After = yellow
set(gca, 'XTick', 1);
set(gca, 'XTickLabel', xtick_label);
ylabel('Mutual Information');
title('MI: Before vs After');
grid on;

% === NCC ===
subplot(1,3,2);
b2 = bar([ncc_before, ncc_after], 'grouped');
b2.FaceColor = 'flat';
b2.CData = [0.3 0.75 0.93;   % Before = light blue
            0.2 0.5 0.8];    % After = dark blue
set(gca, 'XTick', 1);
set(gca, 'XTickLabel', xtick_label);
ylabel('Normalized Cross Correlation');
title('NCC: Before vs After');
grid on;

% === SSD ===
subplot(1,3,3);
b3 = bar([ssd_before, ssd_after], 'grouped');
b3.FaceColor = 'flat';
b3.CData = [0.5 0.5 0.5;     % Before = grey
            0.1 0.7 0.3];    % After = green
set(gca, 'XTick', 1);
set(gca, 'XTickLabel', xtick_label);
ylabel('Sum of Squared Differences');
title('SSD: Before vs After');
grid on;

