close(mstring('all'), mstring('clear'), mstring('all'))
la1 = 0.6 * 10 ** -6 # wavelength, unit:m
delta = 10 * la1  # sampling period,unit:m
z = 0.07  # propagation distance; m
M = 512  # space size
c = mslice[1:M]
r = mslice[1:M]
[C, R] = meshgrid(c, r)
THOR = ((R - M / 2 - 1) ** elpow ** 2 + (C - M / 2 - 1) ** elpow ** 2) ** elpow ** 0.5
RR = THOR * elmul * delta
OB = zeros(M)  # Object
for a in mslice[1:M]:
    for b in mslice[1:M]:
        if RR(a, b) <= 5 * 10 ** -4:  # aperture radius unit:m
            OB(a, b).lvalue = 1
        end
    end
end

FD = fftshift(fft2(fftshift(OB * elmul * QP)))
FD = abs(FD)
FD = FD / max(max(FD))
figure
imshow(OB)

title(mstring('Circular aperture'))
figure
imshow(FD)

title(mstring('Modulus of the Fresnel diffraction pattern'))
