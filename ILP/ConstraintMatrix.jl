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

struct Variables
    n_vrs::UInt32
    coeff::Array{Float64,1}    # Coefficent of variables
    poss::Array{Tuple{UInt32, UInt32}}            # Positions of varibales in data
end
mutable struct ConstraintMatrix
    n_constraints::UInt32                  # Number of constraintss
    matrix::Array{Float64}               # Array of constraints (not matrix) 
    bounds::Array{Float64}                   # Lower (or upper) bounds of constraints
end

function length(vrs::Variables)
	return vrs.n_vrs
end
function length(matrix::ConstraintMatrix)
    return matrix.n_constraints
end
function size(matrix::ConstraintMatrix)
    return size(matrix.matrix)
end 
