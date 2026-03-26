function plotEvolution(Image, phiHistory, pixelSpacing, mainTitle, fig_number)
% plotEvolution - Dynamically visualize the evolution of a Chan-Vese segmentation curve.
%
% This function plots the step-by-step evolution of a level set function 
% representing a segmentation boundary (e.g., from a Chan-Vese algorithm).
% It also computes and plots the evolution of the segmented area over time.
%
% PARAMETERS:
% -----------
% Image : 2D numeric matrix
%     The original grayscale image over which the segmentation evolves.
%
% phiHistory : 3D numeric array
%     A 3D matrix containing the level set function values for each iteration.
%     Dimensions: [Height, Width, numFrames], where each slice phi(:,:,k)
%     represents the level set function at iteration k.
%
% pixelSpacing : 1x2 vector [dy, dx]
%     The physical size of a pixel along y and x axis respectively (e.g., in mm).
%     Used to compute area in physical units (e.g., mm²).
%
% mainTitle : string or char
%     A main identifier string used in figure titles to indicate the segmentation context.
%
% fig_number : scalar integer
%     The number used to identify the figure window for the evolution plot (e.g., figure(1)).
%     This allows for figure reuse or managing multiple plots programmatically.
%
% OUTPUT:
% -------
% This function creates a series of figures:
%   - A single figure window (with ID fig_number) for dynamic visualization of the segmentation boundary.
%   - A second summary figure containing:
%     - the final segmentation boundary
%     - the evolution plot of the segmented area
%     - a textual box summarizing the final area and total iterations
%
% USAGE EXAMPLE:
% --------------
% >> plotEvolution(I, phiSequence, [0.5 0.5], 'Liver Segmentation', 3)
% This would show the evolution using figure 3 and display final statistics.
% Author: Davide Stefanelli

% Initialize and precompute
[~, ~, numFrames] = size(phiHistory);
dy = pixelSpacing(1);
dx = pixelSpacing(2);
pixelArea = dy * dx;
areaInTime = zeros(1, numFrames);

% --- Dynamic visualization of curve evolution using specified figure
figure(fig_number); 
sgtitle(sprintf('EVOLUTION - %s', mainTitle), 'FontSize', 14, 'FontWeight', 'bold');

for k = 1:numFrames
    phi_k = phiHistory(:,:,k);
    figure(fig_number)
    imagesc(Image); colormap(gray); axis image off; hold on;
    contour(phi_k, [0 0], 'LineWidth', 1.5, 'LineColor', 'g');
    hold off;

    % Compute area for current frame
    mask = phi_k < 0;
    areaInTime(k) = sum(mask(:)) * pixelArea;

    drawnow;
    pause(0.5);  % Adjust speed of visual update
end

% --- Final results figure (independent of fig_number)
finalPhi = phiHistory(:,:,end);
finalMask = finalPhi < 0;
finalArea_px = sum(finalMask(:));
finalArea_mm = finalArea_px * pixelArea;

figure('Color','w');
sgtitle(sprintf('FINAL RESULTS - %s', mainTitle), 'FontSize', 16, 'FontWeight', 'bold');

subplot(1,2,1);
imagesc(Image); colormap(gray); axis image off; hold on;
contour(finalPhi, [0 0], 'LineWidth', 2, 'LineColor', 'g');
colorbar;
title('Final contour of the segmentation', 'FontSize', 14);
legend('Segmentation contour', 'Location', 'best');

subplot(1,2,2);
plot(1:numFrames, areaInTime, 'LineWidth', 2, 'Color', [0.85 0.33 0.10]);
grid on;
xlabel('Iteration', 'FontSize', 12);
ylabel('Area [mm²]', 'FontSize', 12);
title('Area evolution over time', 'FontSize', 14);
legend('Area', 'Location', 'best');

txt = sprintf('Final area [px]: %.2f\nFinal area [mm²]: %.2f\nTotal iterations: %d', ...
              finalArea_px, finalArea_mm, numFrames);
text(0.05, 0.95, txt, ...
     'Units', 'normalized', ...
     'FontSize', 12, ...
     'BackgroundColor', 'w', ...
     'EdgeColor', 'k', ...
     'VerticalAlignment', 'top');
end
