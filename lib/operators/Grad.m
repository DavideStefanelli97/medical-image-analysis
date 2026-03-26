function f = Grad(Mat)
% Adapted from course-provided numerical stencil
[m n] = size(Mat);
f = sqrt(Dx(Mat).^2+Dy(Mat).^2); 
