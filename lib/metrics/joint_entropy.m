function H12 = joint_entropy(I1, I2)
% JOINT_ENTROPY Computes the joint entropy between two images.
%
%   H12 = joint_entropy(I1, I2) computes the joint entropy of I1 and I2
%   using a 256-bin normalized joint histogram.
%
%   Parameters:
%     I1, I2  - Input images
%
%   Output:
%     H12     - Scalar joint entropy value in bits
% Author: Davide Stefanelli

     % Compute joint histogram
    H = compute_joint_histogram(I1, I2, 256);

    % Normalize to get joint probability distribution
    Pxy = H / sum(H(:));

    % Remove zero entries to avoid log(0)
    Pxy = Pxy(Pxy > 0);

    % Compute joint entropy
    H12 = -sum(Pxy .* log2(Pxy));
end


