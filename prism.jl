using CairoMakie
using Colors

include("./gruv_colours.jl")

## Gruvbox Line going into prism

const WIDTH::Int16 = 3840
const HEIGHT::Int16 = 2160

RATIO = WIDTH/HEIGHT
xlims = (-2.5f0, 2.5f0)
ylim_val = 0.5f0*(xlims[2]-xlims[1])/RATIO
ylims = (-ylim_val, ylim_val)

struct Photon
    colour::Color
    low::Float32
    high::Float32
end 

waves = Dict{Symbol, Photon}()

wavelengths = range(0.38, 0.75, 8)

waves[:red] =       Photon(red,     wavelengths[7], wavelengths[8])
waves[:orange] =    Photon(orange,  wavelengths[6], wavelengths[7])
waves[:yellow] =    Photon(yellow,  wavelengths[5], wavelengths[6])
waves[:green] =     Photon(green,   wavelengths[4], wavelengths[5])
waves[:cyan] =      Photon(cyan,    wavelengths[3], wavelengths[4])
waves[:blue] =      Photon(blue,    wavelengths[2], wavelengths[3])
waves[:magenta] =   Photon(magenta, wavelengths[1], wavelengths[2])

# waves[:red] = Photon(red, .62, .75)
# waves[:orange] = Photon(orange, .59, .62)
# waves[:yellow] = Photon(yellow, .57, .59)
# waves[:green] = Photon(green, .52, .57)
# waves[:cyan] = Photon(cyan, .495, .52)
# waves[:blue] = Photon(blue, .45, .495)
# waves[:magenta] = Photon(magenta, .38, .45)


Prism = Figure(
    resolution = (WIDTH, HEIGHT), 
    figure_padding=0,
)

Ax = Axis(
    Prism[1,1],
    backgroundcolor = black,
    limits = (xlims, ylims),
)

hidespines!(Ax)
hidedecorations!(Ax)


## Add the Prism

rt3_2 = Float32(sqrt(3)/2)

triangle = Point2f[
    (-0.5f0, 0f0),
    (0f0, rt3_2),
    (1f0, -rt3_2),
    (-1f0, -rt3_2),
    (-0.5f0, 0f0),
    #(0f0, rt3_2),
    #(1f0, -rt3_2),
    #(-1f0, -rt3_2),
]


## Refraction - Refractive Index (Cauchy's transmission equation)
# Values for Fused Silica
A = 1.058 
B = .1031  
ref_ind(λ) = A + B/(λ^2) # λ in μm

snell_in(θ₁, λ) = asin(sin(θ₁)/ref_ind(λ))
snell_out(θ₁, λ) = asin(sin(θ₁)/(1/A + B/(λ^2)))

function deflection_shape_in(A::Axis, light::Photon, θ_high::Float32, θ_low::Float32, c_high::Point2f, c_low::Point2f, θ_prism::Float32)
    θ_out_high = Float32(snell_in(θ_high, light.high) - θ_prism)
    θ_out_low = Float32(snell_in(θ_low, light.low) - θ_prism)
    
    tan_out_high = tan(θ_out_high) 
    tan_out_low  = tan(θ_out_low)

    x_high_out = (sqrt(3)/2 + tan_out_high*c_high[1] - c_high[2]) / (sqrt(3) + tan_out_high)
    x_low_out = (sqrt(3)/2 + tan_out_low*c_low[1] - c_low[2]) / (sqrt(3) + tan_out_low)
    y_high_out = c_high[2] - tan_out_high*(c_high[1] - x_high_out)
    y_low_out = c_low[2] - tan_out_low*(c_low[1] - x_low_out)
    
    c_out_high = Point2f(x_high_out, y_high_out)
    c_out_low = Point2f(x_low_out, y_low_out)

    shape = [c_high, c_out_high, c_out_low, c_low]
    poly!(A, shape, color=light.colour)
    return c_out_high, c_out_low, θ_out_high, θ_out_low
end 

function deflection_shape_out(A::Axis, light::Photon, θ_high::Float32, θ_low::Float32, c_high::Point2f, c_low::Point2f, θ_prism::Float32)
    θ_out_high = Float32(snell_out(θ_high, light.high) - θ_prism)
    θ_out_low = Float32(snell_out(θ_low, light.low) - θ_prism)
    
    tan_out_high = tan(θ_out_high) 
    tan_out_low  = tan(θ_out_low)

    x_high_out = 4f0 
    x_low_out = 4f0
    y_high_out = c_high[2] - tan_out_high*(c_high[1] - x_high_out)
    y_low_out = c_low[2] - tan_out_low*(c_low[1] - x_low_out)
    
    c_out_high = Point2f(x_high_out, y_high_out)
    c_out_low = Point2f(x_low_out, y_low_out)

    shape = [c_high, c_out_high, c_out_low, c_low]
    poly!(A, shape, color=light.colour)
    return c_out_high, c_out_low, θ_out_high, θ_out_low
end

θ_in = Float32(π/4)

xpts = range(-0.52f0, -.48f0, length(keys(waves))+1)
ypts(x) = sqrt(3f0) * (0.5f0 + x)

## Light incident to triangle
angle_incident_to_triangle = Float32(π/12)

# Change to poly, so that we can have nice incidence to triangle
#lines!(
#    Ax,
#    [-5.f0,-0.5f0],
#    [-4.5f0*tan(angle_incident_to_triangle), 0f0],
#    color=white,
#    linewidth=25,
#)

grad = tan(angle_incident_to_triangle)
x0 = -5f0
y0 = (x, x1, y1) -> y1 + grad*(x-x1)

incident_light_shape = Point2f[
    (xpts[1], ypts(xpts[1])),
    (xpts[end], ypts(xpts[end])),
    (x0, y0(x0, xpts[end], ypts(xpts[end]))),
    (x0, y0(x0, xpts[1], ypts(xpts[1]))),
]
poly!(
    Ax,
    incident_light_shape,
    color=white,
)


## Deflection
cols = reverse([:red, :orange, :yellow, :green, :cyan, :blue, :magenta])
for (col, xlow, xhigh) in zip(cols, xpts[1:end-1], xpts[2:end])
    c_out_high, c_out_low, θ_out_high, θ_out_low = deflection_shape_in(Ax, waves[col], θ_in, θ_in, Point2f(xhigh, ypts(xhigh)), Point2f(xlow, ypts(xlow)),Float32(π/6))
    deflection_shape_out(Ax, waves[col], Float32(π/6)+θ_out_high, Float32(π/6)+θ_out_low, c_out_high, c_out_low, Float32(π/6))
end

# Redraw Outline
poly!(
    Ax,
    triangle,
    color = (gray4, 0.6),
)

poly!(
    Ax,
    triangle,
#	[triangle..., triangle...],
	color=(white,0),
	strokecolor=gray8,
	strokewidth=20
)

save("./figs/RainbowPrism.png", Prism)
