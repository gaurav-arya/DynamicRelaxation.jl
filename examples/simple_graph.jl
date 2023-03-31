using Graphs
using StaticArrays
using LinearAlgebra
using NBodySimulator
using StaticGraphs

using Plots, GraphRecipes

include("../src/include_lib.jl")

# Define a simple graph and plot
n_elem = 17
n_pt = n_elem + 1
graph = StaticGraph(path_graph(n_pt))

plot(path_graph(n_pt), curves = false)

E = 210 * 1e9               # [Pa]
Iy = Iz = 4.7619 * 1e-7     # [m^4]
A = 4.7619 * 1e-4           # [m^2]
G = 78 * 1e9                # [Pa]
It = 2 * Iy                 # [m^4]
l_init = 1.0

ep = ElementProperties{Float64}(E, A, Iy, Iz, G, It, l_init)

np_fix = Node3DOF{Float64}(@SVector(zeros(3)), @SVector(zeros(3)), true, @SVector(ones(Bool, 3)));
np_free = [Node3DOF{Float64}(SVector{3,Float64}([i-1,0.0,0.0]), @SVector(zeros(3)), false, @SVector(zeros(Bool, 3))) for i in 2:n_pt-1];

nodes = vcat(np_fix, np_free..., Node3DOF{Float64}(SVector{3,Float64}([n_elem,0.0,0.0]), @SVector(zeros(3)), true, @SVector(ones(Bool, 3)))); # Assuming same order as in graph
eps = [ep for _e in edges(graph)]; # Assuming same order as in graph

edgelist = collect(edges(graph))

edgemap = Dict{Tuple{UInt8, UInt8}, Int}((src(e), dst(e))=>i for (i, e) in enumerate(edgelist))

system = StructuralGraphSystem{Node3DOF}(nodes, graph, eps, edgemap);
