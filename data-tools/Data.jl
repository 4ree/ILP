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

include("./BitTable.jl")
include("./HUIs.jl")
using DataStructures
using Statistics
using Distributions, StatsBase
using Random

@inline function getAbsolutePath(dir)
    #Get absolute path of dir
    cur = pwd()
    cd(dir)
    new_dir=pwd()
    cd(cur)
    return new_dir
end

function readQuantiativeData(dataset)
    n_items = dataset.n_items
    n_transactions = dataset.n_transactions
    data_path = dataset.data_path

    data=OrderedDict{UInt32, Dict{UInt32,Int64}}()
    table = zeros(Bool, n_transactions, n_items)
    sizes = zeros(UInt32, n_transactions)
    itemsets=[]
    t=Int64 #transaction
    t=1
    lines=readlines(data_path)
    for line in lines
        row=OrderedDict{UInt32,Int64}()
        line=rstrip(line)
        lineSplitted=split(line,' ')
        itemset = []
        for item_util in lineSplitted
            a=[parse(Int64, x) for x in split(item_util,':')]
            item = a[1]
            util = a[2]
            push!(a, item)
            push!(row, item => util)
            table[t,item] = true 
            sizes[t]+=1 
        end
        push!(itemsets,itemset)
        push!(data,unsigned(t) => row)

        t+=1
    end
    D = BitTable(table, sizes)
    return data, itemsets, D
end

function readUtable(table_path)
    #=Parameters
    ------------------------------
    table_path: external utility table 's path
    ------------------------------
    Return:
    uTable: a dictionary
    each key is a item
    each value is external utility of item
    =#

    uTable=Dict{UInt32, Float64}()
    f = readlines(table_path)
    for line in f
        temp=[parse(Float64,x) for x in split(line, ", ")]
        push!(uTable, temp[1]=> temp[2])
    end
    return uTable
end
function readData(dataset)
    table_path = dataset.table_path 
    data, itemsets, D = readQuantiativeData(dataset)
    uTable = readUtable(table_path)
    return data, uTable,  itemsets, D
end
function readData(data_path, table_path)
    uTable = readUtable(table_path)
    data=OrderedDict{UInt32, Dict{UInt32,Int64}}()
    t=Int64 #transaction
    t=1
    lines=readlines(data_path)
    for line in lines
        row=OrderedDict{UInt32,Int64}()
        line=rstrip(line)
        lineSplitted=split(line,' ')
        for item_util in lineSplitted
            a=[parse(Int64, x) for x in split(item_util,':')]
            item = a[1]
            util = a[2]
            push!(row, item => util)
        end
        push!(data,unsigned(t) => row)
        t+=1
    end
    return data, uTable
end
function readH(h_path)
    itemsets =Array{Set{UInt32},1}()
    lines = readlines(h_path)
    n_itemsets = length(lines)
    for i in 1:n_itemsets
        line=lines[i]
        line=rstrip(line,'\n')
        line=rstrip(line,' ')
        lineSplitted=split(line,' ')
        itemset = Set([parse(UInt32, x) for x in split(lineSplitted[1],':')])
        push!(itemsets,itemset)
    end
    return itemsets
end

function readH_set(h_path, n_items)
    # Read utility mining result

    itemsets=Array{Set{UInt32},1}()
    itemarrays = []
    sizes=Array{UInt32,1}()
    utils=Array{Float64,1}()
    lines=readlines(h_path)
    n_itemsets = length(lines)
    bit_lists = zeros(Bool, n_itemsets, n_items)
    for i in 1:n_itemsets
        line = lines[i]
        line=rstrip(line,'\n')
        line=rstrip(line,' ')
        lineSplitted=split(line,' ')
        util = parse(Float64,lineSplitted[2])
        itemset = Set([parse(UInt32, x) for x in split(lineSplitted[1],':')])
        itemarray = [parse(UInt32, x) for x in split(lineSplitted[1],':')]
        for item in itemset
            bit_lists[i, item] = true
        end
        size = length(itemset)

        push!(itemsets,itemset)
        push!(utils,util)
        push!(sizes,size)
        push!(itemarrays, itemarray)
    end
    return HUIs(itemsets, utils, sizes, bit_lists, itemarrays)
end

function savHset(h_sets, h_path)
    open(h_path,"w") do f
        len=length(h_sets)
        count=0
        for (itemset, util) in h_sets
            len_itemset = length(itemset)
            count  += 1
            i_count = 0
            for item in itemset
                i_count += 1
                print(f, item)
                if i_count != len_itemset
                    print(f,":")
                else
                    print(f," ")
                end

            end
            print(f,@sprintf("%f", util))

            if count!=len
                write(f,"\n") 
            end

        end
    end
    return
end
function savData(path, data)
    n_transactions=length(keys(data))
    open(path, "w") do f
        for (tid, transaction) in data
            t_len=length(transaction)
            for i in 1:t_len
                item= collect(keys(transaction))[i]
                util=transaction[item]
                print(f,"$item:$util")
                if i!= (t_len) print(f," ") end
            end
            if tid != n_transactions print(f,"\n")
            end
        end
    end
    return
end


function savHSet(itemsets, utils, path)
    open(path,"w") do f
        n_itemsets=length(itemsets)

        for i in 1:n_itemsets
            itemset = itemsets[i]
            n_item = length(itemset)
            count=0
            for item in itemset
                print(f,item)
                count+=1
                if count != n_item
                    print(f,":")
                end
            end
            print(f,@sprintf(" %f", utils[i]))

            if i != n_itemsets
                print(f,"\n")
            end
        end
    end
end

function load_performances_container(container_path::AbstractString, ds, als, load_from_path = true)
    #= Parameters
    ===================================================
    # container_path: container 's path
    # load_from_path: 
    Type: Boolean 
    Whether load container from path? 
    - 0: no
    - 1: yes
    =# 
    if load_from_path && isfile(container_path)
            container = load(container_path)
            performances = container["Performances"]
    else
        performances = Dict()
    end
    if get(performances, ds.name, -1) == -1
        push!(performances, ds.name => Dict())
    end
    push!(performances, ds.name => Dict())
    for al in als
        if get(performances[ds.name], al.name, -1) ==-1
            push!(performances[ds.name], al.name => Dict())
        end
        for mup in ds.mups
            if get(performances[ds.name][al.name], mup, -1) ==-1
                push!(performances[ds.name][al.name], mup => Dict())
            end
            for sip in ds.sips
                if get(performances[ds.name][al.name][mup], sip, -1) ==-1
                    push!(performances[ds.name][al.name][mup], sip => Evaluations())
                end
            end
        end
    end
    return performances
end

