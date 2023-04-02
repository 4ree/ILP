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

include("UtilityList.jl")


@inline function gen_K_itemset(prefix, b)
    #Generate new itemset by 2 k-1 itemsets: a and b
    ret=vcat(prefix,b)
    return ret
end

function initUtilityList(items)
    #=Init utility list
    ------------------------
    itemset: represented by tuple
    iutils: itemset iutils in transactions
    rutils: itemset rutils in transaction
    tidset: a python set of tids of transactions support itemset=#
    uL=UtilityList()
    for item in items
        addItem2Ul(uL,item)
    end
    return uL
        
end

function construct_1_utilityList(data, uTable, minUtil, h_sets, percentage=false)
    
    n_transactions= length(data)
    twu = DefaultOrderedDict{Int64, Int64}(0)

    TU= Dict{Int64, Int64}()#transaction utility
    total_util=0
    tw= Dict{Int64, Dict{Int64, Int64}}() #utility of item in transaction
    t_utils=UInt64


    for (tid, row) in data
        t_utils=0
        for (item, internal_util) in row
    
            util = internal_util * uTable[item]
            if isnothing(get(tw, tid, nothing))
                push!(tw,tid => Dict(item=>util))
            else
                push!(tw[tid], item=>util)
            end
            t_utils   += util
            twu[item] += util
        end
        push!(TU, tid => t_utils)
        total_util+=t_utils
    end


    items=[item for (item, value) in sort(collect(twu), by=x->x[2])]
    
    # print("Order: \n")
    # for i in items
    #     print(i, "=>", twu[i],"\n")
    # end

    uL=initUtilityList(items)
    for (tid, transaction) in data
        t_utils=0
        # for (item, value) in sort(collect(transaction), by= x ->twu[x])
        for item in items
            if item in keys(transaction)
                iutils=tw[tid][item]
                t_utils+=iutils

                rutils=TU[tid]- t_utils
                
                addElement(uL,item, tid, iutils, rutils)
            end
        end
    end
    if percentage minUtil=total_util/100 * minUtil end
    
    for (item, values) in uL.data
        t_iutils=values.t_iutils
        t_rutils=values.t_rutils
        if t_iutils > minUtil -1
            push!(h_sets, [item]=> t_iutils)
        end
        if t_iutils + t_rutils <minUtil
            values.prune =true
        end
    end
    return uL, total_util, minUtil
end

@inline function construct_K_utilityList(uLs, minUtil, h_sets, k)
    # Contruct k-utilityList from k-1 - utilityList


    new_uLs=Array{UtilityList,1}()

    for uL in uLs
        data=uL.data
        items=collect(keys(data))
        n=length(items)
        
    
        if n==0 continue end
        for i in 1: n-1
        
            a=items[i]
            if data[a].prune
                continue
            end
            
            new_prefix = vcat(uL.prefix, a)
            new_uL=UtilityList(data[a].elements,new_prefix,OrderedDict{Int64,Data}())
        
            for j in i+1:n
                
                b=items[j]
                # println(a," ", b)
                
                t_a=data[a].tidset
                t_b=data[b].tidset

                trans=intersect(t_a, t_b) # transactions that support both a and b
                if length(trans) == 0 continue end
     
                addItem2Ul(new_uL, b)
                
                for t in trans
                    iutils=data[a].elements[t].iutils + data[b].elements[t].iutils
                    if k>2 
                        iutils-= uL.prefix_util[t].iutils 
                    end

                    rutils = data[b].elements[t].rutils    #rutils definitely is the rutils of itemset b

                    addElement(new_uL,b,t, iutils,rutils)
                end
                
                new_itemset= gen_K_itemset(new_prefix, b)
                utils=new_uL.data[b].t_iutils
                r_utils=new_uL.data[b].t_rutils
        
                if utils > minUtil-1 
                    push!(h_sets, new_itemset => utils) 
                end
                if utils + r_utils < minUtil
                    new_uL.data[b].prune = true
                end
            end 
            # prune(new_uL, minUtil)
            push!(new_uLs, new_uL)
        end
    end
    uLs=nothing
    return new_uLs
end
function mining(data_path, table_path, minUtil, output, percentage=false)

    data, uTable, _=readData(data_path, table_path)
    h_sets=Dict{Array{Int64}, Int64}()

    uL, data_util, minUtil=construct_1_utilityList(data,uTable, minUtil, h_sets, percentage)
   
    # for (item, value) in uL.data
    #     print("Item: ",item , " RUtils: ",value.t_rutils, "\n")
    # end
    uLs=[uL]
    k=2
    while length(uLs) != 0
        new_uLs=construct_K_utilityList(uLs ,minUtil, h_sets, k)
        uLs=0
        uLs=deepcopy(new_uLs)
        new_uLs=0
        k=k+1
    end
    n_huis=length(h_sets)
    if n_huis==0 return end
    savHset(h_sets, output)
   
    return
end
