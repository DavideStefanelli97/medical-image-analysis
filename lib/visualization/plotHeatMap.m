function plotHeatMap(metric_map, range, best_row, best_col, metric_name)
% plotHeatMap - Visualizes the heatmap of the selected similarity metric
%
% Inputs:
%   metric_map  - 2D matrix of similarity values
%   range       - Vector of pixel shifts (e.g., -25:25)
%   best_row    - Row index of optimal shift in metric_map
%   best_col    - Column index of optimal shift in metric_map
%   metric_name - String: name of the metric ('NCC', 'SSD', 'MI')
% Author: Davide Stefanelli

    bright_cyan = [0 0.8 1];  % Highlight color

    figure('Name', ['Heatmap - ', upper(metric_name)], 'NumberTitle', 'off');
    imagesc(range, range, metric_map);
    axis image; colormap hot; colorbar;
    title([upper(metric_name), ' Heatmap']);
    xlabel('dx'); ylabel('dy');
    set(gca, 'YDir', 'normal'); hold on;

    % Overlay optimal point
    plot(range(best_col), range(best_row), '.', 'Color', bright_cyan, 'MarkerSize', 25);
end
