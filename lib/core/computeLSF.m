function [phi, X, Y, center] = computeLSF(varargin)
%
% computeLevelSetCircle - Compute the signed distance level set function for a circle.
%
% Syntax------------------------------------------------------------------
%   [phi, X, Y] = computeLSF('InputImage', img, 'InteractiveCenter', true, ...
%                                        'Radius', R, 'InsidePositive', true);
%   [phi, X, Y] = computeLSF('Domain', [xmin xmax ymin ymax], 'Center', [x_center, y_center], ...
%                                        'Radius', R, 'InsidePositive', true);
%   [phi, X, Y, center] = computeLSF(...);  % Also returns the center used to define the circle
%
%
% Description-------------------------------------------------------------
%   This function computes the signed distance function φ(x,y) representing the distance from
%   each point (x,y) to the boundary of a circle with radius R. The circle is defined by its
%   center and radius. The sign of φ is determined by the 'InsidePositive' flag.
%
%   There are two modes of operation:
%     1. Manual Domain Mode:
%        - The user supplies a 'Domain' and optionally a 'Center'.
%        - If no center is provided, the default is to use the center of the domain.
%
%     2. Image-Based Mode:
%        - The user supplies an 'InputImage'. The domain is automatically computed from the
%          image dimensions (X: 1 to width, Y: 1 to height).
%        - If 'InteractiveCenter' is set to true, the function displays the image and allows the
%          user to select the circle center using ginput. If not, and no 'Center' is provided,
%          the center is set to the center of the image.
%
%
% Inputs (Name-Value pairs)-----------------------------------------------
%   'InputImage'      - (Optional) The image from which to derive the domain. The image should
%                       be in double format (or will be converted via im2double) and normalized.
%                       Default is [].
%   'Domain'          - (Optional) 1x4 vector [xmin xmax ymin ymax] defining the spatial domain.
%                       Ignored if 'InputImage' is provided. Default is [1 200 1 200].
%   'Center'          - (Optional) 1x2 vector [x_center, y_center] specifying the center of the circle.
%                       If omitted, the center will be determined automatically.
%   'InteractiveCenter' - (Optional) Logical flag. If true and 'InputImage' is provided and no
%                       'Center' is specified, the function displays the image and lets the user
%                       click to choose the center. Default is false.
%   'Radius'          - Scalar defining the circle radius R. Must be > 0. Default is 50.
%   'InsidePositive'  - Logical flag. If true, φ is positive inside the circle and negative outside.
%                       Otherwise, the sign convention is inverted. Default is true.
%
% Outputs:----------------------------------------------------------------
%   phi    - Matrix of the signed distance values, with dimensions corresponding to the computed grid.
%   X, Y   - Meshgrid matrices for the x and y coordinates.
%   center - 1x2 vector [x_center, y_center] indicating the center of the circle used for φ.
%
%
% Example 1 (Manual Domain Mode)------------------------------------------
%   [phi, X, Y] = computeLSF('Domain', [1 300 1 300], 'Center', [150,150], ...
%                                        'Radius', 75, 'InsidePositive', true);
%   surf(X, Y, phi); shading interp; colormap jet; colorbar;
%
%
% Example 2 (Image-Based Mode with Interactive Center)--------------------
%   I = imread('example.jpg');
%   I = im2double(I);
%   [phi, X, Y, center] = computeLSF('InputImage', I, 'InteractiveCenter', true, ...
%                                        'Radius', 40, 'InsidePositive', true);
%   surf(X, Y, phi); shading interp; colormap jet; colorbar;
%
% Author: Davide Stefanelli

    % Setup input parser
    p = inputParser;
    
    % Define default parameters
    defaultInputImage = [];
    defaultDomain = [1 200 1 200];
    defaultCenter = []; % will be determined automatically if empty
    defaultInteractiveCenter = false;
    defaultRadius = 50;
    defaultInsidePositive = true;
    
    % Add parameters
    addParameter(p, 'InputImage', defaultInputImage);
    addParameter(p, 'Domain', defaultDomain, @(x) isnumeric(x) && numel(x)==4);
    addParameter(p, 'Center', defaultCenter, @(x) isempty(x) || (isnumeric(x) && numel(x)==2));
    addParameter(p, 'InteractiveCenter', defaultInteractiveCenter, @(x) islogical(x) || (isnumeric(x) && (x==0 || x==1)));
    addParameter(p, 'Radius', defaultRadius, @(x) isnumeric(x) && isscalar(x) && (x > 0));
    addParameter(p, 'InsidePositive', defaultInsidePositive, @(x) islogical(x) || (isnumeric(x) && (x==0 || x==1)));
    
    % Parse input arguments
    parse(p, varargin{:});
    
    inputImage = p.Results.InputImage;
    domain = p.Results.Domain;
    center = p.Results.Center;
    interactiveCenter = logical(p.Results.InteractiveCenter);
    R = p.Results.Radius;
    insidePositive = logical(p.Results.InsidePositive);
    
    % If an input image is provided, derive the domain from the image dimensions
    if ~isempty(inputImage)
        % Ensure the image is double and normalized
        if ~isa(inputImage, 'double')
            inputImage = im2double(inputImage);
        end
        
        [M, N, ~] = size(inputImage);
        domain = [1 N 1 M];  % x from 1 to width (N), y from 1 to height (M)
    end
    
    % Create meshgrid based on the determined domain
    x = linspace(domain(1), domain(2), domain(2) - domain(1) + 1);
    y = linspace(domain(3), domain(4), domain(4) - domain(3) + 1);
    [X, Y] = meshgrid(x, y);
    
    % Determine the center:
    % If center is empty and an input image is provided, check interactive option
    if isempty(center)
        if ~isempty(inputImage) && interactiveCenter

            fig = figure('Units', 'normalized', 'OuterPosition', [0 0 1 1], ...
                        'MenuBar', 'none', 'ToolBar', 'none', 'NumberTitle', 'off', ...
                        'WindowStyle', 'normal', 'Name', 'Select Center');
         
            axes('Position', [0 0 1 1]);
            imshow(inputImage, []);
            axis image; axis off;
            set(fig, 'Pointer', 'crosshair'); 
            
            title('Select the center for the level set function', 'FontSize', 18);
            [x_center, y_center] = ginput(1);
            close(fig);

        else
            % Default: use the center of the domain
            x_center = (domain(1) + domain(2)) / 2;
            y_center = (domain(3) + domain(4)) / 2;
        end
    else
        x_center = center(1);
        y_center = center(2);
    end

    % Save the effective center used
    center = [x_center, y_center];
    
    % Compute the Euclidean distance from each grid point to the chosen center
    dist = sqrt((X - x_center).^2 + (Y - y_center).^2);
    
    % Compute the signed distance function
    if insidePositive
        % Positive inside the circle (i.e., points inside have phi > 0)
        phi = R - dist;
    else
        % Positive outside the circle
        phi = dist - R;
    end
end
