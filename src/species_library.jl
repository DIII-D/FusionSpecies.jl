
m_e = 9.1093837015e-31
dic_expo = Dict{}()
dic_expo[1] = "¹"
dic_expo[2] = "²"
dic_expo[3] = "³"
dic_expo[4] = "⁴"
dic_expo[5] = "⁵"
dic_expo[6] = "⁶"
dic_expo[7] = "⁷"
dic_expo[8] = "⁸"
dic_expo[9] = "⁹"
dic_expo[0] = "⁰"
dic_expo["+"] = "⁺"
dic_expo["-"] = "⁻"

const species_registry = Dict{Symbol,AbstractBaseSpecies}()
const element_registry = Dict{Symbol,AbstractElement}()

function add2registry(e::AbstractElement)
    @assert e ∉ values(element_registry)
    @assert e.symbol ∉ keys(element_registry)
    element_registry[e.symbol] = e
end

function add2registry(s::AbstractSpecies)
    @assert s ∉ values(species_registry)
    @assert s.symbol ∉ keys(species_registry)
    species_registry[s.symbol] = s
end


macro create_elements(names...)
    names_ = [string(name) for name in names]
    blk = Expr(:block)
    for name in names_
        n = Symbol(name)
        push!(blk.args, :($n = Element(Mendeleev.elements[Symbol($name)])))
        push!(blk.args, :(add2registry($n)))
    end
    esc(blk)
end

macro create_element(symb, args...)
    aargs, kwargs = convert_macro_kwargs(args)
    if :type ∉ keys(kwargs)
        kwargs[:type] = Atoms
    end
    s = string(symb)
    if :isotope ∉ keys(kwargs)
        kwargs[:isotope] = symb
    end
    n = Symbol(string(symb))
    
    blk = Expr(:block)
    expr = :($n = Element($(string(kwargs[:name])), Symbol($s), $(kwargs[:atomic_number]), $(kwargs[:mass]), $(kwargs[:density]),$(QuoteNode(kwargs[:isotope])); type=$(kwargs[:type])))
    push!(blk.args, expr)
    expr = :(add2registry($n))
    push!(blk.args, expr)
    esc(blk)
end

macro create_species()
    #blk = Expr(:block)
    blk = quote 
    for el in values(element_registry)
        for s in el.species
            eval(:($(s.symbol) = $s))
            add2registry(s)
        end
    end
end
    esc(blk)
end

@create_elements H He Be C Si W Ne Ar Xe Kr N Al Cr Fe Ni Cu O F Cl B 
@create_element ∅ mass = 0 name = dummy atomic_number = 0 density = 0.0
@create_element D mass = 2 * H.mass name = deuterium atomic_number = 1 density = 0.0 isotope=H
@create_element T mass = 3 * H.mass name = tritium atomic_number = 1 density = 0.0 isotope=H
@create_element _e⁻ mass = m_e name = electron atomic_number = -1 type = Electron density = 0.0
@create_species
e⁻ = BaseSpecies{Electron}(SpeciesChargeState(-1), "electron", :e⁻, :_e⁻, SpeciesMass(m_e), SpeciesAtomicNumber(-1), :_e⁻)
add2registry(e⁻)
