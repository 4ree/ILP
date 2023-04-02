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

# include("./MiningAlgo/HUI_Miner.jl")
include("./mining/D2HUP.jl")

function mine_data(ds)
    println("===========================================================")
    println("Mining ", ds.name)
    for mup in ds.mups
        println("------------------------------------------------------")
        println("MUP: ", mup)
        mining(ds.data_path, ds.table_path, mup, ds.h_paths[mup], true, ds.total_util)

    end
end

function mine_sanitized_data(als, ds)
    println("============================================================")
    println("Mining ", ds.name)
    println("------------------------------------------------------------")
    for mup in ds.mups
        for sip in ds.sips 
            for  al in als
                println("MUP: ", mup, ", SIP: ",sip, ", Algorithm ", al.name)
                sanitized_data_path = outputPath(al, dirname(ds.origin_path),ds.name, mup, sip)
                mined_path = minedPath(al, dirname(ds.origin_path),ds.name, mup, sip)
                mining(sanitized_data_path, ds.table_path, ceil(Int, (mup*ds.total_util)/100), mined_path, false)
            end
        end
        println("---------------------------------------------------------")
    end
end
