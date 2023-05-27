close('all')
clear('all')
_lambda = 0.6e-6
delta = 10 * _lambda
z = 0.07
M = 512
c = mslice[1:M]
r = mslice[1:M]
[C, R] = meshgrid(c, r)
THOR = ((R - M / 2 - 1) **elpow** 2 + (C - M / 2 - 1) **elpow** 2) **elpow** 0.5
RR = THOR *elmul* delta
OB = zeros(M)
for a in mslice[1:M]:
    for b in mslice[1:M]:
        if RR(a, b) <= 5 * 10 ** -4:        
            OB(a, b).lvalue = 1
        end
    end
end
QP=exp(1*pi/_lambda/z*elmul*(RR*elmul**2))
FD = fftshift(fft2(fftshift(OB *elmul* QP)))
FD = abs(FD)
FD = FD / max(max(FD))
figure 
imshow(OB)

title(mstring('Circular aperture'))
figure
imshow(FD)

title(mstring('Modulus of the Fresnel diffraction pattern'))