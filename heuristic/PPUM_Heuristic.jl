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

include("HHUIF.jl")
include("MSICF.jl")
include("MSU_MAU.jl")
include("MSU_MIU.jl")
struct HeuristicAlgorithm<:Algorithm
    name::String
    address_tid_and_item::Function 
end
name(al::HeuristicAlgorithm) = al.name


function checkSubsetOfSensitive(data, uTable, s_itemsets, s_utils, s_itemset,
        changeItem, changeTid, dec, dl)
    #= 
    Update Iₛ while modifying original database

    Parameters
    - dec: integer
    decreased utility value
    - delete: bool
    whether to delete the changeItem in changeTransaction or not
    =#
    
    for i in 1: length(s_itemsets)
        if issetequal(s_itemsets[i], s_itemset)
            s_utils[i]-=dec
            continue
        end
        if changeItem in s_itemsets[i]
            t = Set(k for k in keys(data[changeTid]))
            if s_itemsets[i] ⊆ t
                if dl
                    dec=uis(s_itemsets[i], changeTid, data, uTable)
                    s_utils[i] -= dec  
                end
            end
        end
    end

    return s_utils
end


function hideSIs(data, uTable, SHUIs, minUtil, func::Function)
    #' @param func::Function the heuristic function for finding item and
    # transaction that should be modified
    

    s_itemsets = SHUIs.itemsets
    s_utils = deepcopy(SHUIs.utils)
    for i in 1: length(s_itemsets)
        s_util=s_utils[i]
        (s_util <= 0) && continue #Only hide sensitive itemset that has util > 0

        s_itemset=s_itemsets[i]
        diff = s_util - minUtil 

        while diff > 0 && length(s_itemset) > 0

            changeItem, changeTid =func(data, uTable, s_itemsets, s_utils, s_itemset, minUtil)
            if (changeTid !=-1 && changeItem !=-1)

                total = u(changeItem, changeTid, data, uTable)
                if total < diff

                    uit = uis(s_itemset, changeTid, data, uTable)
                    dec = uit

                    s_utils = checkSubsetOfSensitive(data, uTable, s_itemsets, s_utils,  s_itemset, changeItem, changeTid, dec, true)
                    # data[changeTid][changeItem] = 0
                    delete!(data[changeTid],changeItem)

                    diff = diff - dec
                else

                    inU_dec = ceil(diff / uTable[changeItem])
                    s_utils = checkSubsetOfSensitive(data, uTable, s_itemsets, s_utils, s_itemset, changeItem,changeTid, diff, false)
                    data[changeTid][changeItem] = data[changeTid][changeItem] - inU_dec

                    if (data[changeTid][changeItem]<1) 
                        delete!(data[changeTid],changeItem)
                    end

                    diff = 0
                end
                if (length(keys(data[changeTid])) == 0)
                    delete!(data,changeTid) 
                end
            else
                # println("Failed")
                diff = 0
            end

        end
    end
    func = nothing
end


function run_algorithm(al::HeuristicAlgorithm, data, uTable, δ, SHUIs, HUIs)
    hideSIs(data, uTable, SHUIs, δ, al.address_tid_and_item)
    return
end

HHUIF=HeuristicAlgorithm("HHUIF", HHUIF_address_tid_and_item)
MSICF=HeuristicAlgorithm("MSICF", MSICF_address_tid_and_item)
MSU_MIU=HeuristicAlgorithm("MSU-MIU",MSU_MIU_address_tid_and_item)
MSU_MAU=HeuristicAlgorithm("MSU-MAU", MSU_MAU_address_tid_and_item)
