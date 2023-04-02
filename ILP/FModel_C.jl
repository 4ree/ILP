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

function construct_tables(h_itemsets, h_utils, s_itemsets,
        data)
    # 1st phase: Constructs tables stored relationship of HUIs and transactions support them
    S_IT = IT()
    N_IT = IT()            
    for i in 1: length(h_itemsets)
        itemset = h_itemsets[i]
        util = h_utils[i]
        size = length(h_itemsets[i])
        # println(itemset, size)
        tids=Set{UInt32}()
        # Find transactions that support itemset 
        for (tid, transaction) in data
            trans = collect(keys(transaction))
            if itemset ⊆ trans
                push!(tids, tid)

            end

        end
        if itemset ∈ s_itemsets
            push!(S_IT.itemsets, Set(itemset))
            push!(S_IT.tidsets, tids)
            push!(S_IT.sizes, size)
            push!(S_IT.utils,util )
            S_IT.n_rows +=1
        else

            push!(N_IT.itemsets, Set(itemset))
            push!(N_IT.tidsets, tids)
            push!(N_IT.utils,util )
            push!(N_IT.sizes, size)
            N_IT.n_rows+=1
        end
    end
    # println(S_IT.n_rows)
    return N_IT, S_IT
end

function construct_tables_FILP(h_itemsets, h_utils, s_itemsets, data)
    S_IT = IT()
    N_IT = IT()            
    for i in 1: length(h_itemsets)
        itemset = h_itemsets[i]
        util = h_utils[i]
        size = length(h_itemsets[i])
        # println(itemset, size)
        tids=Set{UInt32}()
        # Find transactions that support itemset 
        for (tid, transaction) in data
            trans = collect(keys(transaction))
            if itemset ⊆ trans
                push!(tids, tid)
            end
        end
        if itemset ∈ s_itemsets
            push!(S_IT.itemsets, Set(itemset))
            push!(S_IT.tidsets, tids)
            push!(S_IT.sizes, size)
            push!(S_IT.utils,util )
            S_IT.n_rows +=1
        else

            push!(N_IT.itemsets, Set(itemset))
            push!(N_IT.tidsets, tids)
            push!(N_IT.utils,util )
            push!(N_IT.sizes, size)
            N_IT.n_rows+=1
        end
    end
    # println(S_IT.n_rows)
    return N_IT, S_IT
end
    
function find_special_sets(N_IT::IT, S_IT::IT)
    # 2nd phase: find bound-to-lose itemsets and itemsets that will be not affected by hiding process
    remove = Array{UInt32,1}()
    for i in 1: N_IT.n_rows
        L = 0 
        n_itemset  = N_IT.itemsets[i]
        n_tidset = N_IT.tidsets[i]
        for j in 1: S_IT.n_rows
            s_itemset  = S_IT.itemsets[j]
            s_tidset = S_IT.tidsets[j]
            a = n_itemset ∩ s_itemset
            b = n_tidset ∩ s_tidset
            if !isempty(a) && !isempty(b)
                if n_itemset ⊆ s_itemset && n_tidset ⊆ s_tidset
                    push!(remove, i)                #Bound to lose itemset
                    break
                end
            else
                L+=1
                
            end
        end

        if L == S_IT.n_rows
            push!(remove, i)                # itemset that will not be affected by hiding process
        end

        # 3rd phase: find redundant itemsets
        for k in 1:N_IT.n_rows
            n1_itemset = N_IT.itemsets[k]
            n1_tidset = N_IT.tidsets[k]
            if n_itemset!=n1_itemset &&  n1_itemset ⊆ n_itemset && n1_tidset ⊆ n_tidset
                push!(remove, i)
                break
            end
        end

    end
    deleteat!(N_IT, unique(remove))
    # println("n_remove: ",length(unique(remove)))
    # println("r_itemsets: ", N_IT.n_rows)
    return remove
end

function establish_constraints(N_IT, S_IT, data, uTable, δ)

    # Establish variables and constraint matrix for sensitive itemsets
    #========================================================================================#
    n_vrs = 0                                               # Number of variables
    utils = Dict{Tuple{UInt32, UInt32}, Float64 }()           # Variable utils
    coeff = Array{Float64,1}()                                  # Coefficent of variables
    vr_orders = Dict{Tuple{UInt32, UInt32} , Int64 }()      # Order of variables in variable list
    poss = Array{Tuple{Int64, Int64},1}()                   # Positions of variables in data 

    # println(size(S_IT.itemsets))
    # println(S_IT.n_rows)
    n_s_constraints = S_IT.n_rows                          # Number of sensitive itemsets
    
    # println(n_s_constraints)
    # constraints constructed from S_IT table 

    replace_indices=Array{Array{UInt32,1},1}()                                      # Matrix indices to replace (abstract array)
    for c_idx in 1: n_s_constraints
        itemset = S_IT.itemsets[c_idx]
        tidset  = S_IT.tidsets[c_idx]
        prod = collect(Iterators.product(tidset, itemset))

        r = Array{UInt32,1}()
        for v in prod
            if get(vr_orders, v, -1) == -1 
                n_vrs +=1
                exUtil = uTable[v[2]]
                inUtil = data[v[1]][v[2]]

                push!(coeff, exUtil)
                push!(utils,v => exUtil * inUtil)
                push!(vr_orders, v=>n_vrs)
                push!(poss, v)
            end
            push!(r, vr_orders[v])
        end
        push!(replace_indices, r)
    end
    vrs = Variables(n_vrs, coeff, poss)                # All variables of CSP model
    s_matrix = zeros(Int64, n_s_constraints, n_vrs)
    for r in 1:n_s_constraints
        s_matrix[r, replace_indices[r]] .= 1                      
    end
    s_matrix = s_matrix .* transpose(coeff)
    # println("matrix size:", size(s_matrix))
    s_constraints = ConstraintMatrix(n_s_constraints , s_matrix, fill(δ, n_s_constraints))


    # Establish constraint matrix for non-sensitive itemsets
    #========================================================================================#
    lower_bounds = Array{Float64, 1}()    # Lowerbounds to retain NSHUIs 
    remove = Array{UInt32, 1}()         # Some itemsets affected by hiding process but their utilities can not be lower than δ, we will not establish contraints to retain them.
    n_n_constraints = N_IT.n_rows      # Number of constraints constructed from N_IT table
    n_matrix = zeros(Int64, n_n_constraints, n_vrs)
    for i in 1: n_n_constraints
        n_itemset  = N_IT.itemsets[i]
        n_tidset     = N_IT.tidsets[i]
        tid_items = Array{Tuple{UInt32, UInt32},1}()
        vs = collect(Iterators.product(n_tidset, n_itemset))
        l = 0
        for v in vs 
            missing_util = get(utils, v, 0)
            l += missing_util 
            if missing_util != 0
                push!(tid_items, v)
            end

        end
        remaining_util = N_IT.utils[i] - l
        if remaining_util >= δ
            push!(remove, i)                              # Remove itemset from constraints
        end

        push!(lower_bounds, δ - remaining_util)           # Inequality 5 or 6 (correct it later)
        order_list = getindex.(Ref(vr_orders), tid_items)
        n_matrix[i, order_list] .= 1
        # n_constraints[product(i,order_list)] .= 1
    end

    n_matrix=n_matrix[setdiff(1:end, remove), :]
    !isempty(remove) && deleteat!(lower_bounds,  remove)
    n_matrix = n_matrix.* transpose(coeff)
    n_constraints = ConstraintMatrix(n_n_constraints, n_matrix, lower_bounds)
    # println(s_constraints)
    # println(n_constraints)
    return s_constraints, n_constraints, vrs
end

