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

using Pkg
Pkg.add("JLD")
Pkg.build("HDF5")
Pkg.add("DataStructures")
Pkg.add("Distributions")
Pkg.add("StatsBase")
Pkg.add("JuMP")
Pkg.add("TimerOutputs")
Pkg.add("Plots")
Pkg.add("DataStructures")
ENV["GUROBI_HOME"] = "/data/runtimes/gurobi/linux64"
Pkg.add("Gurobi")
Pkg.build("Gurobi")
Pkg.add("CUDA")


