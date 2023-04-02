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

using Printf
using JLD
include("./data-tools/Generator.jl")
include("./MineData.jl")
# ==================================================================================================
# Generate utility information and sensitive information (Only run once)

foodmart   = initDataset("foodmart",0, nothing, [0.061,0.062,0.063, 0.064], [0.5, 0.6 , 0.7, 0.8])
mushrooms  = initDataset("mushrooms",0,nothing,[10.5 ,11.0, 11.5, 12.0], [0.7, 0.8, 0.9, 1.0])
t25i10d10k = initDataset("t25i10d10k",0,nothing, [0.35, 0.36, 0.37, 0.38], [0.4, 0.5, 0.6, 0.7])
t20i6d100k = initDataset("t20i6d100k",0, nothing, [0.31,0.32,0.33,0.34], [1.0, 1.5, 2.0, 2.5])
datasets = [foodmart , mushrooms, t25i10d10k, t20i6d100k]

for i in 1:length(datasets)      # Mining and generate sensitive information
    ds = datasets[i]
    genData(ds, collect(1:10), collect(1:1000 ))
    mine_data(ds)                # Find high utility itemsets
    genSI(ds)                    # Generate sensitive information 
end

#= since foodmart is small, it is suitable for testing =#

# genData(foodmart, collect(1:10), collect(1:1000 ))
# mine_data(foodmart)               # Find high utility itemsets
# genSI(foodmart)                   # Generate sensitive information 
#= One more testing dataset
# genData(t20i6d100k, collect(1:10), collect(1:1000 ))
# mine_data(t20i6d100k)               # Find high utility itemsets
# genSI(t20i6d100k)                   # Generate sensitive information 

# ===================================================================================================
save("./datasets/datasets.jld", "datasets", datasets)
