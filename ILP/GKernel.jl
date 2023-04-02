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

using CUDA

function gpu_count(A, B, counts, n_A, n_B, n_bits)
    #= Count number similar items f|| each pair of itemsets between 2 bittable A, B 
    return count[a][b]: number of similar items of 2 itemsets A[a] and B[b] =#
    x = (blockIdx().x - 1)*blockDim().x+threadIdx().x
    y = (blockIdx().y - 1)*blockDim().y+threadIdx().y
    z = blockIdx().z*blockDim().z+threadIdx().z

    #load shared mem||y
    if (z>n_A) || (x>n_bits) || (y>n_B) return nothing end
    if (threadIdx().y==0)
        sA[threadIdx().x]=A[z][x]
    end
    syncthreads()

    if (sA[threadIdx().x]&B[y][x])

        CUDA.CUDA.@atomic counts[z,y] +=1
    end
    return nothing
end


function constructTable(d_H_sizes, d_S_sizes, 
        d_tidsets, d_supports,
        d_t_counts, d_s_counts, d_s_idxs,
        n_H,n_S,n_transactions)
    #Notice that indexes in Julia language start from 1
    h_idx = (blockIdx().x-1)*blockDim().x+threadIdx().x
    t_idx = (blockIdx().y-1)*blockDim().y+threadIdx().y
    s_idx = (blockIdx().z-1)*blockDim().z+threadIdx().z

    # Check dims
    # if (blockIdx().x == 1 && blockIdx().y == 1 && blockIdx().z==1
    # && threadIdx().x == 1 &&threadIdx().y == 1 &&
    # threadIdx().z == 1 )
    # dim_x = blockDim().x
    # dim_y = blockDim().y
    # dim_z = blockDim().z
    # @cuprintln("Block Dims: $dim_x, $dim_y, $dim_z")
    # end
    if ((t_idx>n_transactions) || (h_idx>n_H) ||
        (s_idx>n_S))
        return nothing
    end

    if (s_idx==1)
        if (d_t_counts[h_idx, t_idx]==d_H_sizes[h_idx])
            d_tidsets[h_idx, t_idx] = true
            # @inbounds @cuprintln(d_T_H[h_idx,t_idx])
            CUDA.@atomic d_supports[h_idx]+= 1
        end
    end

    if (t_idx==1)   
        count=d_s_counts[h_idx, s_idx]
        if count==d_H_sizes[h_idx] && count==d_S_sizes[s_idx]
            d_s_idxs[h_idx]= true
        end
    end
    return nothing
end

function preprocess_12(d_N_sizes, d_N_supports, d_S_supports, d_i_counts, d_t_counts, d_L, d_remove, n_N, n_S)
    s_idx = (blockIdx().x - 1)*blockDim().x+threadIdx().x
    n_idx = (blockIdx().y - 1)*blockDim().y+threadIdx().y

    if(n_idx>n_N) || (s_idx>n_S) return nothing end

    count=d_t_counts[n_idx, s_idx]
    if d_i_counts[n_idx, s_idx]>0 && count>0
        if d_i_counts[n_idx,s_idx]==d_N_sizes[n_idx] && count==d_N_supports[n_idx] && count==d_S_supports[s_idx]
            d_remove[n_idx] = true
        end

    else
        CUDA.@atomic d_L[n_idx] += 1
    end
    return nothing
end



function preprocess_3(d_N_sizes,d_N_supports,
        d_i_counts,d_t_counts,
        d_remove1,
        n_N)
    n2_idx = (blockIdx().x - 1)*blockDim().x+threadIdx().x
    n1_idx = (blockIdx().y - 1)*blockDim().y+threadIdx().y
    if (n1_idx>n_N) || (n2_idx>n_N) return nothing end
    if (n1_idx!=n2_idx)
        count=d_t_counts[n1_idx, n2_idx]
        if d_i_counts[n1_idx, n2_idx]==d_N_sizes[n1_idx] && count==d_N_supports[n1_idx] && count==d_N_supports[n2_idx]
            d_remove1[n2_idx]= true
        end
    end
    return nothing
end

