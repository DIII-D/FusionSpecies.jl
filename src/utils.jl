#=
Author: Jerome Guterl (guterlj@fusion.gat.com)
Company: General Atomics
FusionSpecies.jl (c) 2024
=#

import Base: text_colors, disable_text_style

struct MutableBool
    bool::Vector{Bool}
end
MutableBool(b::Bool) = MutableBool([b])

Base.setproperty!(b::MutableBool, s::Symbol, v::Bool) = b.bool[1] = v

function stringstyled(str::AbstractString; color::Union{Int,Symbol}=:normal,
    bold::Bool=false, underline::Bool=false, blink::Bool=false,
    reverse::Bool=false, hidden::Bool=false)
    bold && color === :bold && (color = :nothing)
    underline && color === :underline && (color = :nothing)
    blink && color === :blink && (color = :nothing)
    reverse && color === :reverse && (color = :nothing)
    hidden && color === :hidden && (color = :nothing)
    enable_ansi = get(text_colors, color, text_colors[:default]) *
                  (bold ? text_colors[:bold] : "") *
                  (underline ? text_colors[:underline] : "") *
                  (blink ? text_colors[:blink] : "") *
                  (reverse ? text_colors[:reverse] : "") *
                  (hidden ? text_colors[:hidden] : "")

    disable_ansi = (hidden ? disable_text_style[:hidden] : "") *
                   (reverse ? disable_text_style[:reverse] : "") *
                   (blink ? disable_text_style[:blink] : "") *
                   (underline ? disable_text_style[:underline] : "") *
                   (bold ? disable_text_style[:bold] : "") *
                   get(disable_text_style, color, text_colors[:default])

    return enable_ansi * str * disable_ansi
end


function convert_macro_kwargs(args)
    aargs = []
    aakws = Pair{Any,Any}[]
    for el in args
        if Meta.isexpr(el, :(=))
            push!(aakws, Pair(el.args...))
        else
            push!(aargs, el)
        end
    end
    kwargs = OrderedDict(aakws)
    return aargs, kwargs
end




function eval_species_ex(expr, species_set)
    ex = :(function eval_s(species_set) end)

    for (i,s) in enumerate(species_set.list_species)
        push!(ex.args[2].args,:($(s.symbol) = species_set.list_species[$i]))
    end
    for (k, v) in species_set.groups
        push!(ex.args[2].args, :($(k) = species_set.groups[$(QuoteNode(k))]))
    end
    push!(ex.args[2].args, :(args = $expr))
    return ex
end