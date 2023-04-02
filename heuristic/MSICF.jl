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

function MSICF_address_tid_and_item(data, uTable, 
                            s_itemsets, s_utils, 
                            s_itemset, min_util)

    max_util = 0 # Remove util = 0 cases 
    maxIc = 0
    changeItem = -1 
    changeTid = -1
    ic = DefaultDict(0)  # conflict count
    for i in 1:length(s_itemsets)

        sv = s_utils[i]
        itemset = s_itemsets[i]

        for item in itemset

                ic[item] +=1
    
        end

    end

    
    for (item, iic) in ic

        if (iic > maxIc) && (item in s_itemset)
            maxIC = iic
            changeItem = item
        end

    end

    for (tid,transaction) in data
        t= Set(keys(transaction))
        if s_itemset ⊆ t
            iu = u(changeItem, tid, data, uTable)
            if iu > max_util 
                max_util = iu
                changeTid = tid 
            end

        end

    end
    return changeItem, changeTid 
end
