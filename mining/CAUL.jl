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

# Boost performance later

mutable struct  Pointer
    # Represent a projected transaction indexed by tid of transaction

    # A pivot is used to separate transaction into to two handside part
    # Right handside of transaction is projected transaction

    prefix_util::Float64    # Prefix util of item  *in transaction*
    pivot::UInt32           # Split position
    transaction::OrderedDict{UInt32, Float64} # Whole transaction
end
mutable struct Row
    # Represent a caul row, indexed by parent item
    support::UInt32     # Support of item 
    util::Float64        # Whole itemset util (including prefix util) 
    itwu::Float64        # TWU of row in *projected transaction
    rutil::Float64       # Remaining utility of row
    pointers::OrderedDict{UInt32, Pointer }    #Projected transaction
end

Row(support, utils, itwu, rutil)=Row(support,utils,itwu,rutil, OrderedDict{UInt32, Pointer}())

mutable struct CAUL
    prefix::Array{UInt32, 1}        # prefix of rows 
    prefix_support::UInt32          # support of prefix          
    prefix_util::Float64             # utility of prefix
    rows::OrderedDict{UInt32, Row}  # caul rows
end

CAUL(support)=CAUL(Array{UInt32,1}(),support, 0,OrderedDict{UInt32, Row}())

function initCAUL(twu, iutils, supports, n_transactions)
    # CAUL of prefix {}
    caul=CAUL(n_transactions)
    rows=OrderedDict{UInt32, Row}() # each row stored by a dictionary indexed by item
    for (item, itwu) in twu
        # Remaining util of each row will be computed later
        push!(rows, item => Row(supports[item], iutils[item], itwu, 0))
    end
    caul.rows=rows
    return caul
end

function printCAUL(caul)
    println("Prefix ", caul.prefix, " prefix util ", caul.prefix_util)
    for (item, row) in caul.rows
        println("\tItem ", item, " support ", row.support," util ", row.util, " rutil ", row.rutil )
        println("\tSupport transactions: ", collect(keys(row.pointers))) 
    end
    println() 
end
