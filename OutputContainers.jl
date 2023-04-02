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

import Base.length
using JLD
include("./Configs.jl")
include("./Performance.jl")

# datasets =load("./Datasets/datasets.jld")["Datasets"] 

# Init performances container
performances = Dict()
# for i in 1:length(datasets)
    # ds =datasets[i]
    # push!(performances, ds.name => Dict())
    # # println(ds.name, " ",ds.sips)
    # for al in als
        # push!(performances[ds.name], al.name => Dict())
        # for mup in ds.mups
            # push!(performances[ds.name][al.name], mup => Dict())
            # for sip in ds.sips
                # push!(performances[ds.name][al.name][mup], sip => Evaluations())
            # end
        # end
    # end
# end
save("./Results/performances.jld","Performances",performances)
