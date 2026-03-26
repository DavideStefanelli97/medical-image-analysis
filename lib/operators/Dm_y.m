function f =  Dm_y(Mat)  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% f =  Dm_y(Mat)
%
% Compute the backward finite difference along y
%
% Input parameters:
%
% Mat := matrix to differentiate
%
% Adapted from course-provided numerical stencil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[m n] = size(Mat);

if nargin == 1
    f = (Mat - Mat([1 1:m-1],1:n));
else error('Usage:  f = Dm_y(Mat)');
end