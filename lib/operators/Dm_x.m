function f =  Dm_x(Mat)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% f =  Dm_x(Mat)
%
% Compute the backward first derivative along x
%
% Input parameters
% Mat := matrix
%
% Adapted from course-provided numerical stencil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[m n] = size(Mat);
if nargin == 1
    f = (Mat - Mat(1:m,[1 1:n-1]));
else error('Usage:  f = Dm_x(Mat)');
end
