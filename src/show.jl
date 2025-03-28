#=
Author: Jerome Guterl (guterlj@fusion.gat.com)
 Company: General Atomics
 show.jl (c) 2025=#

Base.show(io::IO, sp::SpeciesParameters) = print(io,"species params:", sp.species_set)
Base.show(io::IO, o::MIME"text/plain", sp::SpeciesParameters) = print(io,"species params:", sp.species_set)
