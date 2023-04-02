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

function HidingFailure(s_path, new_h_path)
    Iₛ = readH(s_path)
    Iₕ = readH(new_h_path)
    α = 0 
    for itemset in Iₛ
        if itemset ∈ Iₕ
            α += 1
        end
    end
    return α / length(Iₛ)
end

function MissingCost(s_path, h_path, new_h_path)
    Iₛ  = readH(s_path)
    Iₕ  = readH(h_path)
    Iₕ₁ = readH(new_h_path)
    β = 0 
    for itemset in Iₕ
        if (itemset ∉ Iₕ₁) && (itemset ∉ Iₛ)
            β += 1
        end
    end
    return β / (length(Iₕ) - length(Iₛ))
end


function ArtificialCost(s_path, h_path, new_h_path)
    Iₛ = readH(s_path)
    Iₕ = readH(h_path)
    Iₕ₁= readH(new_h_path)

    γ = 0
    for itemset in Iₕ₁ 
        if (itemset ∉ Iₕ) && (itemset ∉ Iₛ)
            # Debug purpose: println(itemset)
            γ += 1
        end
    end

    return γ / (length(Iₕ) - length(Iₛ))
end

