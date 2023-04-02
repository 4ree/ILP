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

include("./GKernel.jl")
function countIntersection(A, B, n_bits, d_A=nothing, d_B=nothing)

    #Count intersection of 2 bitTables 

    if d_A == nothing
        d_A = CuArray(A)
        # println(size(d_A))

    end 
    if d_B == nothing
        d_B = CuArray(B)
        # println(size(d_B))
    end 
    d_counts =  d_A * transpose(d_B)
    return d_counts, d_A, d_B
end    

function parallel_construct_tables( 
        H, S, D)
    h_itemsets = H.bit_lists
    s_itemsets = S.bit_lists

    #check dims
     # println(size(H.utils))
    # println(size(S_G_IT.bit_lists))
    # println(size(D.bit_lists))

    n_H = size(h_itemsets)[1]
    n_S = size(s_itemsets)[1]
    n_items = size(h_itemsets)[2]
    n_transactions = size(D)[1]
    # println("Number of high-utility itemsets: ",n_H )
    # println("Number of sensitive high-utility itemsets: ",n_S )
    # println("Number of transaction: ",n_transactions)
    # println("Number of items: ", n_items)

    d_tidsets = CUDA.zeros(Int32, (n_H, n_transactions)) # tidsets of HUIs represents as bitLists
    d_supports= CUDA.zeros(Int32, n_H)

    d_s_counts,d_H,_=countIntersection(h_itemsets,s_itemsets,n_items)
    d_t_counts,_,_=countIntersection(h_itemsets,D.bit_lists,n_items,d_H)
    #checking parameters
    # println("d_tidsets",size(d_tidsets))
    # println("d_t_counts ", size(d_t_counts))

    d_s_idxs=CUDA.zeros(Bool, n_H)

    # println(size(d_s_idxs))

    d_H_sizes=CuArray(H.sizes) #HUI sizes
    d_S_sizes=CuArray(S.sizes) #SHUI sizes
    TPB=16
    blockSize = (TPB, TPB, 1)
    blockspergrid_x = ceil(Int64,n_H / blockSize[1])
    blockspergrid_y = ceil(Int64,n_transactions/ blockSize[2])
    blockspergrid_z = ceil(Int64,n_S/ blockSize[3])
    gridSize = (blockspergrid_x, blockspergrid_y,blockspergrid_z)

    # Checking parameters
    # println(n_H," ", n_S," ", n_transactions)
    # println(gridSize)
    # println(blockSize)
    @cuda threads=blockSize blocks=gridSize constructTable(d_H_sizes, d_S_sizes, 
                                                           d_tidsets, d_supports,
                                                           d_t_counts, d_s_counts, d_s_idxs,
                                                           n_H,n_S,n_transactions)

    # println(filter(x->x>0, d_supports))

    # println(s_idxs)
    # println(size(s_idxs)) 
    s_idxs = Array(d_s_idxs)
    indxs =findall(x -> x==1, s_idxs)

    #Transfer GMEM to MEM
    # supports = Array(d_supports)
    tidsets = Array(d_tidsets)
    # println(supports)
    # println(size(tidsets))

    H_G_IT = G_IT(n_H, H.utils, H.sizes, d_supports, H.bit_lists,
                  tidsets)
    # println(size(d_T_H))
    S_G_IT=copyRows(H_G_IT, indxs)

    deleteat!(H_G_IT, indxs) 

    return H_G_IT, S_G_IT,  indxs
end
function find_special_sets_G(N_G_IT, S_G_IT)
    n_N=N_G_IT.n_rows
    n_S=S_G_IT.n_rows
    n_items = size(N_G_IT.itemsets)[2]
    n_transactions = size(N_G_IT.tidsets)[2]

    d_remove=CUDA.zeros(Bool, n_N)
    d_L=CUDA.zeros(Int32, n_N)

    #Checking matrix dims
    # println(size(N_G_IT.itemsets))
    # println(size(S_G_IT.itemsets))
    d_i_counts, d_N,_=countIntersection(N_G_IT.itemsets,S_G_IT.itemsets,n_items)
    d_t_counts, d_N_tidsets,_=countIntersection(N_G_IT.tidsets,S_G_IT.tidsets,n_transactions)

    #check matrix dims
    # println(size(d_i_counts))
    # println(size(d_t_counts))

    #Copy data to GMEM
    d_N_sizes = CuArray(N_G_IT.sizes)
    # d_N_supports = CuArray(N_G_IT.supports)
    # d_S_supports = CuArray(S_G_IT.supports)

    #check dims
    # println(size(d_N_sizes))
    # println(size(d_N_supports))
    # println(size(d_S_supports))
    TPB=16
    blockSize = (TPB, TPB)
    blockspergrid_x = ceil(Int64,n_S/ blockSize[2])
    blockspergrid_y = ceil(Int64,n_N/ blockSize[1])
    gridSize = (blockspergrid_x, blockspergrid_y)
    @cuda threads = blockSize blocks = gridSize preprocess_12(d_N_sizes, N_G_IT.supports, S_G_IT.supports, 
                                                              d_i_counts, d_t_counts, 
                                                              d_L, d_remove, n_N, n_S)


    synchronize()
    #free memory
    d_i_counts= nothing
    d_t_counts= nothing

    d_i_counts=CUDA.zeros(Int32, n_N,n_N)
    d_t_counts=CUDA.zeros(Int32, n_N,n_N)
    d_remove1=CUDA.zeros(Bool, n_N)

    d_i_counts,_,_=countIntersection(nothing,nothing,n_items, d_N, d_N)
    d_t_counts,_,_=countIntersection(nothing, nothing,n_transactions, d_N_tidsets, d_N_tidsets)
    # #check matrix dims
    # println(size(d_i_counts))
    # println(size(d_t_counts))
    synchronize()
    TPB=16
    blockSize = (TPB, TPB)
    blockspergrid_x = ceil(Int64,n_N/ blockSize[1])
    blockspergrid_y = ceil(Int64,n_N/ blockSize[2])
    gridSize = (blockspergrid_x, blockspergrid_y)
    @cuda threads = blockSize blocks = gridSize preprocess_3(d_N_sizes,N_G_IT.supports,
                                                             d_i_counts,d_t_counts,
                                                             d_remove1, n_N)


    #get remove idxs
    L = findall(x -> x==n_S, Array(d_L))
    remove = findall(x->x==1, Array(d_remove))
    remove1 = findall(x->x==1, Array(d_remove1))
    remove_idxs=sort(remove ∪ remove1 ∪ L)

    #debuging purposes
    # println(remove_idxs)

    # remove_idxs=cp.hstack((remove_idxs,L))
    # remove_idxs=np.unique(cp.asnumpy(remove_idxs))

    deleteat!(N_G_IT, remove_idxs)

    # #free memory
    # d_i_counts=None
    # d_t_counts=None
    # d_remove1=None
    # d_N=None
    # d_N_tidsets=None
    # d_L=None
    return N_G_IT, remove_idxs
end
function  bitLists_2_sets(bit_lists)
    ret =[]
    dims = size(bit_lists)
    for i in 1:dims[1]
        set = []
        for j in 1:dims[2]
            if bit_lists[i,j] == true
                push!(set, j)
            end
        end
        push!(ret, set)
    end
    return ret

end
function  establish_constraints_G(N_G_IT, S_G_IT, data, uTable, δ)
    n_vrs = 0                                               # Number of variables
    utils = Dict{Tuple{UInt32, UInt32}, Float64 }()           # Variable utils
    coeff = Array{Float64,1}()                                  # Coefficent of variables
    vr_orders = Dict{Tuple{UInt32, UInt32} , Int64 }()      # Order of variables in variable list
    poss = Array{Tuple{Int64, Int64},1}()                   # Positions of variables in data 

    n_s_constraints = S_G_IT.n_rows                          # Number of constraints constructed from S_IT table 
    # s_itemsets = [findall(x -> x=1, itemset) for itemset in s_bitlists]
    s_itemsets= bitLists_2_sets(S_G_IT.itemsets)
    s_tidsets = bitLists_2_sets(S_G_IT.tidsets)
    n_itemsets= bitLists_2_sets(N_G_IT.itemsets)
    n_tidsets = bitLists_2_sets(N_G_IT.tidsets)

    replace_indices=Array{Array{UInt32,1},1}()                                      # Matrix indices to replace (abstract array)
    for c_idx in 1: n_s_constraints
        itemset = s_itemsets[c_idx]
        tidset  = s_tidsets[c_idx]
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
    lower_bounds = Array{Float64, 1}()    # Lowerbounds to retain NSHUIs 
    remove = Array{UInt32, 1}()         # Some itemsets affected by hiding process but their utilities can not be lower than δ, we will not establish contraints to retain them.
    n_n_constraints = N_G_IT.n_rows      # Number of constraints constructed from N_IT table
    n_matrix = zeros(Int64, n_n_constraints, n_vrs)
    for i in 1: n_n_constraints
        n_itemset  = n_itemsets[i]
        n_tidset     = n_tidsets[i]
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
        remaining_util = N_G_IT.utils[i] - l
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
    return s_constraints, n_constraints, vrs, N_G_IT
    # println(s_itemsets)
end
