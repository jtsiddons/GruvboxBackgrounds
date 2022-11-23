using CairoMakie
using Colors

include("./gruv_colours.jl")

## Graphic Settings
const WIDTH::Int16 = 3840 
const HEIGHT::Int16 = 2160
const PLANET_SCALE::Float32 = 0.125f0

RATIO = WIDTH/HEIGHT
xlims = (-0.2f0, 31f0)
ylim_val = 0.5f0*(xlims[2]-xlims[1])/RATIO
ylims = (-ylim_val, ylim_val)

## This is a planets graphic, showing
## a circle for each planet, with a single colour.

struct PlanetaryObject
    x::Float32
    y::Float32
    radius::Float32
    colour::Color
end

planets = Dict{Symbol, PlanetaryObject}()

## Planets and Sol are scaled relative to Earth. Distances are in AU
planets[:Sol    ] = PlanetaryObject(-(PLANET_SCALE * 109f0), 0f0, PLANET_SCALE * 109f0, yellow)

planets[:Mercury] = PlanetaryObject( 0.39f0,   0f0,   PLANET_SCALE *  0.39f0,   white)
planets[:Venus  ] = PlanetaryObject( 0.72f0,   0f0,   PLANET_SCALE *  0.95f0,   orange)
planets[:Earth  ] = PlanetaryObject( 1.00f0,   0f0,   PLANET_SCALE *  1.00f0,   blue)
planets[:Mars   ] = PlanetaryObject( 1.52f0,   0f0,   PLANET_SCALE *  0.53f0,   red)
planets[:Jupiter] = PlanetaryObject( 5.20f0,   0f0,   PLANET_SCALE * 11.19f0,   white)
planets[:Saturn ] = PlanetaryObject( 9.54f0,   0f0,   PLANET_SCALE *  9.40f0,   yellow)
planets[:Uranus ] = PlanetaryObject(19.19f0,   0f0,   PLANET_SCALE *  4.04f0,   white)
planets[:Neptune] = PlanetaryObject(30.07f0,   0f0,   PLANET_SCALE *  3.88f0,   blue)

SolarSystem = Figure(
    resolution = (WIDTH, HEIGHT), 
    figure_padding=0,
)

Ax = Axis(
    SolarSystem[1,1], 
    backgroundcolor=black,
    limits = (xlims, ylims),
)

hidespines!(Ax)
hidedecorations!(Ax)

function planet_size(planet::PlanetaryObject)
    return planet.radius*WIDTH/(xlims[2]-xlims[1])
end

function plot_planet!(A::Axis, planet::PlanetaryObject)
    poly!(A, Circle(Point2f(planet.x, planet.y), planet.radius), color = planet.colour)
end

function planet_lines(A::Axis, start_height::Float32, end_height::Float32, colour::Color, planet::PlanetaryObject)
    marker_size = planet_size(planet)

    if start_height > planet.radius || end_height < -planet.radius
        return
    end
    if end_height > planet.radius
        end_height = planet.radius
    end
    if start_height < -planet.radius
        start_height = -planet.radius
    end
    
    y1 = start_height/planet.radius
    y2 = end_height/planet.radius
    angle1 = asin(y1)
    angle2 = asin(y2)
    x1 = cos(angle1)
    x2 = cos(angle2)
    
    
    line = BezierPath([
        MoveTo(Point2f(x1, y1)),
        EllipticalArc(Point2f(0f0, 0f0), 1f0, 1f0, 0f0, angle1, angle2),
        LineTo(Point2f(-x2, y2)),
        EllipticalArc(Point2f(0f0, 0f0), 1f0, 1f0, 0f0, π-angle2, π-angle1),
        LineTo(Point2f(x1, y1)),
        ClosePath()
    ])

    scatter!(A, planet.x, planet.y, marker=line, markersize=marker_size, color=colour)
end 

function planet_rings(A::Axis, planet::PlanetaryObject, colour::Color)
    
    marker_size = planet_size(planet)
    
    a_out, b_out = 1.5f0, 0.5f0
    a_in, b_in = 1.3f0, 0.4f0
    x_out, y_out = circ_ellipse_intersec(a_out, b_out)
    x_in, y_in = circ_ellipse_intersec(a_in, b_in)

    angle_out = acos(x_out)
    angle_in = acos(x_in)
    e_angle_out = acos(x_out/a_out)
    e_angle_in = acos(x_in/a_in)

    ring = BezierPath([
        MoveTo(Point2f(-x_in, y_in)),
        EllipticalArc(Point2f(0f0, 0f0), a_in, b_in, 0f0, π-e_angle_in, 2π + e_angle_in),
        EllipticalArc(Point2f(0f0, 0f0), 1f0, 1f0, 0f0, angle_in, angle_out),
        EllipticalArc(Point2f(0f0, 0f0), a_out, b_out, 0f0, 2π + e_angle_out, π-e_angle_out),
        EllipticalArc(Point2f(0f0, 0f0), 1f0, 1f0, 0f0, π-angle_out, π-angle_in),
        ClosePath()
    ])

    scatter!(
        A,
        planet.x,
        planet.y,
        marker = ring,
        markersize = marker_size,
        color = colour
    )
end

function circ_ellipse_intersec(a, b)
    # Intersection of circle (r=1) and ellipse (a,b)
    # See `https://math.stackexchange.com/questions/898313/intersection-of-circle-and-ellipse`
    # y² = (a² - 1)x² / ((a²/b²) - a²)
    intersec_fraction = (a^2 - 1) / ((a^2/b^2) - a^2)
    x2 = 1 / (1 + intersec_fraction)
    x = sqrt(x2)
    y = sqrt(intersec_fraction*x2)
    return x, y
end

function planet_spot(A::Axis, x::Float32, y::Float32, r::Float32, colour::Color, planet::PlanetaryObject)
    marker_size = planet_size(planet)
    
    spot = BezierPath([
        MoveTo(Point2f(x, y)),
        EllipticalArc(Point2f(x, y), r*1.5f0, 0.8f0*r, 0f0, 0f0, 2π),
        ClosePath()
    ])

    scatter!(A, planet.x, planet.y, marker = spot, markersize = marker_size, color=colour)    
end

## Stars
# Don't put stars in the region of planets.

n_stars = 500
x_opts = range(xlims..., 1_000)
y_opts = range(ylims..., 1_000)
y_opts = y_opts[findall(opt -> abs(opt) > 1.3*planets[:Jupiter].radius, y_opts)]
col_opts = [fill(gray13, 10)..., fill(white, 20)..., fill(yellow, 2)..., red, blue]

star_points = [Point2f(rand(x_opts), rand(y_opts)) for _ in 1:n_stars]
colours = rand(col_opts, n_stars)
sizes = 10f0 .* rand(n_stars)
markers = rand([:star4, :star5, :star6, :star8], n_stars)

scatter!(
    Ax,
    star_points,
    color = colours,
    markersize = sizes,
    marker = markers,
)

## Solar System - plot sun and planets

for (_, planet) in planets
    plot_planet!(Ax, planet)
end

# Add Saturn Rings
planet_rings(Ax, planets[:Saturn], orange)

# Add Jupiter Lines
n_lines=8
points = range(-planets[:Jupiter].radius, planets[:Jupiter].radius, n_lines+1)
line_colours = reverse([white, orange, white, orange, green, magenta, white, cyan])

for (s, e, c) in zip(points[1:end-1], points[2:end], line_colours)
    planet_lines(Ax, s, e, c, planets[:Jupiter])
end 

planet_spot(Ax, -0.2f0, -0.5f0, 0.15f0, red, planets[:Jupiter])

## Add some land to earth
euro_asia = BezierPath([
    MoveTo(Point2f(0.5f0, Float32(sqrt(3)/2))),
    LineTo(Point2f(-0.1f0, 0.8f0)),
    LineTo(Point2f(-0.15f0, 0.85f0)),
    LineTo(Point2f(-0.25f0, 0.4f0)),
    LineTo(Point2f(-0.2f0, 0.6f0)),
    LineTo(Point2f(-0.3f0, 0.4f0)),
    LineTo(Point2f(-0.6f0, 0.3f0)),
    LineTo(Point2f(-0.5f0, 0.2f0)),
    LineTo(Point2f(0.5f0, 0.2f0)),
    LineTo(Point2f(0.6f0, -0.4f0)),
    LineTo(Point2f(0.75f0, 0.2f0)),
    LineTo(Point2f(Float32(sqrt(3)/2), 0.5f0)),
    EllipticalArc(Point2f(0f0, 0f0), 1f0, 1f0, 0f0, π/6, π/3),
    ClosePath()
])

africa = BezierPath([
    MoveTo(Point2f(-0.5f0, 0.1f0)),
    LineTo(Point2f(0.2f0, 0.0f0)),
    LineTo(Point2f(0.1f0, -0.8f0)),
    LineTo(Point2f(-0.1f0, -0.75f0)),
    LineTo(Point2f(-0.1f0, -0.4f0)),
    LineTo(Point2f(-0.5f0, -0.4f0)),
    LineTo(Point2f(-0.5f0, 0.1f0)),
    ClosePath()
])

Earth = planets[:Earth]
scatter!(Ax, Earth.x, Earth.y, marker = euro_asia, color = green, markersize=planet_size(Earth))
scatter!(Ax, Earth.x, Earth.y, marker = africa, color = green, markersize=planet_size(Earth))


save("./figs/SolarSystemSimple.png", SolarSystem)


