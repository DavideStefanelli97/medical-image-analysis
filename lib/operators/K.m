function f = K(M)
% Adapted from course-provided numerical stencil

f = (Dxx(M).*(Dy(M).^2)-2.*Dy(M).*Dx(M).*(Dx(Dy(M)))+Dyy(M).*(Dx(M).^2) )./(((Dx(M).^2+Dy(M).^2).^(3/2))+1e-6);
