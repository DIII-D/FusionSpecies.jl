#=
Author: Jerome Guterl (guterlj@fusion.gat.com)
 Company: General Atomics
 show.jl (c) 2025=#

Base.show(io::IO, sp::SpeciesParameters) = print(io, "species params:", sp.species_set)
Base.show(io::IO, o::MIME"text/plain", sp::SpeciesParameters) = print(io, "species params:", sp.species_set)

function Base.show(io::IO, ::MIME"text/plain", species_set::SpeciesSet)
    print(io, stringstyled("⟦"; color=20) * (isempty(species_set) ? "∅" : join(name_.(species_set.list), "; ")) * stringstyled("⟧"; color=20))
end

function Base.show(io::IO, species_set::SpeciesSet{T}) where {T}
    print(io, stringstyled("⟦"; color=20) * (isempty(species_set) ? "∅" : join(name_.(species_set.list), "; ")) * stringstyled("⟧"; color=20))
end

function Base.show(io::IO, ::MIME"text/plain", set::ElementsSet)
    print(io, stringstyled("⟦"; color=30) * (isempty(set) ? "∅" : join(name_.(set.list), "; ")) * stringstyled("⟧"; color=30))
end

function Base.show(io::IO, set::ElementsSet)
    print(io, stringstyled("⟦"; color=30) * (isempty(set) ? "∅" : join(name_.(set.list), "; ")) * stringstyled("⟧"; color=30))
end

function Base.show(io::IO, ::MIME"text/plain", element::AbstractElement)
    printstyled(io, "$(string(element.symbol))"; color=element_color)
    printstyled(io, "($(element.name))")
end

function Base.show(io::IO, element::AbstractElement)
    printstyled(io, "$(string(element.symbol))"; color=element_color)
end
inline_summary(el::Element) = stringstyled("$(el.symbol)"; color=element_color) * " : " * el.name

function Base.show(io::IO, species::Vector{<:LoadedSpecies})
    print(io, "[$(species...)]")
end


function Base.show(io::IO, ::MIME"text/plain", species::LoadedSpecies)
    printstyled(io, "$(string(species.symbol))", " [$(stype(species))][", "$(string(species.element.symbol))", "] ", " - index: $(species.index)", color=species_color)
end

function Base.show(io::IO, species::AbstractSpecies)
    printstyled(io, sdoc(species))
end


"$TYPEDSIGNATURES display available elements"
function show_elements() 
    println("Available elements")
    for el in values(element_registry)
        println(inline_summary(el))
    end
end
name_(species::Vector{<:AbstractElement}) = join([stringstyled(string(s.symbol); color=20, bold=true) for s in species], ", ")
name_(species::Vector{<:AbstractSpecies}) = join([sdoc(s) for s in species], ", ")
name_(species::Vector{Tuple{LoadedSpecies,LoadedSpecies}}) = join([stringstyled("($(s[1]),$(s[2]))"; color=:magenta, bold=true) for s in species], ", ")

name_(species::AbstractSpecies) = sdoc(species)
sdoc(species::AbstractSpecies) = is_main(species) ? stringstyled(string(species.symbol); color=24, bold=true) : stringstyled(string(species.symbol); color=species_color, bold=true)

name_(species::AbstractElement) = stringstyled(string(species.symbol); color=10, bold=true)

name_(species_set::SpeciesSet) = join(name_.(species_set.list), " ")
inline_summary(species_set::SpeciesSet) = join([name_(species) * "[$(species.index.value)]" for species in species_set.list], " ")


Base.show(io::IO, iter::SpeciesIterator) = print(io, sdoc(iter))
Base.show(io::IO, ::MIME"text/plain", iter::SpeciesIterator) = print(io, sdoc(iter))

function show_plasma_species()
    list_elements = [getfield(@__MODULE__, n).symbol for n in names(@__MODULE__; all=true) if getfield(@__MODULE__, n) isa AbstractElement]
    list = [getfield(@__MODULE__, n).symbol for n in names(@__MODULE__; all=true) if getfield(@__MODULE__, n) isa AbstractSpecies]
    println(string.(list_elements))
    println(string.(list))
end

function show_species()
    check_status_species_registry(; lock=true)
    show(species_registry["species_set"])
end