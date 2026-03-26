function generate_registration_report(I_ref, I_mov_orig, I_mov_reg, name, numBins)
% Generate a detailed registration report between two images.
%
% I_ref         - Reference image (e.g., T2)
% I_mov_orig    - Moving image before registration (e.g., DWI, PET)
% I_mov_reg     - Registered image
% name          - Descriptive string for the modality (e.g., 'DWI', 'PET')
% numBins       - Number of bins for the joint histogram (e.g., 128)
% Author: Davide Stefanelli

    % Compute Mutual Information
    MI_before = MI(I_ref, I_mov_orig);
    MI_after  = MI(I_ref, I_mov_reg);

    % Compute joint histogram after registration
    H = compute_joint_histogram(I_ref, I_mov_reg, numBins);

    % Create the figure
    figure('Name', ['Registration Report - ', name], 'NumberTitle', 'off', 'Position', [100 100 1400 600]);

    % Subplot 1: reference image
    subplot(2, 3, 1);
    imagesc(I_ref);
    axis image on;  % show axes
    colormap(gca, 'gray');
    title('Image: Reference', 'FontWeight', 'bold');
    colorbar;

    % Subplot 2: registered image
    subplot(2, 3, 2);
    imagesc(I_mov_reg);
    axis image on;
    colormap(gca, 'gray');
    title(['Image: Registered', name], 'FontWeight', 'bold');
    colorbar;

    % Subplot 3: checkerboard overlay
    subplot(2, 3, 3);
    checkerboard_view(double(I_ref), double(I_mov_reg), 16);
    axis on;
    colormap(gca, 'gray');
    title('Checkerboard: Reference vs Registered', 'FontWeight', 'bold');
    colorbar;

    % Subplot 4: joint histogram visualization
    subplot(2, 3, [4 5]);
    imagesc(log(H + 1));
    axis on;
    colormap(gca, 'hot');
    colorbar;
    title('Joint Histogram (Log Scale)', 'FontWeight', 'bold');
    xlabel('Intensity values in REG');
    
    ylabel('Intensity values in REF');

    % Subplot 5: MI textual info
    subplot(2, 3, 6);
    axis off;
    text(0, 0.8, 'Mutual Information (MI):', 'FontSize', 12, 'FontWeight', 'bold');
    text(0, 0.6, sprintf('Before Registration: %.4f', MI_before), 'FontSize', 11);
    text(0, 0.4, sprintf('After Registration:  %.4f', MI_after), 'FontSize', 11);
    text(0, 0.2, ['Modality: ', name], 'FontSize', 11);
end

