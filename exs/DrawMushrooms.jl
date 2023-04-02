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

include("../DrawGraphs.jl")
container=load("../res/performances.jld")
performances = container["Performances"]
# println(keys(performances))
ds=load("../datasets/mushrooms.jld")["Dataset"] 
al_names = keys(performances[ds.name])
mup = ds.mups[length(ds.mups)]
sip =ds.sips[length(ds.sips)]
scene1(performances, ds, al_names, mup)
scene2(performances, ds, al_names, sip)
