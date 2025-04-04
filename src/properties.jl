
abstract type AbstractProperties  end
abstract type AbstractElementProperties <: AbstractProperties end
abstract type AbstractElementProperty <: AbstractElementProperties end
abstract type AbstractSpeciesProperties <: AbstractProperties end
abstract type AbstractSpeciesProperty <: AbstractSpeciesProperties end
abstract type AbstractSpeciesIndexes end
abstract type AbstractSpeciesIndex<: AbstractSpeciesIndexes end

const AbstractProperty = Union{AbstractSpeciesProperty,AbstractElementProperty}
Base.:*(f::Number, m::T) where {T<:AbstractProperties} = T(f * m.value)
Base.:<(x::Number, y::T) where {T<:AbstractProperty} = x < y.value
Base.:<(x::T, y::Number) where {T<:AbstractProperty} = x.value < y

struct SpeciesIonizationEnergy{F<:Union{Missing,Float64}} <: AbstractSpeciesProperty
    value::F
end

struct SpeciesChargeState <: AbstractSpeciesProperty
    value::Float64
end
SpeciesChargeState(A::Int64) = SpeciesChargeState(Float64(A))

struct SpeciesChargeStates <: AbstractSpeciesProperties
    value::Vector{Float64}
end
SpeciesChargeStates(v::Vector{<:SpeciesChargeState}) = SpeciesChargeStates([s.value for s in v])

for o in (:+,:-,:*,:/,:^)
    eval(:(Base.$o(p::SpeciesChargeState, i) = $o(p.value, i)))
end

struct ElementMass <: AbstractElementProperty
    value::Float64
end
ElementMass(m::ElementMass) = m
ElementMass(A::Int64) = ElementMass(Float64(A))

struct ElementAtomicNumber <: AbstractElementProperty
    value::Int64
end
ElementAtomicNumber(A::Float64) = ElementAtomicNumber(Int64(A))

struct ElementDensity <: AbstractElementProperty
    value::Float64
end
ElementDensity(m::ElementDensity) = m

struct SpeciesAtomicNumber <: AbstractSpeciesProperty
    value::Float64
end
SpeciesAtomicNumber(A::Int64) = SpeciesAtomicNumber(Float64(A))
SpeciesAtomicNumber(m::ElementAtomicNumber) = SpeciesAtomicNumber(m.value)

struct SpeciesMass <: AbstractSpeciesProperty
    value::Float64
end
SpeciesMass(m::ElementMass) = SpeciesMass(m.value)
struct SpeciesMasses <: AbstractSpeciesProperties
    value::Vector{Float64}
end
SpeciesMasses(v::Vector{<:SpeciesMass}) = SpeciesMasses([s.value for s in v])

struct SpeciesReducedMass <: AbstractSpeciesProperty
    value::Float64
end
SpeciesReducedMass(m::ElementMass) = SpeciesReducedMass(m.value)
struct SpeciesReducedMasses <: AbstractSpeciesProperties
    value::Matrix{Float64}
end
SpeciesReducedMasses(s::Vector{<:SpeciesMass}) = SpeciesReducedMasses(reshape([s1.value / (s1.value + s2.value) for (s1, s2) in Iterators.product(s, s)],length(s), length(s)))

struct ElementIndex <: AbstractSpeciesIndex
    value::Int64
end
ElementIndex() = ElementIndex(0)

struct SpeciesIndex <: AbstractSpeciesIndex
    value::Int64
end
SpeciesIndex(i::SpeciesIndex) = SpeciesIndex(i.value)

struct BinarySpeciesIndex{T1 <: ParticleType,T2 <: ParticleType}
    s1::Int64
    s2::Int64
end


struct SpeciesIndexes{V<:Union{Vector{Int64},Vector{BinarySpeciesIndex}}} <: AbstractSpeciesIndexes
    value::V
end

function SpeciesIndex(s::SpeciesIndexes)
    @assert length(s.value) == 1
    SpeciesIndex(s.value[1])
end
SpeciesIndexes(i::Int64) = SpeciesIndex([i])

SpeciesIndexes() = SpeciesIndexes(Vector{Int64}())
SpeciesIndexes(s::SpeciesIndex) = SpeciesIndexes([s.value])
SpeciesIndexes(v::Vector{SpeciesIndex}) = SpeciesIndexes([s.value for s in v])
Base.iterate(s::SpeciesIndexes, args...) = iterate(s.value, args...)
Base.firstindex(s::SpeciesIndexes, args...) = firstindex(s.value, args...)


struct ElectronIndex <: AbstractSpeciesIndex
    value::Int64
end
ElectronIndex(i::SpeciesIndex) = ElectronIndex(i.value)

struct MainIonIndex <: AbstractSpeciesIndex
    value::Int64
end

function MainIonIndex(v::Vector) 
    @assert length(v) == 1 
    MainIonIndex(v[1])
end
MainIonIndex(v::SpeciesIndex) = MainIonIndex(v.value)

struct MainAtomIndex <: AbstractSpeciesIndex
    value::Int64
end
function MainAtomIndex(v::Vector)
    @assert length(v) == 1
    MainAtomIndex(v[1])
end

MainAtomIndex(v::SpeciesIndex) = MainAtomIndex(v.value)

export SpeciesMasses, SpeciesChargeState, SpeciesChargeStates, SpeciesIndexes, SpeciesIndex, ElectronIndex, MainAtomIndex, MainIonIndex

Base.getindex(t::Union{AbstractSpeciesProperties,SpeciesIndexes}, args...) = getindex(t.value, args...)
Base.copy(t::T) where {T<:Union{AbstractSpeciesProperties,AbstractSpeciesIndexes}} = T(copy(t.value))
Base.length(t::T) where {T<:Union{AbstractSpeciesProperties,SpeciesIndexes}} = length(t.value)
Base.copyto!(t::T,args...) where {T<:Union{AbstractSpeciesProperties,SpeciesIndexes}} = copyto!(t.value,args...)
Base.size(t::T) where {T<:Union{AbstractSpeciesProperties,SpeciesIndexes}} = size(t.value)
Base.empty!(t::T) where {T<:AbstractSpeciesIndexes} = empty!(t.value)
Base.iterate(t::T, args...) where {T<:Union{AbstractSpeciesProperties,SpeciesIndexes}} = iterate(t.value, args...)
Base.unique!(t::T, args...) where {T<:Union{AbstractSpeciesProperties,SpeciesIndexes}} = unique!(t.value, args...)
Base.sort!(t::T, args...) where {T<:Union{AbstractSpeciesProperties,SpeciesIndexes}} = sort!(t.value, args...)
Base.append!(s1::SpeciesIndexes, s2::SpeciesIndexes) = append!(s1.value, s2.value)
Base.to_index(i::AbstractSpeciesIndexes) = Base.to_index(i.value)
Base.ismissing(s::AbstractSpeciesIndex) = s.value ==0
