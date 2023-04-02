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

function construct_tables_PPUM_ILP(h_itemsets, h_utils, s_itemsets,  data)
    # 1st phase: Constructs tables stored relationship of HUIs and transactions support them
    #     println(length(s_itemsets))
    SHI = HI()
    NHI = HI()            
    for i in 1: length(h_itemsets)
        itemset = h_itemsets[i]
        util = h_utils[i]
        tids=Array{UInt32, 1}()
        # Find transactions that support itemset 
        for (tid, transaction) in data
            trans = collect(keys(transaction))
            if itemset ⊆ trans
                push!(tids, tid)
            end
        end
        if itemset ∈ s_itemsets
            push!(SHI.itemsets, itemset)
            push!(SHI.tidsets, tids)
            SHI.n_rows +=1
        else
            push!(NHI.itemsets, itemset)
            push!(NHI.tidsets, tids)
            NHI.n_rows+=1
        end
    end
    return NHI, SHI
end

function find_special_sets_PPUM_ILP(NHI, SHI, data, uTable, δ)
    # 2nd phase: find bound-to-lose itemsets and itemsets that will be not affected by hiding process
    remove = Array{UInt32,1}()
    for i in 1: NHI.n_rows
        L = 0 
        n_itemset  = NHI.itemsets[i]
        n_tidset = NHI.tidsets[i]
        for j in 1: SHI.n_rows
            s_itemset  = SHI.itemsets[j]
            s_tidset = SHI.tidsets[j]
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

        if L == SHI.n_rows
            push!(remove, i)                # itemset that will not be affected by hiding process
        end

        # 3rd phase: find redundant itemsets
        for k in 1:NHI.n_rows
            n1_itemset = NHI.itemsets[k]
            n1_tidset = NHI.tidsets[k]
            if n_itemset!=n1_itemset &&  n1_itemset ⊆ n_itemset && n1_tidset ⊆ n_tidset
                push!(remove, i)
                break
            end
        end

    end
    # for i in 1:length(NHI)
    # println("Itemset ",i,": ", NHI.itemsets[i], " Tidset: ", NHI.tidsets[i])
    # end
    # println("Sensitive itemset: ", SHI.itemsets[1]," Tidset: ", S_HIT.tidsets[1] )
    deleteat!(NHI, unique(remove))
    # println("n_remove: ",length(unique(remove)))
    # println("r_itemsets: ",NHI.n_rows)
    return remove
end

function establish_constraints_PPUM_ILP(NHI, SHI, data, uTable, δ)

    # Establish variables and constraint matrix for sensitive itemsets
    #========================================================================================#
    n_vrs = 0                                               # Number of variables
    utils = Dict{Tuple{UInt32, UInt32}, Int64 }()           # Variable utils
    coeff = Array{Int64,1}()                                  # Coefficent of variables
    vr_orders = Dict{Tuple{UInt32, UInt32} , Int64 }()      # Order of variables in variable list
    poss = Array{Tuple{Int64, Int64},1}()                   # Positions of variables in data 

    n_s_constraints = SHI.n_rows                          # Number of constraints constructed from S_HIT table 
    replace_indices=Array{Array{UInt32,1},1}()                                      # Matrix indices to replace (abstract array)
    for c_idx in 1: n_s_constraints
        itemset = SHI.itemsets[c_idx]
        tidset  = SHI.tidsets[c_idx]
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
    s_constraints = ConstraintMatrix(n_s_constraints , s_matrix, fill(δ, n_s_constraints))


    # Establish constraint matrix for non-sensitive itemsets
    #========================================================================================#
    lower_bounds = Array{Int64, 1}()    # Lowerbounds to retain NSHUIs 
    remove = Array{UInt32, 1}()         # Some itemsets affected by hiding process but their utilities can not be lower than δ, we will not establish contraints to retain them.
    n_n_constraints = NHI.n_rows      # Number of constraints constructed from NHI table
    n_matrix = zeros(Int64, n_n_constraints, n_vrs)
    for i in 1: n_n_constraints
        n_itemset  = NHI.itemsets[i]
        n_tidset     = NHI.tidsets[i]
        tid_items = Array{Tuple{UInt32, UInt32},1}()
        l = 0
        for j in 1: n_s_constraints
            s_itemset = SHI.itemsets[j]
            s_tidset = SHI.tidsets[j]

            item_intersection = n_itemset ∩ s_itemset
            tid_intersection = n_tidset ∩ s_tidset
            vs  =  collect(Iterators.product(tid_intersection, item_intersection)) 

            for v in vs 
                exUtil = uTable[v[2]]
                inUtil = data[v[1]][v[2]]
                missing_util = inUtil * exUtil
                l += missing_util 
                if missing_util!=0
                    push!(tid_items, v)
                end
            end
        end
        println(l)
        n_util = totalItemsetUtil(n_itemset, data, uTable)
        remaining_util = n_util  - l
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
    println(s_constraints)
    println(n_constraints)
    return s_constraints, n_constraints, vrs
end

