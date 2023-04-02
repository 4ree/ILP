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

include("Data.jl")
include("Datasets.jl")

# using Plots

function readTransactionData(data_path)
    data=OrderedDict{UInt32, Set}()
    itemset=Array{UInt32,1}()
    t=UInt64 #transaction
    t=1
    lines=readlines(data_path)
    for line in lines
        row=Set{UInt32}()
     
        line=rstrip(line)
        lineSplitted=split(line,' ')
        for item in lineSplitted
            item=parse(UInt32, item)
            push!(row, item)
            if !(item in itemset)
                push!(itemset,item)
            end
        end
        push!(data,unsigned(t) => row)

        t+=1
    end
    # print(maximum(itemset))
    return data, itemset
end

function logNorm(x)
    
    μ = mean(log.(x) )
    
    σ=std(log.(x))


    pdf = (exp.(- (log.(x) .- μ ).^2 ./(2 * σ^2)) ./ (x .* σ .* sqrt(2*pi)))

    return pdf 
end
   
function genExternalUtilities(items, table_path, exUtils_range)
    n_items=length(collect(items))
    x=exUtils_range/100
    pdf=logNorm(x)
    pdf=pdf/sum(pdf)
   
    # p=plot(x,pdf, dpi=300)
    # savefig(p,"./externalUtilities.png")
    uTable = Dict{UInt32, Float64}()

    
    for i in 1:n_items
        item = items[i]
        exUtil=sample(x, ProbabilityWeights(pdf))
        push!(uTable, item => exUtil)
    end
    a= sort(collect(uTable), by=i -> i[1])
 
  
    open(table_path,"w") do f
        for i in 1:n_items
            item=a[i][1]
            exUtil=a[i][2]

            print(f,"$item, $exUtil")
            if i!= n_items
                print(f,"\n")
            end
        end
    end
    return uTable, maximum(items)
end

function genInternalUtilitiies(data, path, uTable, iUtils_range)
    totalUtil=0
    transaction_utils = Dict{UInt32, Float64}()
    n_transactions=length(keys(data))
    open(path, "w") do f
        for tid in keys(data)
            t_len=length(data[tid])
            t_util=0 
            internalUtilities=rand(iUtils_range, t_len)
            for i in 1: t_len
                transaction=collect(data[tid])
                item = transaction[i]
                inUtil=internalUtilities[i]
                print(f,"$item:$inUtil")
                t_util += uTable[item] * inUtil
                if i!= (t_len) print(f," ") end
            end
            if tid != n_transactions print(f,"\n")
            end
            push!(transaction_utils, tid => t_util)
            totalUtil += t_util 
        end
    end
    return totalUtil, transaction_utils, n_transactions
end

function genData(dataset, iUtils_range, exUtils_range)
    println("==================================")
    println("Dataset name: ",dataset.name)
    data, items=readTransactionData(dataset.origin_path)
    uTable, max_item=genExternalUtilities(items,dataset.table_path, exUtils_range)
    totalUtil, transaction_utils, n_transactions=genInternalUtilitiies(data, dataset.data_path, uTable, iUtils_range)

    dataset.total_util=totalUtil
    dataset.transaction_utils = transaction_utils
    dataset.n_items = max_item
    dataset.n_transactions = n_transactions

    println("Total utility: ",totalUtil)

end

function genSI(dataset)
    println("============================================================")
    println("Generate sensitive information for dataset: ", dataset.name) 
    for mup in dataset.mups
        for sip in dataset.sips
            print("MUP: ",mup, ", SIP: ",sip,", ")
            H = readH_set(dataset.h_paths[mup], dataset.n_items)  
            h_itemsets = H.itemsets
            h_utilities = H.utils
        
            n_h=length(h_itemsets)
            n_s= floor(Int,n_h*sip/100)

            print("Number of sensitive itemsets: ",n_s,"\n")

            indices = shuffle(1:n_h)
            s_idxs  = indices[1:n_s]

            s_itemsets  = h_itemsets[s_idxs]
            s_utilities = h_utilities[s_idxs]

            savHSet(s_itemsets, s_utilities, dataset.s_paths[mup][sip])
        end
    end
end
