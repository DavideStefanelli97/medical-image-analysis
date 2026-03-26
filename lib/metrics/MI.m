function mi = MI(I1, I2)
% MI Computes the Mutual Information between two images.
%
%   mi = MI(I1, I2) calculates the mutual information as:
%       MI = H(I1) + H(I2) - H(I1, I2)
%
%   Parameters:
%     I1, I2  - Input images
%
%   Output:
%     mi      - Scalar mutual information in bits
% Author: Davide Stefanelli

    mi = entropy(I1) + entropy(I2) - joint_entropy(I1, I2);
end
