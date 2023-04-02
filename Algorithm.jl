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

abstract type Algorithm end


function outputPath(al::Algorithm, dir, ds_name, mup, sip)
    al_name = name(al)
    outputDir="$dir/$mup/sanitized"
    if !isdir(outputDir) mkdir(outputDir) end
    outputPath = string(outputDir,"/",ds_name,"_",al_name,"_",sip)
    return outputPath
end

function minedPath(al::Algorithm, dir, ds_name, mup, sip)
    al_name = name(al)
    minedDir="$dir/$mup/sanitized/mined"
    if !isdir(minedDir) mkdir(minedDir) end
    minedPath = string(minedDir,"/",ds_name,"_",al_name,"_",sip)
    return minedPath
end

