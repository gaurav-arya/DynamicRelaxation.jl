
using Plots, GraphRecipes

include("../src/include_lib.jl")

# Define a simple graph system
n_elem = 17
n_pt = n_elem + 1
graph = StaticGraph(path_graph(n_pt))
system = default_system(graph, Node6DOF, :catenary)


# Set loads
#ext_f = point_loads([Pz(-10, system) ], [n_pt], system)
ext_f = uniform_load(Pz(-10_000, system), system)

# Set parameters
maxiters = 300
dt = 0.01
tspan = (0.0, 10.0)

# Create problem
simulation = RodSimulation{StructuralGraphSystem{Node6DOF},Float64,eltype(ext_f)}(system, tspan, dt, ext_f)
prob = ODEProblem(simulation)
ssprob = SteadyStateProblem(prob)

# Create callback TODO: find a better way
c = 0.7
(u0, v0, n, u_len, v_len) = gather_bodies_initial_coordinates(simulation)
(dx_ids, dr_ids, v_ids, ω_ids) = get_vel_ids(u_len, v_len)
velocitydecay!(integrator) = velocitydecay!(integrator, vcat(v_ids, ω_ids), c)
cb = PeriodicCallback(velocitydecay!, 3 * dt; initial_affect=true)

# Create a callback to do kinetic damping

# Set termination condition
cond = NLSolveTerminationCondition(NLSolveTerminationMode.AbsSafe; abstol = 1e-1)
#cond = KETerminationCondition(v_ids, abstol = 1e-3)

# Set algorithm for solver
#alg = Rosenbrock23(autodiff=false)
alg = RK4()

# Solve problem
@time sol = solve(ssprob, DynamicSS(alg, termination_condition = cond),  maxiters=maxiters, callback = cb);
#@time sol = solve(ssprob, SSRootfind(),  maxiters=maxiters, callback = cb);
#@profview solve(prob, alg, dt = simulation.dt, maxiters=maxiters, callback = cb);

# Plot final state
u_final = get_state(sol.u, u_len)
plot(u_final[1, :], u_final[3, :])

#=

# Select frames for animation
itt = generate_range(100, 1, length(sol.u))
u_red = sol.u[itt]

# Loop over the time values and create a plot for each frame
anim = @animate for i in axes(u_red, 1)
    u_final = get_state(u_red[i], u_len)
    plot(u_final[1, :], u_final[3, :])
end

# Save the frames as a gif
gif(anim, "animation.gif", fps=20)

=#