%% ============================= PROJECT OVERVIEW ==============================
%  GOAL:
%  This script performs 3D segmentation of the left atrium (LA) from a stack
%  of MRI slices contained in 'patient5.mat' using the Chan–Vese model.
%  The trabeculae are included in the segmented region.
%
%  PROCESS OVERVIEW:
%  • Load and visualize the 3D MRI volume
%  • Preprocessing (normalization + anisotropic diffusion)
%  • Slice-by-slice Chan–Vese segmentation with level-set evolution
%  • Morphological post-processing of each slice
%  • Area and total volume estimation (in mm² and mm³)
%  • 3D mesh reconstruction using Iso2Mesh (via `binsurface`)
%
% =============================================================================

%% ============================= 1. INITIALIZATION =============================
clc; clear; close all;

% Initialize project paths
scriptDir = fileparts(mfilename('fullpath'));
run(fullfile(scriptDir, '..', '..', 'setup.m'));

%% =========================== 2. LOAD MRI VOLUME ==============================
load(fullfile(PROJECT_ROOT, 'data', 'patient5.mat'));  % Contains res.imm (volume) and res.info.{ps,st}

volume_image     = res.imm;
pixel_spacing    = res.info.ps;    % [dx, dy] in mm
slice_thickness  = res.info.st;    % dz in mm

[nx, ny, nz] = size(volume_image);

fprintf('\n================ MRI VOLUME INFO ================\n');
fprintf('Volume size               : %d x %d x %d\n', nx, ny, nz);
fprintf('Pixel spacing             : %.2f mm × %.2f mm\n', pixel_spacing(1), pixel_spacing(2));
fprintf('Slice thickness           : %.2f mm\n', slice_thickness);
fprintf('=================================================\n');

% Visualize middle slice
mid_slice = round(nz / 2);
image_viewer(volume_image(:,:,mid_slice), ...
    sprintf('Mid Slice — patient5.mat (Slice %d)', mid_slice), true, pixel_spacing);

%% ======================= 3. DEFINE SLICE RANGE & PARAMETERS ===================
slice_range = 9:35;
volume_cropped = volume_image(:,:,slice_range);
num_slices = length(slice_range);

% Allocate memory
volume_filtered = zeros(nx, ny, num_slices);
PHI     = zeros(nx, ny, num_slices);         % Level-set function
PHI_bin = false(nx, ny, num_slices);         % Final binary masks
area_mm2 = zeros(1, num_slices);             % Area per slice (mm²)

% Chan–Vese and preprocessing parameters
mu = 0.5; 
lambda1 = 30; 
lambda2 = -30; 
ni = 0.0;
epsilon = 1e-6; 
max_iterations = 100; 
check_interval = 5;
time_step = 1; 
radius = 3;

% Anisotropic diffusion
num_iter = 5; 
delta_t = 0.1; 
kappa = 15; 
option = 2;

% Interactive seed update frequency
update_center_every_n_slices = 10;

fprintf('\n=== Chan–Vese Segmentation on %d Slices ===\n', num_slices);

%% ===================== 4. SLICE-BY-SLICE SEGMENTATION =========================

for i = 1:num_slices
    slice_id = i + slice_range(1) - 1;
    fprintf('→ Processing slice %d...\n', slice_id);

    % --- Select new center every N slices
    if mod(i - 1, update_center_every_n_slices) == 0
        figure; imagesc(volume_cropped(:,:,i)); colormap gray; axis image;
        title(sprintf('Slice %d — Select LA center', slice_id));
        [x, y] = ginput(1); x = round(x); y = round(y);
        center = [x, y]; close;
        fprintf('✓ New seed: (x = %d, y = %d)\n', x, y);
    end

    % --- Preprocessing
    slice = mat2gray(double(volume_cropped(:,:,i)));
    Image = anisodiff2D(slice, num_iter, delta_t, kappa, option);

    % --- Level-set initialization
    phi = computeLSF('Domain', [1 ny 1 nx], ...
                     'Center', center, ...
                     'Radius', radius, ...
                     'InsidePositive', false);

    % --- Chan–Vese evolution
    segmented_area = zeros(1, max_iterations);
    for iter = 1:max_iterations
        [phi_x, phi_y] = gradient(phi);
        normGrad = sqrt(phi_x.^2 + phi_y.^2 + epsilon);
        Nx = phi_x ./ normGrad; Ny = phi_y ./ normGrad;
        curvature = divergence(Nx, Ny);

        inside  = (phi < 0);
        outside = ~inside;
        c1 = sum(Image(inside)) / (sum(inside(:)) + epsilon);
        c2 = sum(Image(outside)) / (sum(outside(:)) + epsilon);

        phi = phi + time_step * (mu * curvature + ni + ...
              lambda1 * (Image - c1).^2 + lambda2 * (Image - c2).^2);

        segmented_area(iter) = nnz(phi < 0);

        % Early stopping if area stabilizes
        if iter > check_interval
            delta_area = abs(segmented_area(iter) - segmented_area(iter - check_interval)) ...
                         / (segmented_area(iter) + epsilon);
            if delta_area < 0.01
                break;
            end
        end
    end

    % --- Post-processing
    se = strel('disk', 9);
    mask = phi < 0;
    mask_eroded = imerode(mask, se);
    L = bwlabel(mask_eroded);
    label_id = L(y, x);
    cleaned = imdilate(L == label_id, se);
    final_mask = imfill(cleaned, 'holes');

    % --- Store results
    PHI(:,:,i)     = phi;
    PHI_bin(:,:,i) = final_mask;
    area_mm2(i)    = nnz(final_mask) * prod(pixel_spacing);

    fprintf('✓ Slice %d segmented (Area = %.2f mm²)\n', slice_id, area_mm2(i));
end

%% ======================= 5. SLICE-WISE VISUALIZATION ==========================
fprintf('\n=== Final Overlay: φ vs Post-Processed Mask ===\n');

gif_path = fullfile(PROJECT_ROOT, 'results', 'seg_left_atrium_3d', 'segmentation_slices.gif');

for i = 1:num_slices
    slice_id = i + slice_range(1) - 1;
    figure(500); clf;
    imagesc(volume_cropped(:,:,i)); colormap gray; axis image off; hold on;
    contour(PHI(:,:,i), [0 0], 'b', 'LineWidth', 1.0);           % φ (raw)
    contour(PHI_bin(:,:,i), [0.5 0.5], 'c--', 'LineWidth', 1.5); % cleaned
    title(sprintf('Slice %d — φ (blue) vs mask (light blue --)', slice_id));
    drawnow;

    % Export frame to animated GIF
    frame = getframe(gcf);
    im = frame2im(frame);
    [A, map] = rgb2ind(im, 256);
    if i == 1
        imwrite(A, map, gif_path, 'gif', 'LoopCount', Inf, 'DelayTime', 0.5);
    else
        imwrite(A, map, gif_path, 'gif', 'WriteMode', 'append', 'DelayTime', 0.5);
    end

    pause(0.3);
end
fprintf('✓ GIF saved to: %s\n', gif_path);

%% ========================== 6. 3D MESH RECONSTRUCTION =========================
fprintf('\n=== 3D Mesh Reconstruction of Left Atrium ===\n');
[node, elem] = binsurface(PHI_bin);

% Convert voxel indices to mm
node(:,1) = node(:,1) * pixel_spacing(2);  % x
node(:,2) = node(:,2) * pixel_spacing(1);  % y
node(:,3) = node(:,3) * slice_thickness;   % z

% Display 3D mesh
figure('Name','3D Mesh — Left Atrium');
plotmesh(node, elem, ...
    'facecolor', 'b', ...
    'edgecolor', 'none', ...
    'facealpha', 0.9);
axis equal off;
camlight headlight;
title('3D Reconstruction — Left Atrium');

% Compute and report final volume
Volume_mm3 = sum(area_mm2) * slice_thickness;
fprintf('✓ Total segmented LA volume: %.2f mm³\n', Volume_mm3);

%% =========================== 7. COMMAND WINDOW REPORT =========================
fprintf('\n=================== SEGMENTATION SUMMARY ===================\n');
fprintf('Number of segmented slices    : %d\n', num_slices);
fprintf('Average LA area per slice     : %.2f mm²\n', mean(area_mm2));
fprintf('Total segmented volume (LA)   : %.2f mm³\n', Volume_mm3);
fprintf('================================================================\n');
