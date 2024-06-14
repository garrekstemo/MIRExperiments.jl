"""
    beam_plot(fig, dir, timestamps, labels; col, yoffset, normalize)

Generate a simple plot of the beam spectrum. Used mainly for diagnostics.
"""
function beam_plot(fig, dir, timestamps, labels; 
                col::Int = 1, yoffset::Float64 = 0.0, normalize = true)
	
    if !(eltype(labels) <: AbstractString)
        labels = string.(labels)
    end

    intensities = []

	ax = Axis(fig[1, 1], xlabel = "Wavelength (nm)", ylabel = "Intensity (arb.)", xticks = LinearTicks(10))
	
	for (i, file) in enumerate(timestamps)
        df = LVM.readlvm(dir, file)
        intensity = -df[!, col]
        
        if normalize
            intensity ./= maximum(intensity)  # Data is flipped
        end
        
        push!(intensities, intensity)
        lines!(ax, df.wavelength, intensity .+ i * yoffset, label = labels[i])
    end
    axislegend(ax)
	ax, intensities
end