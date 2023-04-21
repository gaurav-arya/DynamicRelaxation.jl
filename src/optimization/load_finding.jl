struct LoadScaleRodSimulation{T} <: StructuralSimulation{T}
    system::StructuralGraphSystem{T}
    tspan::Tuple{Float64, Float64}
    dt::Float64
end

function LoadScaleRodSimulation(system::T, tspan, dt) where {T}
    return LoadScaleRodSimulation{eltype(system.bodies)}(system::T, tspan, dt)
end

function f_acceleration(a, τ, ext_f, i, p)
    a = SA[a[1] + p[1] * ext_f[i][1], a[2] + p[1] * ext_f[i][2], a[3] + p[1] * ext_f[i][3]]
    τ = SA[τ[1] + p[1] * ext_f[i][4], τ[2] + p[1] * ext_f[i][5], τ[3] + p[1] * ext_f[i][6]]
    return a, τ
end

function accelerate_system(u_v, system::StructuralGraphSystem{Node6DOF},
                           simulation::LoadScaleRodSimulation{Node6DOF}, body,
                           ext_f, du, dr_ids, ω, i, dt, u_t, p)
    (a, τ, s, j) = rod_acceleration(u_v, system, body, i)
    (a, τ) = f_acceleration(a, τ, ext_f, i, p)
    (a, τ) = constrain_acceleration(a, τ, body)
    a = apply_jns!(a, s, dt)
    dω = update_dω(i, ω, τ, du, dr_ids, j, u_t, dt)
    return a, dω
end
