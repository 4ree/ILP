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

include("SideEffects.jl")

function evaluate_side_effects(als, ds, performances)
    println("============================================================")
    println("Dataset ", ds.name)
    println("------------------------------------------------------------")
    for mup in ds.mups

        h_path = ds.h_paths[mup]
        for sip in ds.sips
            s_path = ds.s_paths[mup][sip]
            for  al in als
                println("MUP: ", mup, ", SIP: ",sip, ", Algorithm ", al.name)
                new_h_path=minedPath(al, dirname(ds.origin_path),ds.name, mup, sip)
                if !isfile(new_h_path)
                    performances[ds.name][al.name][mup][sip].HF = 1
                    performances[ds.name][al.name][mup][sip].MC = 1
                    performances[ds.name][al.name][mup][sip].HF = 1
                    break
                end
                HF = HidingFailure(s_path, new_h_path) 
                MC = MissingCost(s_path, h_path, new_h_path)
                AC = ArtificialCost(s_path,h_path, new_h_path)
                performances[ds.name][al.name][mup][sip].HF = HF
                performances[ds.name][al.name][mup][sip].MC = MC
                performances[ds.name][al.name][mup][sip].HF = HF
                println("Hiding Failure: ", @sprintf("%.3f", HF))
                println("Missing Cost: ", @sprintf("%.3f", MC))
                println("Artificial Cost: ", @sprintf("%.3f", AC))
                println("---------------------------------------------------------")
                new_h_paths = nothing
            end
        end
        println("---------------------------------------------------------")
    end
end
