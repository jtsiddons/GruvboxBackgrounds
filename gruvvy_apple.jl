using CairoMakie
using Colors
using FileIO

include("./gruv_colours.jl")

const WIDTH::Int16 = 3840
const HEIGHT::Int16 = 2160

RATIO = WIDTH/HEIGHT

## Set axis scale so that points are 1:1
xlims = (-5f0, 5f0)
ylim_val = 0.5f0*(xlims[2]-xlims[1])/RATIO
ylims = (-ylim_val, ylim_val)

F = Figure(
    resolution = (WIDTH, HEIGHT),
    figure_padding = 0,
)

GruvText = F[1,1] = GridLayout()

## I want to have the arch logo such that it is in rainbow top-to-bottom
# No idea how to proceed
# Best guess - generate an svg path for the logo and then split it

path = "M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z"

ylim_range = range(ylims[2], ylims[1], 7)
colours = [
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
]

bright_colours = [
    bright_red,
    bright_green,
    bright_yellow,
    bright_blue,
    bright_magenta,
    bright_cyan,
]

arch = BezierPath(path, fit=true, flipy = true, keep_aspect=true)

for (i, (yl, yu, c, b)) in enumerate(zip(ylim_range[2:end], ylim_range[1:end-1], colours, bright_colours))
    A = Axis(
        GruvText[i,1],
        backgroundcolor = black,
        limits = (xlims, (yl, yu)),
    )

    hidespines!(A)
    hidedecorations!(A)

    # scatter!(A, 0.1, -0.1, marker = arch, markersize = 2100, color = white)
    scatter!(A, 0.0, 0.0, marker = arch, markersize = 2100, color = b, strokearound=true, strokewidth=50, strokecolor=c)
end

rowgap!(GruvText, 0)
colgap!(GruvText, 0)

save("./figs/GruvvyApple.png", F)
