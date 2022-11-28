using CairoMakie
using Colors

include("./gruv_colours.jl");

## Generate colourmap for gruvbox blue - white - red

# Use hues and Colors.diverging_palette
#huemap(c::Color) = atand((sqrt(3)*(c.g-c.b)),(2*c.r - c.g - c.b))
#colmap = Colors.diverging_palette(360-huemap(blue), huemap(red) ; dcolor1=blue, dcolor2=red)

# Use range (twice) (better result)
colmap = [range(blue, white, 25)..., range(white, red, 25)...]

const WIDTH::Int16 = 3840
const HEIGHT::Int16 = 2160

RATIO = WIDTH/HEIGHT

temps = readlines("./annual_temp.txt")
ntemps = length(temps)
yrs = Vector{Int16}(undef, ntemps)
anoms = Vector{Float32}(undef, ntemps)

for (i, temp) in enumerate(temps)
    yr, anom, _ = split(temp, ",")
    yrs[i] = parse(Int16, yr)
    anoms[i] = parse(Float32,anom)
end

yrs_from_0 = yrs .- yrs[1]

## Set axis scale so that points are 1:1
xlims = (-ntemps, ntemps)
ylim_val = 0.5f0*(xlims[2]-xlims[1])/RATIO
ylims2 = (-ylim_val, ylim_val)
ylims = (-ntemps, ntemps)

## Climate Rectangle
F = Figure(
    resolution = (WIDTH, HEIGHT),
    figure_padding = 0,
    backgroundcolor = black,
)

Ax = Axis(
    F[1, 1],
    #aspect=1,
    backgroundcolor = black,
    limits = (xlims, ylims),
)

hidespines!(Ax)
hidedecorations!(Ax)

a = poly!(
    [Rect(-i, -i, 2i, 2i) for i in reverse(eachindex(anoms))],
#    [Circle(Point2f(0f0, 0f0), i) for i in reverse(eachindex(anoms))],
    color=reverse(anoms),
    colormap = colmap,
)

save("./figs/climate_square.png", F)

Ax.limits = ((0, ntemps), (0, 1))
save("./figs/climate_line.png", F)

## Make circle version
F = Figure(
    resolution = (WIDTH, HEIGHT),
    figure_padding = 0,
    backgroundcolor = black,
)

Ax = Axis(
    F[1, 1],
    backgroundcolor = black,
    limits = (xlims, ylims2),
)

hidespines!(Ax)
hidedecorations!(Ax)

a = poly!(
#    [Rect(-i, -i, 2i, 2i) for i in reverse(eachindex(anoms))],
    [Circle(Point2f(0f0, 0f0), i) for i in reverse(eachindex(anoms))],
    color=reverse(anoms),
    colormap = colmap,
)

save("./figs/climate_circle.png", F)

Ax.limits = (xlims, ylims)
Ax.aspect = 1
save("./figs/climate_circle_full.png", F)
