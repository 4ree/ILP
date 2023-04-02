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

struct HUIs
    itemsets::Array{Set{UInt32}}
    utils::Array{Float64}
    sizes::Array{UInt32}
    bit_lists::Array{Bool}
    itemarrays::Array{Array{UInt32}}
end
function length(huis::HUIs)
    return length(huis.sizes)
end
