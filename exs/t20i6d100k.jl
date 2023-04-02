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

# using Plots
using JLD
using Printf
import Base.length
import Base.size
import Base.deleteat!

include("./Tools/Generator.jl")
# include("./Tools/Data.jl")
include("./Algorithm.jl")
include("./Tools/Utils.jl")
include("./Configs.jl")
include("HideSData.jl")
include("Evaluate.jl")
include("MineData.jl")
include("Performance.jl")
include("containers.jl")
#Load generated data
# datasets =load("../datasets/datasets.jld")["Datasets"] 
# container = load("../res/performances.jld")

ds_container_path = "../datasets/t20i6d100k.jld"
container_path = "../res/performances.jld"

if isfile(ds_container_path)
    ds = load(ds_container_path)["Dataset"]
else
    ds = initDataset("t20i6d100k",0, nothing, [0.31,0.32,0.33,0.34], [1.0, 1.5, 2.0, 2.5])
    genData(ds, collect(1:10), collect(1:1000))
    mine_data(ds)                # Find high utility itemsets
    genSI(ds)                    # Generate sensitive information 
    save(ds_container_path, "Dataset", ds)
end
performances = load_performances_container(container_path, ds, als)
hide_sensitive_data(als, ds, performances)
evaluate_side_effects(als, ds, performances)     
save(container_path,"Performances",performances)
