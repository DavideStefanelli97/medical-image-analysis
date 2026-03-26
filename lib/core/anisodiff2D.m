function diff_im = anisodiff2D(im, num_iter, delta_t, kappa, option)
% Author: Davide Stefanelli
    im = double(im);
    [rows, cols] = size(im);
    diff_im = im;

    for t = 1:num_iter
        % Gradients in four directions
        nablaN = [diff_im(1,:); diff_im(1:rows-1,:)] - diff_im;
        nablaS = [diff_im(2:rows,:); diff_im(rows,:)] - diff_im;
        nablaE = [diff_im(:,2:cols), diff_im(:,cols)] - diff_im;
        nablaW = [diff_im(:,1), diff_im(:,1:cols-1)] - diff_im;

        % Diffusion coefficients
        if option == 1
            cN = exp(-(nablaN / kappa).^2);
            cS = exp(-(nablaS / kappa).^2);
            cE = exp(-(nablaE / kappa).^2);
            cW = exp(-(nablaW / kappa).^2);
        elseif option == 2
            cN = 1 ./ (1 + (nablaN / kappa).^2);
            cS = 1 ./ (1 + (nablaS / kappa).^2);
            cE = 1 ./ (1 + (nablaE / kappa).^2);
            cW = 1 ./ (1 + (nablaW / kappa).^2);
        else
            error('Invalid diffusion option. Use 1 or 2.');
        end

        % Update the image
        diff_im = diff_im + delta_t * (...
            cN .* nablaN + cS .* nablaS + ...
            cE .* nablaE + cW .* nablaW);
    end
end


