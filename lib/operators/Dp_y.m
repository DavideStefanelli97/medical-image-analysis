function f =  Dp_y(Mat) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% f =  Dp_y(Mat)
%
% Compute the forward finite difference along y
%
% Input parameters:
%
% Mat := matrix to differentiate
%
% Adapted from course-provided numerical stencil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[m n] = size(Mat);

if nargin == 1
    f = (Mat([2:m m],1:n) - Mat);
else error('Usage:  f = Dp_y(Mat)');
end