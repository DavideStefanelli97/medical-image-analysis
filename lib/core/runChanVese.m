function [phi, area, numIter, phiHistory] = runChanVese(Image, phi0, maxIter, dt, ...
    mu, lam1, lam2, ni, displayStep, stopThresh, saveHistory)
% runChanVese - Chan-Vese level set segmentation (version with curve history saving)
%
% INPUTS:
%   Image        - 2D grayscale image to segment
%   phi0         - Initial level set function (same size as Image)
%   maxIter      - Maximum number of iterations
%   dt           - Evolution time step
%   mu           - Edge regularization weight (default: 1)
%   lam1         - Inner region fitting weight      (default: 1)
%   lam2         - Outer region fitting weight       (default: -1)
%   ni           - Balloon force                     (default: 0)
%   displayStep  - Save phi every this many iterations (default: 10)
%   stopThresh   - Threshold on area variation to stop (default: 1)
%   saveHistory  - Boolean: save phi every displayStep (default: true)
%
% OUTPUTS:
%   phi          - Final level set function
%   area         - Vector with inner area history (phi < 0)
%   numIter      - Actual iterations performed
%   phiHistory   - 3D array with phi saved every displayStep (if requested)
% Author: Davide Stefanelli

% ---------------------------
% Set default parameters
% ---------------------------
if nargin < 5 || isempty(mu),          mu = 1;         end
if nargin < 6 || isempty(lam1),        lam1 = 1;       end
if nargin < 7 || isempty(lam2),        lam2 = -1;      end
if nargin < 8 || isempty(ni),          ni = 0;         end
if nargin < 9 || isempty(displayStep), displayStep = 10; end
if nargin < 10 || isempty(stopThresh), stopThresh = 1; end
if nargin < 11 || isempty(saveHistory), saveHistory = true; end

% ---------------------------
% Initializations
% ---------------------------
phi = phi0;
area = zeros(1, maxIter);

% Preallocate phiHistory
[H, W] = size(Image);
nSteps = floor(maxIter / displayStep);
if saveHistory
    phiHistory = zeros(H, W, nSteps);
else
    phiHistory = [];
end

% save the initial curve (at step = 0)
saveIdx = 1;
phiHistory(:, :, saveIdx) = phi0;

% Gradient components (fixed at the beginning)
Fx = Dx(Grad(phi) ./ (abs(Grad(phi)) + eps));  % avoid division by zero
Fy = Dy(Grad(phi) ./ (abs(Grad(phi)) + eps));

% ---------------------------
% Time evolution
% ---------------------------
for i = 1:maxIter
    % Inner/outer masks
    Hi = (phi < 0);    % inside the curve
    He = (phi >= 0);   % outside the curve

    % Intensity averages
    I0i = Image .* Hi;
    I0e = Image .* He;
    c1 = sum(I0i(:)) / (sum(Hi(:)) + eps);  % mean inside
    c2 = sum(I0e(:)) / (sum(He(:)) + eps);  % mean outside

    % Update phi (as in the original code)
    phi = phi + dt .* ( ...
        mu * divergence(Fx, Fy) + ...
        ni + ...
        lam1 * (Image - c1).^2 + ...
        lam2 * (Image - c2).^2 );

    % Update area
    He = (phi < 0);  % update "inside" mask
    area(i) = sum(He(:));

    % Save phi every displayStep
    if saveHistory && mod(i, displayStep) == 0
        saveIdx = saveIdx + 1;
        phiHistory(:, :, saveIdx) = phi;
    end

    % Stopping condition (area convergence)
    if i > 5 && abs(area(i) - area(i-1)) < stopThresh
        area = area(1:i);  % truncate
        if saveHistory && mod(i, displayStep) ~= 0
            saveIdx = saveIdx + 1;
            phiHistory(:, :, saveIdx) = phi;
        end
        disp(['✓ Chan-Vese stopped at iteration ', num2str(i), ' (converged).']);
        break
    end
end

% Case: completed without convergence
if i == maxIter
    area = area(1:end);
    if saveHistory && mod(i, displayStep) ~= 0
        saveIdx = saveIdx + 1;
        phiHistory(:, :, saveIdx) = phi;
    end
end

% Trim phiHistory to the actual number of saved snapshots
if saveHistory
    phiHistory = phiHistory(:, :, 1:saveIdx);
end

numIter = i;

end


