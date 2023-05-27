from diffractsim import MonochromaticField, mm, nm, cm

F = MonochromaticField(
    wavelength=632.8 * nm, extent_x=5.6 * mm, extent_y=5.6 * mm, Nx=500, Ny=500
)

F.add_aperture_from_image(
    "F:\PJ test\IMG_0657.jpg", pad=(10 * mm, 10 * mm), Nx=1400, Ny=1400
)

rgb = F.compute_colors_at(80*cm)
F.plot(rgb, xlim=[-7, 7], ylim=[-7, 7])