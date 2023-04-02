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

function hide_sensitive_data(als, ds, performances, times=3)
    println("============================================================")
    println("------------------------------------------------------------")
    println("Dataset name: ", ds.name)
    println("|I|: ", ds.n_items)
    println("|D|: ", ds.n_transactions)
    println("Total utility: ", ds.total_util)

    for mup in ds.mups
        δ = ceil(Int, (ds.total_util * mup)/100)
        for sip in ds.sips
            println("------------------------------------------------------------")
            for al in als 
                output_path = outputPath(al,dirname(ds.origin_path) ,  ds.name, mup, sip)
                runtimes = []
                data = nothing
                # For debugging
                #-------------------------------------------#

                # data, uTable, itemset, D  = readData(ds)
                # if al.name!="G-ILP"
                # runtime = @elapsed run_algorithm(al, data, uTable, δ, SHUIs, HUIs)
                # else
                # runtime = @elapsed run_gpu_algorithm(al, D, uTable, δ, SHUIs, HUIs, data)
                # end

                #----------------------------------------#

                for i in 1:times
                    data, utable, itemset, D = nothing, nothing, nothing, nothing
                    SHUIs , HUIs = nothing, nothing
                    data, uTable, itemset, D  = readData(ds)
                    SHUIs  = readH_set(ds.s_paths[mup][sip], ds.n_items)
                    HUIs   = readH_set(ds.h_paths[mup], ds.n_items)
                    if length(SHUIs) == 0
                        runtime = 0
                    else
                        # runtime = @elapsed run_algorithm(al, data, uTable, δ, SHUIs, HUIs)
                        if al.name!="G-ILP"
                            runtime = @elapsed run_algorithm(al, data, uTable, δ, SHUIs, HUIs)
                            # runtime = 0  # for debugging purpose
                        else
                            runtime = @elapsed run_gpu_algorithm(al, D, uTable, δ, SHUIs, HUIs, data)
                        end
                    end
                    if runtime == 0.0 
                        push!(runtimes, runtime)
                        break
                    end
                    if i==1
                        savData(output_path, data)                           
                    else
                        push!(runtimes, runtime)
                    end
                    jump_model = nothing
                    model = nothing
                    # GC.gc(true)
                end
                println("MUP: ",mup,", SIP: ",sip, ", Algorithm ",al.name, ", Runtime: ", mean(runtimes))
                performances[ds.name][al.name][mup][sip].runtime = mean(runtimes)

            end
        end
    end

    mine_sanitized_data(als, ds)        # Mine sanitized data and evaluate hiding algorithms 
end
