#=
Copyright (C) 2023 Duc Nguyen

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
=#

include("./ConstraintMatrix.jl")
include("./IT.jl")
include("./FModel_C.jl")
include("./FModel_G.jl")
include("./ILPSolve.jl")
include("./FModel_PPUM_ILP.jl")
struct CSPAlgorithm<:Algorithm
    name::String
    preprocess::Function 
    solve_CSP::Function
end
name(al::CSPAlgorithm) = al.name
function preprocess_PPUM_ILP(data, uTable, δ, SHUIs, HUIs)
    N_IT, S_IT = construct_tables(HUIs.itemarrays, HUIs.utils, SHUIs.itemarrays, data)
    find_special_sets(N_IT, S_IT)
    s_constraints, n_constraints, variables = establish_constraints(N_IT, S_IT, data, uTable, δ)
    return s_constraints, n_constraints, variables, N_IT 
end
function preprocess_C(data, uTable, δ, SHUIs, HUIs)
    N_IT, S_IT = construct_tables(HUIs.itemsets, HUIs.utils, SHUIs.itemsets, data)
    find_special_sets(N_IT, S_IT)
    s_constraints, n_constraints, variables = establish_constraints(N_IT, S_IT, data, uTable, δ)
    return s_constraints, n_constraints, variables, N_IT 
end
function preprocess_G(D, uTable, δ, SHUIs, HUIs, data)
    N_G_IT, S_G_IT = parallel_construct_tables(HUIs, SHUIs, D)
    find_special_sets_G(N_G_IT, S_G_IT)
    s_constraints, n_constraints, variables = establish_constraints_G(N_G_IT, S_G_IT, data, uTable, δ)
  
    return s_constraints, n_constraints, variables, N_G_IT 
end
function preprocess_PPUM_ILP(data, uTable, δ, SHUIs, HUIs)
    NHI,SHI = construct_tables_PPUM_ILP(HUIs.itemarrays, HUIs.utils, SHUIs.itemarrays, data)
    find_special_sets_PPUM_ILP(NHI, SHI, data, uTable, δ)
    s_constraints, n_constraints, variables = establish_constraints_PPUM_ILP(NHI, SHI, data, uTable, δ)
    return s_constraints, n_constraints, variables, NHI
end
FILP = CSPAlgorithm("FILP", preprocess_C, solve_CSP_FILP)
G_ILP = CSPAlgorithm("G-ILP", preprocess_G, solve_CSP_G_ILP)
PPUM_ILP = CSPAlgorithm("PPUM-ILP", preprocess_PPUM_ILP, solve_CSP_PPUM_ILP)
function run_algorithm(al::CSPAlgorithm, data, uTable, δ, SHUIs, HUIs)
    s_constraints, n_constraints, variables, table = al.preprocess(data, uTable, δ, SHUIs, HUIs)
    x, jump_model, model  = al.solve_CSP(s_constraints, n_constraints, variables, δ, table, data, uTable)
    hideSIs(x, data, variables) 
    return jump_model, model
end
function run_gpu_algorithm(al::CSPAlgorithm, D, uTable, δ, SHUIs, HUIs, data)
    s_constraints, n_constraints, variables, table = al.preprocess(D, uTable, δ, SHUIs, HUIs, data)
    x, jump_model, model  = al.solve_CSP(s_constraints, n_constraints, variables, δ, table, data, uTable)
    hideSIs(x, data, variables) 
    return jump_model, model
end

