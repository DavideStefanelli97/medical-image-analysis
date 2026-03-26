function ssdval = SSD(I1, I2)
% Author: Davide Stefanelli
    ssdval = sum(sum((I1-I2).^2));
end