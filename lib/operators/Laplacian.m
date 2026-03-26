%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   f = Laplacian(Matrix)              %
% Adapted from course-provided numerical stencil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f = laplacian(Mat) 
[m n] = size(Mat);
f = Dxx(Mat)+Dyy(Mat); 
