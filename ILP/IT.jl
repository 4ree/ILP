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

mutable struct HI
    # The HI table data structure, each row represents an itemset
    n_rows::UInt32                      # Number of rows (or itemsets) in IT table
    itemsets
    tidsets
end

function deleteat!(table::HI, indxs)
    deleteat!(table.itemsets, indxs)
    deleteat!(table.tidsets, indxs)
    table.n_rows -= length(indxs)
end

function length(table::HI)
    return table.n_rows
end

HI() = HI(0, [], [])

mutable struct IT
    # The IT table data structure, each row represents an itemset
    n_rows::UInt32                      # Number of rows (or itemsets) in IT table
    utils::Array{Float64}                 # Util itemsets  
    sizes::Array{Int64}
    itemsets::Array{Set{UInt32}}
    tidsets::Array{Set{UInt32}}
end

function deleteat!(table::IT, indxs)
    deleteat!(table.itemsets, indxs)
    deleteat!(table.tidsets, indxs)
    deleteat!(table.utils, indxs)
    deleteat!(table.sizes, indxs)
    table.n_rows -= length(indxs)
end

function length(table::IT)
    return table.n_rows
end

IT() = IT(0, Array{Int64,1}(), Array{Int64,1}(), [], [] )

mutable struct G_IT
    n_rows :: UInt32
    utils :: Array{Float64,1}
    sizes :: Array{Int64,1}
    supports
    itemsets    #BitLists
    tidsets     #BitLists
end
G_IT() = G_IT(0, Array{Int64,1}(), Array{Int64,1}(), Array{Int64,1}(), [], [])
function deleteat!(table::G_IT, indxs)
    deleteat!(table.utils, indxs)
    deleteat!(table.sizes, indxs)

    keep_indxs = setdiff(1:table.n_rows, indxs)
    table.itemsets = table.itemsets[keep_indxs, : ]
    table.tidsets = table.tidsets[keep_indxs, :]

    table.supports = table.supports[keep_indxs]

    table.n_rows -= length(indxs)
end
function copyRows(table::G_IT, indxs)
    n_rows = length(indxs)

    utils = deepcopy(table.utils[indxs])
    sizes = deepcopy(table.sizes[indxs])

    itemsets = deepcopy(table.itemsets[indxs, :])
    tidsets = deepcopy(table.tidsets[indxs, :])
    supports = deepcopy(table.supports[indxs])
    # println(size(tidsets))
    # println(size(itemsets))
    # return G_IT(n_rows, utils,itemsets, sizes, [], [])
    return G_IT(n_rows, utils, sizes, supports, itemsets, tidsets)
end

