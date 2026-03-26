function [phi, X, Y] = initLSFfrompoints( ...
        I, positions, numSamples, smoothingSigma)

% Build a smooth signed-distance level‐set from user points
% [phi,X,Y] = init...(I, positions, numSamples, smoothingSigma)
%   I               : grayscale image
%   positions (Nx2) : [x y] vertices
%   numSamples      : # points to sample on spline (e.g. 1000)
%   smoothingSigma  : sigma for imgaussfilt on phi (e.g. 1.0)
%
% If numSamples or smoothingSigma omitted, defaults are 1500, 0 (no filter).
% Author: Davide Stefanelli

    if nargin<3 || isempty(numSamples),     numSamples    = 1500; end
    if nargin<4 || isempty(smoothingSigma), smoothingSigma = 0;    end

    % ensure double image and size
    if ~isfloat(I), I = im2double(I); end
    [ny, nx] = size(I);

    % close polygon
    curveX = [positions(:,1); positions(1,1)];
    curveY = [positions(:,2); positions(1,2)];

    % closed cubic spline (Curve Fitting Toolbox)
    pts         = [curveX'; curveY'];
    splineCurve = cscvn(pts);
    tSamples    = linspace(splineCurve.breaks(1), ...
                           splineCurve.breaks(end), ...
                           numSamples);
    xySmooth    = ppval(splineCurve, tSamples);
    curveX_s    = xySmooth(1,:)';
    curveY_s    = xySmooth(2,:)';

    % rasterize into mask
    mask = poly2mask(curveX_s, curveY_s, ny, nx);

    % optional morpho‐smoothing on mask
    se          = strel('disk',1);
    mask_smooth = imopen(mask, se);
    mask_smooth = imclose(mask_smooth, se);

    % compute signed distance
    distOut = bwdist(mask_smooth);
    distIn  = bwdist(~mask_smooth);
    phi     = distOut - distIn;

    % optional Gaussian smoothing on phi
    if smoothingSigma>0
        phi = imgaussfilt(phi, smoothingSigma);
    end

    % coordinate grids
    [X, Y] = meshgrid(1:nx, 1:ny);
end
