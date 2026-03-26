function f =  Dp_x(Mat) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% f =  Dp_x(Mat)
%
% Compute the forward finite difference along x
%
% Input parameters:
%
% Mat := matrix to differentiate
%
% Adapted from course-provided numerical stencil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[m n] = size(Mat);

if nargin == 1
    f = (Mat(1:m,[2:n n]) - Mat);
else error('Usage:  f = Dp_x(Mat)');
end



    
