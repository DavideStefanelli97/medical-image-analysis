function H = compute_joint_histogram(I1, I2, numBins)
% COMPUTE_JOINT_HISTOGRAM - Computes the joint histogram of two grayscale images.
%
% Inputs:
%   I1, I2   - Images of same size
%   numBins - Number of intensity bins
%
% Output:
%   H       - Joint histogram (numBins x numBins)
% Author: Davide Stefanelli

    % Check che le dimensioni siano uguali
    if ~isequal(size(I1), size(I2))
        error('Images must have the same dimensions.');
    end

    I1 = double(I1);
    I2 = double(I2);

    % Normalizzazione su [0,1]
    I1 = I1 - min(I1(:));
    I2 = I2 - min(I2(:));
    r1 = max(I1(:)); if r1 == 0, r1 = 1; end
    r2 = max(I2(:)); if r2 == 0, r2 = 1; end
    I1 = I1 / r1;
    I2 = I2 / r2;

    % Quantizzazione in [1, numBins]
    Q1 = floor(I1 * (numBins - 1)) + 1;
    Q2 = floor(I2 * (numBins - 1)) + 1;

    % Protezione da fuori range
    Q1 = max(min(Q1, numBins), 1);
    Q2 = max(min(Q2, numBins), 1);

    % Istogramma con accumarray
    idx = [Q2(:), Q1(:)];
    H = accumarray(idx, 1, [numBins, numBins]);

    % Se per qualche ragione accumarray restituisce vuoto, forza uno zero
    if isempty(H)
        H = zeros(numBins, numBins);
    end
end
