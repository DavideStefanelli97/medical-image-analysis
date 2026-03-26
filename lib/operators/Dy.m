function f = Dy(Mat)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% f = Dy(Mat)
%
%  Centered finite difference along y
%
% Input parameters:
% Mat := matrix to differentiate
%
% Adapted from course-provided numerical stencil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[m n] = size(Mat);

if nargin == 1
   f = (Mat([2:m m],1:n) - Mat([1 1:m-1],1:n))/2; 
else error('Usage: Dy = Dy(Mat)');
end