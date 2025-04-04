module FusionSpecies

import Mendeleev
using DocStringExtensions
using Unitful
using Adapt
using OrderedCollections


species_color = :magenta
element_color = 10



abstract type ParticleType end

include("utils.jl")
include("properties.jl")
include("species_types.jl")
include("species_set.jl")
include("getter.jl")
include("iterator.jl")
include("species_library.jl")
include("show.jl")

import Base: (==)

function Base.:(==)(s1::AbstractLoadedSpecies, s2::AbstractLoadedSpecies)
    return all([getfield(s1, f) == getfield(s2, f) for f in fieldnames(typeof(s1)) if f != :index])
end







is_main(s::AbstractSpecies) = false
is_main(s::LoadedSpecies) = s.is_main_species.bool[1]

Base.to_index(s::LoadedSpecies) = Base.to_index(s.index)


export show_elements, get_element, add_species, show_species, create_species
export import_species, @species_set, @elements_set
export get_species, get_species, get_species_set, get_electron_species, get_species_index, get_electron_index
export name_, check_status_species_registry, species_registry, get_nspecies, get_species_Z, get_species_reduced_masses, get_species_masses, get_electron_index, get_species_abstract_type
export AbstractSpecies, BaseSpecies, SpeciesSet, AbstractLoadedSpecies, Species, Elements, AbstractElement, LoadedSpecies, SpeciesParameters
export ElectronSpecies, IonSpecies
end