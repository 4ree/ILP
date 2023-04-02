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

mutable struct BitTable 
    bit_lists::Array{Bool}
    sizes::Array{UInt32}
end
function deleteat!(table::BitTable, inds)
    deleteat!(table.bit_lists, inds) 
    deleteat!(table.sizes, inds)
end
function size(table::BitTable)
    return size(table.bit_lists)
end
