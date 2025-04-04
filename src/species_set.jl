abstract type AbstractSet end

struct ElementsSet{T<:AbstractElement} <: AbstractSet
    list::Vector{T}
    dic::Dict{Int64,T}
    groups::Dict{Symbol,Any}
    lock::Vector{Bool}
end
ElementsSet() = ElementsSet{AbstractElement}()
ElementsSet{AbstractElement}() = ElementsSet{AbstractElement}(Vector{AbstractElement}(), Dict{Int64,AbstractElement}(), Dict{Symbol,Any}(), [false])

struct SpeciesSet{T<:AbstractLoadedSpecies} <: AbstractSet
    list::Vector{T}
    dic::Dict{Int64,T}
    groups::Dict{Symbol,Any}
    lock::Vector{Bool}
end
get_elements(species_set::SpeciesSet) = unique([s.element for s in species_set.list])

Base.isempty(s::SpeciesSet) = isempty(s.list)

function SpeciesSet(v::Vector{T}) where {T<:AbstractLoadedSpecies}
    dic = Dict{Int64,T}()
    for s in v
        dic[s.index.value] = s
    end
    SpeciesSet(v, dic, Dict{Symbol,Any}(), [true])
end
Base.getindex(s::AbstractSet, i::Int64) = s.list[i]
Base.length(s::AbstractSet) = length(s.list)
Base.iterate(s::AbstractSet, args...) = iterate(s.list, args...)

SpeciesSet() = SpeciesSet{LoadedSpecies}()
SpeciesSet{T}() where {T} = SpeciesSet{T}(Vector{LoadedSpecies}(), Dict{Int64,LoadedSpecies}(), Dict{Symbol,Any}(), [false])
check_status(species_set::AbstractSet; lock=false, message="") = @assert species_set.lock[1] == lock message * " | species_registry : $(species_set.lock[1])"


function add_species(obj::BaseSpecies, species_set::SpeciesSet)
    check_status(species_set)
    tmp = LoadedSpecies(obj, get_next_index(species_set))
    @assert tmp ∉ species_set.list "Species $obj already added.... \n List of current species in species set: $(species_set.list)"
    push!(species_set.list, tmp)
end
add_species(obj::LoadedSpecies, species_set::SpeciesSet) = add_species(BaseSpecies(obj), species_set)

function add_element(obj::Element, elements_set::ElementsSet)
    check_status(elements_set)
    tmp = LoadedElement(obj, get_next_index(elements_set))
    @assert tmp ∉ elements_set.list "Species $obj already added.... \n List of current species in species set: $(species_elements.list)"
    push!(elements_set.list, tmp)
end

function add_element(obj::Symbol, elements_set::ElementsSet)
    obj ∈ keys(element_registry) && return add_element(element_registry[obj], elements_set)
    error(" cannot find the element: $obj ...\n Available elements : $(keys(element_registry))")
end

function add_species(obj::Symbol, species_set::SpeciesSet)
    obj ∈ keys(element_registry) && return add_species(element_registry[obj], species_set)
    obj ∈ keys(species_registry) && return add_species(species_registry[obj], species_set)
    error(" cannot find the species/element: $obj ...\n Available elements : $(keys(element_registry)) \n Available species: $(keys(species_registry))")
end

function _get_species(obj::Symbol)
    obj ∈ keys(element_registry) && return element_registry[obj]
    obj ∈ keys(species_registry) && return species_registry[obj]
    error(" cannot find the species/element: $obj ...\n Available elements : $(keys(element_registry)) \n Available species: $(keys(species_registry))")
end



function get_species(obj::Symbol)
    species_set = SpeciesSet()
    add_species(obj, species_set)
    setup_species!(species_set)
    return species_set
end



macro _add_species(obj)
    species_set = FusionSpecies.get_species(obj)
    expr = Expr(:block)
    for s in species_set.list
        push!(expr.args, :($(s.symbol) = FusionSpecies.get_species($(QuoteNode(s.symbol)))))
    end
    for el in get_elements(species_set)
        push!(expr.args, :($(el.symbol) = FusionSpecies.get_element($(QuoteNode(el.symbol)))))
    end
    esc(expr)
end

# macro species_set(obj)
#     FusionSpecies.get_species(obj)
# end

# macro elements_set(obj)
#     FusionSpecies.get_elements(obj)
# end

function get_species(objs::Vector{Symbol})
    species_set = SpeciesSet()
    for obj in objs
        add_species(getfield(@__MODULE__, obj), species_set)
    end
    setup_species!(species_set)
    return species_set
end

function get_elements(objs::Vector{Symbol})
    species_set = ElementsSet()
    for obj in objs
        add_species(getfield(@__MODULE__, obj), species_set)
    end
    setup_species!(species_set)
    return species_set
end

function add_species(el::Element, species_set::AbstractSet)
    check_status(species_set)
    for s in el.species
        add_species(s, species_set)
    end
end

macro species_set(objs...)
    species_set = SpeciesSet()
    for obj in objs
        add_species(obj, species_set)
    end
    setup_species!(species_set)
    return species_set
end

macro elements_set(objs...)
    elements_set = ElementsSet()
    for obj in objs
        add_element(obj, elements_set)
    end
    setup_elements!(elements_set)
    return elements_set
end

function setup_species!(species_set::SpeciesSet)
    list = species_set.list
    @assert length(unique(list)) == length(list)

    list_idx = [v.index for v in species_set.list]
    @assert length(unique(list_idx)) == length(list_idx)
    els = [s.element for s in species_set.list]
    # update species stored in elements
    for el in els
        empty!(el.species)
        for s in species_set.list
            if s.element.symbol == el.symbol
                push!(el.species, s)
            end
        end
    end
    setup_groups!(species_set)
    species_set.lock[1] = true
end

function setup_elements!(set::ElementsSet)
    list = set.list
    @assert length(unique(list)) == length(list)
    list_idx = [v.index for v in list]
    @assert length(unique(list_idx)) == length(list_idx)
    setup_groups!(set)
    set.lock[1] = true
end



function check_species_index(species_set::SpeciesSet)
    for (k, v) in species_set.dic
        @assert k == v.index
    end
    indexes = sort([v.index for (k, v) in species_set.dic])
    # check that indexes start at 1
    @assert minimum(indexes) == 1
    # check that indexes are incremental by 1
    @assert minimum(diff(indexes)) == maximum(diff(indexes)) == 1
end




import_species!(species_set::SpeciesSet, mod::Module; force_import::Bool=false, verbose=true) = import_species!(species_set, mod, force_import; verbose)
function import_species!(species_set::SpeciesSet, mod::Module, force_import::Bool; verbose=true)
    list = []
    expr = quote end
    for (i, s) in enumerate(species_set.list)
        if !hasproperty(mod, s.symbol) || force_import
            push!(list, s)
            try #for main, cannot directly use setproperty! since julia v1.11
                setproperty!(mod, s.symbol, species_set.list[i])
            catch
                mod.eval(:($(s.symbol) = 1))
                setproperty!(mod, s.symbol, species_set.list[i])
            end
        else
            println("warning: cannot import species $(name_(s)) into module $mod ...")
        end
    end
    for e in get_elements(species_set)
        if !hasproperty(mod, e.symbol) || force_import
            push!(list, e)
            try #for main, cannot directly use setproperty! since julia v1.11
                setproperty!(mod, e.symbol, get_elements(species_set))
            catch
                mod.eval(:($(e.symbol) = 1))
                setproperty!(mod, e.symbol, get_elements(species_set))
            end
        else
            println("warning: cannot import element $(name_(e)) into module $mod ...")
        end
    end
    msg = "importing species into module `$mod`: $(join(name_.(list)," ")) "
    verbose ? println(msg) : return msg
end

macro import_species(args...)
    aargs, kwargs = convert_macro_kwargs(args)
    :force_import ∉ keys(kwargs) ? kwargs[:force_import] = false : nothing
    @assert length(aargs) == 1 && length(kwargs) == 1
    force_import = kwargs[:force_import]
    :(import_species!($(aargs[1]), @__MODULE__, $force_import))
end

function set_main_species!(species_set::SpeciesSet, s)
    for s in get_species(species_set, s)
        s.is_main_species.bool = true
    end
end

# ---------------------------------------------------------------------------------------------- # 
"""
species parameters in vector format
"""
struct SpeciesParameters
    mass::SpeciesMasses
    μ::SpeciesReducedMasses
    Z::SpeciesChargeStates
    idx_e⁻::ElectronIndex
    all::SpeciesIndexes
    ions::SpeciesIndexes
    neutrals::SpeciesIndexes
    atoms::SpeciesIndexes
    molecules::SpeciesIndexes
    imp_ions::SpeciesIndexes
    imp_atoms::SpeciesIndexes
    idx_main_ion::MainIonIndex
    idx_main_atom::MainAtomIndex
    species_set::SpeciesSet
end

sdoc(s::SpeciesParameters) = "nspc=$(length(s.Z))"


get_electron(sp::SpeciesParameters; kw...) = get_electron(sp.species_set; kw...)

get_main_ion_index(sp::SpeciesParameters; kw...) = get_main_ion_index(sp.species_set; kw...)

get_ions_index(sp::SpeciesParameters) = sp.ions
get_species_index(sp::SpeciesParameters) = get_species_index(sp.species_set)
Species = Union{Vector{<:AbstractSpecies},Vector{Symbol},Symbol,AbstractSpecies,Int64,Vector{Int64}}

#name(species::Species) = name(get_species(species))
get_species_indexes(sp::SpeciesParameters, s::Union{Symbol,Species,Vector,AbstractSpeciesIndexes}) = get_species_indexes(sp.species_set, s)
get_species_indexes(sp::SpeciesParameters, e::AbstractElement) = get_species_indexes(sp.species_set, get_species(sp.species_set, e))


get_species_charge_states(species_parameters::SpeciesParameters) = species_parameters.Z
get_species_masses(species_parameters::SpeciesParameters) = SpeciesMasses(species_parameters.mass)
get_species_reduced_masses(species_parameters::SpeciesParameters) = SpeciesReducedMasses(species_parameters.mass)

Base.ones(sp::SpeciesParameters) = ones(get_nspecies(sp.species_set))