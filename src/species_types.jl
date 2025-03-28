
abstract type AbstractSpecies{T<:ParticleType} end

abstract type AbstractLoadedSpecies{T<:ParticleType} <: AbstractSpecies{T} end
abstract type AbstractBaseSpecies{T} <: AbstractSpecies{T} end


abstract type AbstractElement end


abstract type ChargedParticleType <: ParticleType end
abstract type Electron <: ChargedParticleType end
abstract type Ions <: ChargedParticleType end
abstract type Neutrals <: ParticleType end
abstract type Atoms <: Neutrals end
abstract type Molecules <: Neutrals end

abstract type ImpurityMolecule <: Molecules end
abstract type MainMolecule <: Molecules end
abstract type MainAtom <: Atoms end
abstract type ImpurityAtom <: Atoms end
abstract type ImpurityIon <: Ions end
abstract type MainIon <: Ions end

const ChargedParticleSpecies = AbstractSpecies{<:ChargedParticleType}
const ElectronSpecies = AbstractSpecies{<:Electron}
const IonSpecies = AbstractSpecies{<:Ions}
const NeutralSpecies = AbstractSpecies{<:Neutrals}
const AtomSpecies = AbstractSpecies{<:Atoms}
const MoleculeSpecies = AbstractSpecies{<:Molecules}


const IonsAtoms = Union{Ions,Atoms}

struct Element{T<:ParticleType} <: AbstractElement
    name::String
    symbol::Symbol
    atomic_number::ElementAtomicNumber
    mass::ElementMass
    density::ElementDensity
    species::Vector{AbstractSpecies}
    isotope::Symbol
end
abstract type AbstractMaterialElement <: AbstractElement end
struct MaterialElement <: AbstractMaterialElement
    name::String
    symbol::Symbol
    atomic_number::ElementAtomicNumber
    mass::ElementMass
    density::ElementDensity
    isotope::Symbol
end



function (e::Element)(q::Int64)
    for s in e.species
        s.charge_state.value == q && return s
    end
    return missing
end

(e::Element)(q::UnitRange) = [s for q_ in q for s in e.species if s.charge_state.value == q_]


const Elements = Union{Element,Vector{<:Element}}


Element(element::Mendeleev.Element) = Element{Atoms}(element.name, Symbol(element.symbol), ElementAtomicNumber(element.number), ElementMass((element.atomic_mass |> u"kg").val), ElementDensity((element.density |> u"kg/m^3").val), Symbol(element.symbol))
Element(n, s, a, m, d, isotope::Symbol; type=Atoms) = Element{type}(n, s, ElementAtomicNumber(a), ElementMass(m), ElementDensity(d), isotope)
Element{T}(n, s, a, m, d, isotope) where {T<:Atoms} = Element{T}(n, s, a, m, d, [BaseSpecies(z, n, s, m, a, isotope) for z in 0:a.value], isotope)
Element{T}(n, s, a, m, d, isotope) where {T<:Electron} = Element{T}(n, s, a, m, d, [BaseSpecies(a.value, n, s, m, a, isotope)], isotope)


charge_states(el::Element)::Int64 = el.atomic_number.value
atomic_number(el::Element)::Int64 = el.atomic_number.value
export charge_states, atomic_number

function Base.show(io::IO, ::MIME"text/plain", element::AbstractElement)
    printstyled(io, "$(string(element.symbol))", color=element_color)
    printstyled(io, "($(element.name))")
end

function Base.show(io::IO, element::AbstractElement)
    printstyled(io, "$(string(element.symbol))", color=element_color)
end
inline_summary(el::Element) = stringstyled("$(el.symbol)", color=element_color) * " : " * el.name

# ---------------------------------------------------------------------------------------------------------------------------------------------------- #
struct BaseSpecies{T} <: AbstractBaseSpecies{T}
    charge_state::SpeciesChargeState
    name::String
    symbol::Symbol
    element_symbol::Symbol
    mass::SpeciesMass
    atomic_number::SpeciesAtomicNumber
    isotope::Symbol
end

BaseSpecies(s::AbstractLoadedSpecies{T}) where {T} = BaseSpecies{T}(s.charge_state, s.name, s.symbol, s.element.symbol, s.mass, s.atomic_number, s.isotope.symbol)

function BaseSpecies(z, el_name, el_symbol, el_mass::ElementMass, el_atomic_number::ElementAtomicNumber, isotope)
    T = get_type_species(z)
    s = get_species_symbol(el_symbol, z)
    BaseSpecies{T}(SpeciesChargeState(z), el_name, s, el_symbol, SpeciesMass(el_mass), SpeciesAtomicNumber(el_atomic_number), isotope)
end

struct LoadedSpecies{T<:ParticleType} <: AbstractLoadedSpecies{T}
    charge_state::SpeciesChargeState
    name::String
    symbol::Symbol
    element::AbstractElement
    mass::SpeciesMass
    ionization_energy::SpeciesIonizationEnergy
    atomic_number::SpeciesAtomicNumber
    index::SpeciesIndex
    isotope::AbstractElement
    is_active::MutableBool
    is_main_species::MutableBool
end


function LoadedSpecies(s::BaseSpecies, idx::Int64)
    T = get_species_particle_type(s)
    isotope = get_element(s.isotope)
    LoadedSpecies{T}(s.charge_state, s.name, s.symbol, get_element(s.element_symbol), s.mass, get_ionization_energy(get_element(s.element_symbol), s.charge_state, isotope), s.atomic_number, SpeciesIndex(idx), isotope, MutableBool(false), MutableBool(false))
end
type(::AbstractLoadedSpecies{T}) where {T} = T
stype(s::LoadedSpecies) = split(string(type(s)), ".")[end]

function get_ionization_energy(element::Element, z::SpeciesChargeState, isotope::Element)
    Z = floor(Int64, z.value) + 1
    Z > element.atomic_number.value && return SpeciesIonizationEnergy(0.0)
    element.symbol ∈ keys(Mendeleev.elements.bysymbol) && return SpeciesIonizationEnergy(Mendeleev.elements[element.symbol].ionenergy[Z].val)
    isotope.symbol ∈ keys(Mendeleev.elements.bysymbol) && return SpeciesIonizationEnergy(Mendeleev.elements[isotope.symbol].ionenergy[Z].val)
    return SpeciesIonizationEnergy(0.0)
end

export get_species_masses, get_species_reduced_masses, get_species_charge_states