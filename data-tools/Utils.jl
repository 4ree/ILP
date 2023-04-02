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

@inline function uis(itemset, tid, data, uTable)
    #=Parameters
    -------------------------------
    itemset: hash set
    uTable: external utilities table
    -------------------------------
    Return utility of itemset in transaction

    =#
    utils=0
    for item in itemset
        util=u(item, tid, data, uTable)
        if util==0 return 0 end
        utils += util
    end
    return utils
end

@inline function u(item, tid, data, uTable)
    #=
    Parameters
    -------------------------------
    uTable: external utilities table
    -------------------------------
    Return utility of item in transaction
    =#
    inU=get(data[tid],item, 0)
    if inU == 0 return 0 end
    exU = get(uTable, item , 0)
    return inU*exU
end


@inline function totalUtil(item, data, uTable)
    # Compute total util of item in dataset
    total=0
    exU = get(uTable,item,0)
    if exU == 0 return 0 end
    for (tid, transaction) in data
        inU = get(transaction, item, 0)         
        total += inU * exU 
    end

    return total
end

@inline function totalItemsetUtil(itemset, data, uTable)
    # Compute total util of itemset in dataset
    total = 0
    for (tid, transaction) in data
        if itemset ⊆ collect(keys(transaction))
            total += uis(itemset, tid, data,uTable)
        end
    end
    return total
end
