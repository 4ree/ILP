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

using Plots
import Base.length
import Base.size
import Base.deleteat!
using JLD
using Printf
include("./Algorithm.jl")
function scene1(performances, ds, al_names, mup)
    x=ds.sips
    y=[]
    plot(xlabel = "Sensitive information percentage (%)",
         ylabel = "Excution time (sec)",
         legend =:legend)
    for al in al_names
        runtimes = []
        for sip in ds.sips
            push!(runtimes, performances[ds.name][al][mup][sip].runtime)
            # if al_name == "PPUM_ILP" || al.name =="FILP"
                # println(al_name,"\t",mup,"\t",sip,"\t",runtimes)
            # end
        end
        plot!(x, runtimes, label = al, marker=:auto)
    end
    # plot(x,y, label = labels, 
    # xlabel = "Tỷ lệ thông tin nhạy cảm(%)",
    # ylabel = "Thời gian thực thi (giấy)",
    # legend =:legend)
    savefig(string("./res/",ds.name,"1.pdf"))
end
function scene2(performances, ds, al_names, sip)
    plot( xlabel = "Minimum utility thresholds (%)",
         ylabel = "Excution time (sec)",
         legend =:legend)
    x=ds.mups
    for al in al_names
        runtimes = []
        for mup in ds.mups
            runtime = performances[ds.name][al][mup][sip].runtime
            push!(runtimes, runtime) 
        end
        plot!(x, runtimes, label = al, marker=:auto)
    end

    # plot(x,y, label = labels)
    # plot(x,y, label = labels,
    # xlabel = "Ngưỡng lợi ích tối thiểu (%)",
    # ylabel = "Thời gian thực thi (giây)",
    # legend =:legend)
    savefig(string("./res/",ds.name,"2.pdf"))
end
