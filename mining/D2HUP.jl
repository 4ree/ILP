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

include("CAUL.jl")

function genAllSubset(caul, h_sets, n_rows, pos=1, prefix=nothing, prefix_util = 0)
    # When all row items are high utilty and support by same transactions 
    # we will generate all their extensions

    items = collect(keys(caul.rows))
    isnothing(prefix) && (prefix = caul.prefix)
    for i in pos:n_rows
        item = items[i]
        new_itemset = vcat(prefix, item)
        new_util= prefix_util + caul.rows[item].util 
        # new_util= 0 
        push!(h_sets, new_itemset => new_util)

        # Recursive call with increased itemset size
        genAllSubset(caul, h_sets, n_rows,i+1, new_itemset, new_util)
    end
    (pos == n_rows) && return 
end

function inititalize(data, uTable, minUtil, percentage = false)
    #' @param percentage::float utilty thresold

    n_transactions= length(data)
    
    twu = DefaultOrderedDict{UInt32, Float64}(0)
    supports=DefaultDict{UInt32, Float64}(0)
    iutils=DefaultOrderedDict{UInt32, Float64}(0)   # Item TWU
    TU= Dict{UInt32, Float64}()              # Transaction utility
    total_util = Float64
    total_util=0
    tw = OrderedDict{UInt32, OrderedDict{UInt32, Float64}}()#utility of item in transaction
    t_util=Float64
    
    for (tid, transaction) in data
        t_util=0 # transaction util
        push!(tw,tid => OrderedDict{UInt32, Float64}())
        for (item, internal_util) in transaction
            util = internal_util * uTable[item]
            iutils[item]+=util

            #Store data with transaction weighted utility (tw)
            push!(tw[tid], item => util) 
            t_util   += util
            supports[item] +=1
        end
        items=keys(transaction)
        for item in items 
            twu[item]+=t_util 
        end
        push!(TU, tid => t_util)
        total_util+=t_util # Data total utility
    end
    percentage && (minUtil= ceil(total_util*(minUtil)/100))
    println("Min util: ", minUtil)

    # Items sorted by ascending of total order instead of descending of total order
    # as descriptions in paper
    sorted_twu=OrderedDict{UInt32, Float64}(item => util for (item, util) in  
                                           sort(collect(twu), by=x->x[2]))
    for (tid, transaction) in tw
        sort!(transaction, by=x->twu[x])
    end

    # Filter item with twu < minUtil
    for (item, util) in sorted_twu
        if util<minUtil
            pop!(sorted_twu,item)
        end
    end
    n_transactions=length(tw)
    caul=initCAUL(sorted_twu, iutils, supports, n_transactions)

    # Compute remaining utility for caul rows
    for (tid, transaction) in tw
        # sort!(transaction, by=x->twu, )
        pivot = 0
        ltwu =0
        for (item, util) in transaction
            ltwu+=util
            row = get(caul.rows, item, -1)
            pivot+=1
            if row!=-1
                push!(row.pointers,tid => Pointer(util ,pivot, transaction))
                row.rutil += TU[tid] - ltwu
            end
        end
    end

    return caul, minUtil, TU , twu, total_util

end
function d2hup(caul , h_sets, TU, minUtil, twu)
    # printCAUL(caul)
    allHighUtility = true

    #Case 1
    allSupportAsPrefix = true
    (length(caul.rows) == 0) && return 
    for (item, row) in caul.rows

        (row.util < minUtil) && (allHighUtility = false)
 
        (row.support < caul.prefix_support) && (allSupportAsPrefix = false)

        (!(allHighUtility || allSupportAsPrefix)) && break
    end
    # if two conditions are met we will output each non-empty subset
    if (allHighUtility && allSupportAsPrefix) 
        # println("Case 1")
        genAllSubset(caul, h_sets, length(caul.rows))
        return
    end

    # case 2 singleton property
    # Fixed
    if allSupportAsPrefix
        delta = typemax(Float64)
        new_prefix = deepcopy(caul.prefix)           # We will loop through pointers (projected transactions) and compute util of child node 's item 
        s = 0
        
        # println("Prefix: ", new_prefix)
        # println("Prefix support: ", caul.prefix_support)
        # println("Prefix util: ", caul.prefix_util)
        delta = typemax(Float64)
        for (item, row) in caul.rows
            push!(new_prefix, item)
            util = row.util - caul.prefix_util
            (util < delta ) && (delta = util)
            s+=util
        end
        
        # s = sum(i_u) #sum of utility of promising items
        # println(s,"\t",delta)
        #output HUP
        # new_prefix= collect(new_prefix)
        pat_util = caul.prefix_util + s
        if (minUtil<= pat_util) && (pat_util < (minUtil + delta)) 
            push!(h_sets, new_prefix => pat_util)
            # println("Singleton ")
            return
        end
    end    

    # Otherwise 
    for (parent_item, row) in caul.rows
        # Gen new prefix
        new_prefix=vcat(parent_item, caul.prefix)
        new_prefix_support = row.support
        
        # Current node util
        parent_util = row.util

        # If current node represents a high utility itemset
        if (row.util>= minUtil)
            #output 
            push!(h_sets, new_prefix => parent_util) 
        end

        # Otherwise create child nodes for current nodes
        if (row.util + row.rutil) >= minUtil   # This lowerbound could be tighter 
            #Generate new rows

            new_prefix_util = row.util  
            new_caul = CAUL(new_prefix_support)
            for (tid, pointer) in row.pointers  # Each pointer represent a projected transaction
                transaction = pointer.transaction
                
                i_u = collect(transaction)

                n_items = length(i_u)
                pivot = pointer.pivot           # Current item position in transaction
           

                # A *projection* transaction divided by 2 hand-sides left and right
                # Compute remaining util of parent item (right hand-side because we 
                # sort each transaction by ascending of total order)

                # create new caul
                if parent_item == i_u[n_items][1]
                    continue
                end
                rtwu =  0
                for i in pivot+1 : n_items
                    rtwu+= i_u[i][2]
                end
                rutil = rtwu
                for j in (pivot +1): n_items
                    # Create new row (if not exists)
                    cell_item = i_u[j][1]
                    cell_util = i_u[j][2]

                    if get(new_caul.rows, cell_item, -1) == -1
                        push!(new_caul.rows, cell_item  => Row(0,0,0,0))
                    end

                    new_pointer_prefix_util =pointer.prefix_util + cell_util
                    push!(new_caul.rows[cell_item].pointers, tid => Pointer(new_pointer_prefix_util, j ,transaction))


                    new_caul.rows[cell_item].support+=1
                    new_caul.rows[cell_item].util += new_pointer_prefix_util
                    new_caul.rows[cell_item].itwu += rtwu
                    rutil -= cell_util
                    new_caul.rows[cell_item].rutil += rutil
                   
                end
            end
       
        
            new_caul.prefix = new_prefix
            new_caul.prefix_util = new_prefix_util 
            sort!(new_caul.rows, by = x->new_caul.rows[x].itwu) # Should we use new twu of projected transaction to sort it ?
            d2hup(new_caul, h_sets, TU, minUtil, twu)
        end

    end
end


function mining(data_path, table_path, minUtil, output, percentage=false, totalUtil = 0)
    data, uTable =readData(data_path, table_path)
    caul, minUtil, TU , twu, total_util= inititalize(data, uTable, minUtil, percentage)
    if (total_util != totalUtil)&&(totalUtil>0) 
        println("Data util mismatch") 
        println("Total dataset util read: ", total_util)
        println("Total dataset util in database: ", totalUtil)
    end
    h_sets=Dict{Array{UInt32}, Float64}()
    d2hup(caul, h_sets, TU, minUtil, twu)
    n_huis=length(h_sets)

    if n_huis==0 return end
    savHset(h_sets, output)
    return TU, twu    
    end
