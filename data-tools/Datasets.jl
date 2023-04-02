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
mutable struct Dataset
    origin_path         # Path of origin dataset
    data_path           # Generated dataset with internal utility information
    table_path          # Generated utility table path of generated data 
    name                # Name of dataset
    h_paths             # High utility itemset path for each mup
    s_paths             # Sensitive itemsets path for each mup and sip
    total_util          # Total utilitiy of dataset
    transaction_utils   # Dictionary store utility of each transaction
    mups                # Minimum utility percentage thresolds
    sips                # Sensitive information percentages 
    n_items             # |I|
    n_transactions      # |D|
end
       
function initDataset(ds_name, total_util, transaction_utils, mups, sips)
    path = @sprintf("/home/nnduc/projects/datasets")
    origin_path="$path/$ds_name/$ds_name.txt"
    data_path="$path/$ds_name/q_$ds_name" 
    table_path="$path/$ds_name/u_$ds_name"
    h_paths=Dict{Float64, String}()
    s_paths=Dict{Float64,Dict{Float64, String}}()
    
    for mup in mups
        mup=Float64(mup)
        gen_path="$path/$ds_name/$mup"
        # println(gen_path)
        if !isdir(gen_path) mkdir(gen_path) end
        h_path= "$gen_path/h_$ds_name"
        s_paths[mup]= Dict{Float64,String}()

        push!(h_paths,mup=>h_path)

        for sip in sips
            sip=Float64(sip)
            s_path=string(gen_path,"/",ds_name,"_",sip)
            push!(s_paths[mup], sip=>s_path)
        end
        
    end


    return Dataset(origin_path, data_path, table_path, ds_name,  h_paths, s_paths, total_util, transaction_utils, mups, sips, 0, 0)
end

