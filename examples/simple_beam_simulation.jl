using Plots, GraphRecipes

using DynamicRelaxation

using Graphs
using StaticGraphs
using DiffEqCallbacks
using DifferentialEquations

# Define a simple graph system
n_elem = 17
n_pt = n_elem + 1
graph = StaticGraph(path_graph(n_pt))
system = default_system(graph, Node6DOF, :catenary, n_pt)

# Set loads
ext_f = uniform_load(Pz(-10_000, system), system)

# Set parameters
maxiters = 500
dt = 0.01
tspan = (0.0, 10.0)

# Create problem
simulation = RodSimulation{StructuralGraphSystem{Node6DOF}, Float64, eltype(ext_f)}(system,
                                                                                    tspan,
                                                                                    dt,
                                                                                    ext_f)
prob = ODEProblem(simulation)

# Create callback
c = 0.7
(u0, v0, n, u_len, v_len) = get_u0(simulation)
(dx_ids, dr_ids, v_ids, ω_ids) = get_vel_ids(u_len, v_len)
v_decay!(integrator) = velocitydecay!(integrator, vcat(v_ids, ω_ids), c)
cb1 = PeriodicCallback(v_decay!, 3 * dt; initial_affect = true)

tol = 1e-5
ke_cond(u, t, integrator) = ke_condition(u, t, integrator, tol, vcat(v_ids, ω_ids))
cb2 = ContinuousCallback(ke_cond, velocityreset!) # This has no effect currently...

cb = CallbackSet(cb1, cb2)

# Set algorithm for solver
alg = RK4()

# Solve problem
@time sol = solve(prob, alg, dt = simulation.dt, maxiters = maxiters, callback = cb);

# Plot final state
u_final = get_state(sol.u[end], u_len)
plot(u_final[1, :], u_final[3, :])

# Select frames for animation
itt = generate_range(100, 1, length(sol.u))
u_red = sol.u[itt]

# Loop over the time values and create a plot for each frame
anim = @animate for i in axes(u_red, 1)
    u_final = get_state(u_red[i], u_len)
    plot(u_final[1, :], u_final[3, :])
end

# Save the frames as a gif
gif(anim, "animation.gif", fps = 20)
