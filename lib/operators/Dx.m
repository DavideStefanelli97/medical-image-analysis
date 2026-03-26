function f = Dx(Mat)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% f = Dx(Mat)
%
%  Centered finite difference along x
%
% Input parameters:
% Mat := matrix to differentiate
%
% Adapted from course-provided numerical stencil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
[m n] = size(Mat);

if nargin == 1
    f = (Mat(1:m,[2:n n]) - Mat(1:m,[1 1:n-1]))/2;
else error('Usage: Dx = Dx(Mat)');
end