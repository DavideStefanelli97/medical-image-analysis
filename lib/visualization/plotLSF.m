function plotLSF(phi, X, Y, varargin)
%
% plotLSF - Visualize the Level Set Function in 3D and 2D.
%
% Syntax:
%   plotLSF(phi, X, Y)
%   plotLSF(phi, X, Y, 'Title3D', '3D Level Set', 'ZeroContourColor', 'r', ...
%                        'OverlayImage', img, 'ImageAlpha', 0.5);
%
% Description:
%   This function produces two subplots in one figure:
%   1. A 3D plot of the level set surface using surf, overlaid with contour3 lines.
%      This subplot uses colormap 'jet' with its own colorbar.
%   2. A 2D plot that displays the zero level set (phi = 0) as a contour line.
%      This subplot uses colormap 'gray' with its own colorbar. An underlying image 
%      can optionally be overlaid for reference.
%
% Inputs:
%   phi - Matrix representing the level set function.
%   X, Y - Meshgrid matrices corresponding to the coordinates of phi.
%
% Optional Name-Value Pair Arguments:
%   'Title3D'           - Title for the 3D plot. Default: 'Level Set Function 3D'.
%   'Title2D'           - Title for the 2D plot. Default: 'Zero Level Set Contour'.
%   'ContourLevels3D'   - Vector specifying the levels at which to draw contour lines 
%                         in 3D. Default: 20 equally spaced levels between min(phi) and max(phi).
%   'ZeroContourColor'  - Color for the zero level set contour in the 2D plot. Default: 'm'.
%   'OverlayImage'      - An optional image (matrix) to overlay on the 2D plot. The image
%                         should be in double format and normalized to [0, 1].
%   'ImageAlpha'        - Transparency for the overlay image (0 to 1). Default: 0.5.
%
% Example:
%   [phi, X, Y] = computeLSF('InputImage', I, 'InteractiveCenter', true, 'Radius', 75);
%   plotLSF(phi, X, Y, 'Title3D', '3D Level Set Visualization', ...
%                        'Title2D', 'Zero Level Set', 'ZeroContourColor', 'g');
% Author: Davide Stefanelli

    % Setup input parser
    p = inputParser;
    
    % Define default values for optional parameters
    defaultTitle3D = 'Level Set Function 3D';
    defaultTitle2D = 'Zero Level Set Contour';
    defaultContourLevels3D = linspace(min(phi(:)), max(phi(:)), 20);
    defaultZeroContourColor = 'm';
    defaultOverlayImage = [];
    defaultImageAlpha = 0.5;
    
    % Add parameters
    addParameter(p, 'Title3D', defaultTitle3D, @ischar);
    addParameter(p, 'Title2D', defaultTitle2D, @ischar);
    addParameter(p, 'ContourLevels3D', defaultContourLevels3D, @isnumeric);
    addParameter(p, 'ZeroContourColor', defaultZeroContourColor, @(x) ischar(x) || isnumeric(x));
    addParameter(p, 'OverlayImage', defaultOverlayImage);
    addParameter(p, 'ImageAlpha', defaultImageAlpha, @(x) isnumeric(x) && x>=0 && x<=1);
    
    % Parse input arguments
    parse(p, varargin{:});
    
    title3D = p.Results.Title3D;
    title2D = p.Results.Title2D;
    contourLevels3D = p.Results.ContourLevels3D;
    zeroContourColor = p.Results.ZeroContourColor;
    overlayImage = p.Results.OverlayImage;
    % imageAlpha = p.Results.ImageAlpha;  % not used in this version
    
    %% 3D Visualization: Surface and Contour3
    figure('Name', 'LSF (start)', 'NumberTitle', 'off');
    
    % Create first axes for the 3D plot
    ax1 = subplot(121);
    
    % Plot the level set function surface
    surf(X, Y, phi, 'EdgeColor', 'none');
    hold on;
    % Overlay contour lines on the surface
    contour3(X, Y, phi, contourLevels3D, 'k');
    % Highlight the zero level set contour
    contour3(X, Y, phi, [0 0], zeroContourColor, 'LineWidth', 3);
    
    % Improve visualization aesthetics
    shading interp;
    colormap(ax1, jet);    % Set 'jet' colormap for the 3D plot
    colorbar(ax1);         % Add colorbar for the 3D plot
    camlight headlight;
    lighting gouraud;
    xlabel('X-axis');
    ylabel('Y-axis');
    zlabel('\phi(x,y)');
    title(title3D);
    hold off;
    
    % Modern MATLAB (R2019b+) handles per-axes colormaps natively
    
    %% 2D Visualization: Zero Level Set Contour
    % Create second axes for the 2D plot
    ax2 = subplot(122);
    
    % If an overlay image is provided, display it
    if ~isempty(overlayImage)
        imagesc(X(1,:), Y(:,1), overlayImage);
        axis image;
        hold on;
    else
        imagesc(X(1,:), Y(:,1), zeros(size(phi)));
        axis image;
        hold on;
    end
    
    % Plot the zero level set contour
    contour(X, Y, phi, [0 0], 'LineWidth', 2, 'LineColor', zeroContourColor);
    xlabel('X-axis');
    ylabel('Y-axis');
    title(title2D);
    grid on;
    hold off;
    
    % Set 'gray' colormap for the 2D plot and add its colorbar
    colormap(ax2, gray);
    colorbar(ax2);
end
