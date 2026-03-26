function H = entropy(I)
% ENTROPY Computes the Shannon entropy of a single image.
%
%   H = entropy(I) returns the entropy in bits of image I, computed using
%   256-bin normalized histogram. Input image is normalized to [0, 1].
%
%   Parameters:
%     I - Input image (uint8, uint16, double, etc.)
%
%   Output:
%     H - Scalar entropy value in bits
% Author: Davide Stefanelli

    % Convert and normalize
    I = double(I);
    I = (I - min(I(:))) / (max(I(:)) - min(I(:)) + eps);

    % Compute normalized histogram
    p = histcounts(I, 256, 'Normalization', 'probability');

    % Remove zero probabilities
    p = p(p > 0);

    % Compute entropy
    H = -sum(p .* log2(p));
end

