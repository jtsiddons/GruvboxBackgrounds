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

path = "M105.8125,16.625 c -7.39687,18.135158 -11.858304,29.997682 -20.09375,47.59375 5.04936,5.35232 11.247211,11.585364 21.3125,18.625 C 96.210077,78.390904 88.828713,73.920352 83.3125,69.28125 72.7727,91.274163 56.259864,122.60209 22.75,182.8125 49.087628,167.60733 69.504089,158.23318 88.53125,154.65625 87.714216,151.1422 87.2497,147.34107 87.28125,143.375 l 0.03125,-0.84375 c 0.417917,-16.87382 9.195665,-29.84979 19.59375,-28.96875 10.39809,0.88104 18.48041,15.28242 18.0625,32.15625 -0.0786,3.17512 -0.43674,6.22955 -1.0625,9.0625 18.82058,3.68164 39.01873,13.03179 65,28.03125 -5.123,-9.4318 -9.69572,-17.93388 -14.0625,-26.03125 -6.87839,-5.33121 -14.05289,-12.2698 -28.6875,-19.78125 10.05899,2.61375 17.2611,5.62932 22.875,9 C 124.63297,63.338161 121.03766,52.354109 105.8125,16.625 z"

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

save("./figs/GruvvyArch.png", F)
