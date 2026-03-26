function f = Gup(I,Fx,Fy)
% Adapted from course-provided numerical stencil
f=((Fx>0).*Dp_x(I) +(Fx<0).*Dm_x(I)).*Fx +((Fy>0).*Dp_y(I) +(Fy<0).*Dm_y(I)).*Fy ;
