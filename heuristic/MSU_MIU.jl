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

function MSU_MIU_address_tid_and_item(data, uTable, 
                            s_itemsets, s_utils, 
                            s_itemset, min_util)
    maxMSU=0
    minUtil=Inf
    changeItem = -1
    changeTid = -1
    for (tid, transaction) in data
        t = Set(keys(transaction))
        if s_itemset ⊆ t
            msu=0
            for item in s_itemset
                iq=data[tid][item]
                if iq<1
                    msu=0
                    break
                end
                iu=iq*uTable[item]
                msu+=iu
            end
            if msu> maxMSU
                maxMSU=msu
                changeTid=tid
            end
        end
    end
    if changeTid == -1 
        return changeItem, changeTid
    end
    for item in s_itemset 
        iu = u(item, changeTid, data, uTable)
        if iu < minUtil && iu !=0
            minUtil = iu
            changeItem=item
        end
    end
    return changeItem, changeTid
end
