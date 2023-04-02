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

struct Element
    iutils::Int64
    rutils::Int64
end

mutable struct Data  
    t_iutils::Int64
    t_rutils::Int64

    tidset:: Set{Int64}
    elements::Dict{Int64,Element}
    prune::Bool
end
mutable struct UtilityList
    prefix_util::Any
    prefix::Array{Int64}
    data:: OrderedDict{Int64,Data}
    
end
Data() = Data(0, 0, Set{Int64}(), Dict{Int64,Element}(), false)
UtilityList()=UtilityList(nothing,[],OrderedDict{Int64,Data}())
function addItem2Ul(uL, item)
    push!(uL.data, item =>  Data())
end
function addElement(uL, item, tid, iutils, rutils)
    d=uL.data[item]
    d.t_iutils+=iutils
    d.t_rutils+=rutils
    push!(d.elements, tid => Element(iutils, rutils))
    push!(d.tidset, tid)
end

function printSet(s)
    print("[")
    for i in s
        print(i)
        print(" ")
    end
    print("]")
end
function printULValues(utilityList)
    println("")
    print("\titemset: ")
    printSet(utilityList.itemset)
    println("")
    println("\tTotal Utils: ", utilityList.t_iutils)
    println("\tTotal Remaining Utils: ", utilityList.t_rutils)
    print("\tTidset: ")
    printSet(utilityList.tidset)
    println("")
    println("\tPrune: ", utilityList.prune)
    println("\tNext: ",utilityList.next)
end
function printUL(uL)
    for (key, value) in uL
        print("Prefix :", key) 
        print(printULValues(value))
    end
end
function printDict(dict)
    for (key, value) in dict
        println(@sprintf("%d => %d",key, value))
    end
end
