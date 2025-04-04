#=
Author: Jerome Guterl (guterlj@fusion.gat.com)
 Company: General Atomics
 FusionSpecies.jl (c) 2024
 =#

mutable struct SpeciesIterator{S<:SpeciesIndexes}
    s::S
    species_set::Union{SpeciesSet,Missing}
end

Base.iterate(s::SpeciesIterator, args...) = iterate(s.s)

Base.length(s::SpeciesIterator) = length(s.s)

Base.copy(iter::SpeciesIterator) = SpeciesIterator(copy(iter.s), iter.species_set)
Base.empty!(iter::SpeciesIterator{<:SpeciesIndexes}) = empty!(iter.s)#; update_label!(iter))
Base.append!(iter::SpeciesIterator{<:SpeciesIndexes}, v::SpeciesIndexes) = append!(iter.s, v)
Base.length(iter::SpeciesIterator{SpeciesIndexes}) = length(iter.s)
get_species(s::SpeciesSet, iter::SpeciesIterator) = get_species(s, iter.s)

sdoc(species_set::SpeciesSet, iter::SpeciesIndexes) = stringstyled("⟦", color=20) * name_(get_species(species_set, iter)) * stringstyled("⟧", color=20)
sdoc(::Missing, iter::SpeciesIndexes) = stringstyled("⟦", color=20) * "$(iter.s)" * stringstyled("⟧", color=20)
sdoc(iter::SpeciesIterator) = sdoc(iter.species_set, iter.s)
sdoc(iters::Vector{<:SpeciesIterator}) = mapreduce(s -> "$(sdoc(s))", *, iters)

SpeciesIterator(species_set::SpeciesSet, s::Union{Symbol,Vector}) = SpeciesIterator(species_set, SpeciesIndexes(species_set, s))
SpeciesIterator(species_set::SpeciesSet) = SpeciesIterator(SpeciesIndexes(species_set), species_set)
SpeciesIterator(species_set::SpeciesSet, s::SpeciesIndexes) = SpeciesIterator(s, species_set)

intersect_species_index(a::SpeciesSet, b) = intersect_species_index(get_species_index(a), b)
intersect_species_index(a::Vector{<:LoadedSpecies}, b) = intersect_species_index(get_species_indexes(a), b)
intersect_species_index(a::SpeciesIndexes, b::SpeciesIterator) = intersect_species_index(a, b.s)
intersect_species_index(a::SpeciesIterator, b::SpeciesIterator) = intersect_species_index(a.s, b.s)
intersect_species_index(a::SpeciesIndexes, b::SpeciesIndexes) = intersect(a.value, b.value)
intersect_species(species_set::SpeciesSet, a, b) = SpeciesIterator(SpeciesIndexes(intersect_species_index(a, b)), species_set)

export intersect_species

function add_species!(iter::SpeciesIterator, species_idx::AbstractSpeciesIndexes)
    append!(iter.s, species_idx)
    unique!(iter.s)
    sort!(iter.s)
end

setup_iterators_species_set!(iter::SpeciesIterator, species_set::SpeciesSet) = iter.species_set =  species_set#; update_label!(iter));

function set_species!(iter::SpeciesIterator, species_idx::SpeciesIndexes) 
    empty!(iter.s)
    for s in species_idx
        push!(iter.s.value,s)
    end
end

function set_species(iter::SpeciesIterator, species_set, species_idx::Union{Symbol,Vector,SpeciesIndexes,AbstractSpeciesIndexes,Species})
    return SpeciesIterator(species_set, species_idx)
end

concat(s1::AbstractSpeciesIndexes, s2::AbstractSpeciesIndexes)::SpeciesIndexes = SpeciesIndexes(unique(vcat(s1.value, s2.value)))

set_species!(iter::SpeciesIterator, species_set::SpeciesSet, species::Union{Symbol,Vector,SpeciesIndexes,AbstractSpeciesIndexes,Species}) = set_species!(iter, SpeciesIndexes(species_set, species))
# set_species(iter::SpeciesIterator, species_set::SpeciesSet, species::) = set_species(iter, species_set, SpeciesIndexes(species_set, species))

set_species!(iter::SpeciesIterator, species_set::SpeciesSet, species::Union{SpeciesIterator}) = set_species!(iter, species_set, species.s)

function set_species!(iter::SpeciesIterator, species_set::SpeciesSet, expr::Expr) 
    f = eval(eval_species_ex(expr, species_set))
    out = Base.invokelatest(f,species_set)
    if out isa Vector
        out = hcat(out...)
    end
    if out isa Matrix
        out = vcat(out...)
    end
    print(out)
    set_species!(iter, species_set, get_species_index.(out))
end

function set_species(iter::SpeciesIterator, species_set::SpeciesSet, expr::Expr)
    f = eval(eval_species_ex(expr, species_set))
    out = Base.invokelatest(f, species_set)
    if out isa Vector
        out = hcat(out...)
    end
    if out isa Matrix
        out = vcat(out...)
    end
    set_species(iter, species_set, get_species_index.(out))
end

set_species!(iter, species_set, species::Array{<:Tuple{LoadedSpecies,LoadedSpecies}}) = set_species!(iter, species_set, get_species_index.(species))

