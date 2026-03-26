function f = Dxx(Mat)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% f = Dxx(Mat)
%
% Second-order finite difference along x
%
% Input parameters:
% Mat := matrix to differentiate
%
% Adapted from course-provided numerical stencil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
[m n] = size(Mat);

if nargin == 1
   f = (Mat(1:m,[2:n n]) - 2.*Mat + Mat(1:m,[1 1:n-1])); 
else error('Usage: f = Dxx(Mat)');
end

