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

using JuMP, Gurobi
function getC(containter, idx)
    count = 0
    for c in containter
        count +=1
        if count == idx return c
        end
    end
end


function relaxation(utils, sizes, indxs, jump_model, n_cons)
    # println(sizes)
    # println(utils)
    longest = argmax(sizes)
    idx = argmin(utils[longest])
    c_idx = indxs[idx] 
    # println(c_idx)
    # c = getC(n_cons, c_idx)
    delete(jump_model,n_cons[c_idx])
    # println(is_valid(jump_model,n_cons[c_idx]))
    deleteat!(utils, idx)
    deleteat!(indxs, idx)
    deleteat!(sizes, idx)
    # println(indxs)
    # println(sizes)
    # println(utils)
end
function solve_CSP_FILP(s_constraints, n_constraints, variables, δ, N_IT, data, uTable)

    jump_model = direct_model(Gurobi.Optimizer())
    model = backend(jump_model)
    @variable(jump_model, 1<= x[1:length(variables)], Int)

    n_s_cons = length(s_constraints)
    n_n_cons = length(n_constraints)

    @constraint(jump_model, s_cons, s_constraints.matrix * x .<= s_constraints.bounds)
    @constraint(jump_model, n_cons, n_constraints.matrix * x  .>= n_constraints.bounds)

    @objective(jump_model, Min, sum(x))

    indxs = collect(1:length(N_IT.sizes))
    set_optimizer_attribute(jump_model, "OutputFlag", 0)
    # println(size(n_cons), size(s_cons))
    optimize!(jump_model)
    while termination_status(jump_model) == MOI.INFEASIBLE || termination_status(jump_model)== MOI.INFEASIBLE_OR_UNBOUNDED
        # Relaxation
        # println("Relax")
        relaxation(N_IT.utils, N_IT.sizes, indxs, jump_model, n_cons)
        optimize!(jump_model)
    end
    return value.(x), jump_model, model
end

function solve_CSP_G_ILP(s_constraints, n_constraints, variables, δ, N_IT, data, uTable)
    jump_model = direct_model(Gurobi.Optimizer())
    model = backend(jump_model)
    @variable(jump_model, 1<= x[1:length(variables)], Int)

    n_s_cons = length(s_constraints)
    n_n_cons = length(n_constraints)

    @constraint(jump_model, s_cons, s_constraints.matrix * x .<= s_constraints.bounds)
    @constraint(jump_model, n_cons, n_constraints.matrix * x .>= n_constraints.bounds)
    @objective(jump_model, Min, sum(x))

    set_optimizer_attribute(jump_model, "OutputFlag", 0)
    # println(size(n_cons), size(s_cons))
    optimize!(jump_model)
    if  termination_status(jump_model) == MOI.INFEASIBLE || termination_status(jump_model)== MOI.INFEASIBLE_OR_UNBOUNDED
        # Relaxation
        # println("Relax CSP")
        n_penalties = ones(n_n_cons)
        s_penalties = fill(GRB_INFINITY, n_s_cons)  # Those constraints should not be relaxed
        penalties = vcat(s_penalties, n_penalties)
        error = GRBfeasrelax(model, 0, 1, C_NULL, C_NULL, penalties, C_NULL)
        # set_optimizer_attribute(jump_model, "MIPGap", 0.001)
        optimize!(jump_model)
    end
    return value.(x), jump_model, model
end
function computeInformationForRelaxation(NHI, data, uTable)

    sizes=[]
    utils=[]
    for itemset in NHI.itemsets
        push!(sizes, length(itemset))
        push!(utils, totalItemsetUtil(itemset,data,uTable))
    end
    # println(utils)
    indxs = collect(1: length(sizes))
    return sizes, utils, indxs
end

function solve_CSP_PPUM_ILP(s_constraints, n_constraints, variables, δ, NHI, data, uTable)

    jump_model = direct_model(Gurobi.Optimizer())
    model = backend(jump_model)

    @variable(jump_model, 1 <= x[1:length(variables)], Int)

    n_s_cons = length(s_constraints)
    n_n_cons = length(n_constraints)

    @constraint(jump_model, s_cons, s_constraints.matrix * x .<= s_constraints.bounds)
    @constraint(jump_model, n_cons, n_constraints.matrix * x  .>= n_constraints.bounds)

    @objective(jump_model, Min, sum(x))

    set_optimizer_attribute(jump_model, "OutputFlag", 0)
    optimize!(jump_model)
    sizes, utils, indxs = computeInformationForRelaxation(NHI, data, uTable)

    while  termination_status(jump_model) == MOI.INFEASIBLE || termination_status(jump_model)== MOI.INFEASIBLE_OR_UNBOUNDED
        # Relaxation
        relaxation(utils, sizes, indxs, jump_model, n_cons)
        optimize!(jump_model)
    end

    return value.(x), jump_model, model
end
function hideSIs(x_vals, data, variables)
    for i in 1:length(variables)
        pos =  variables.poss[i]
        tid = pos[1]
        item = pos[2]
        if get(data, tid, -1) == -1
            continue
        end
        data[tid][item] = ceil(x_vals[i])
    end
end

