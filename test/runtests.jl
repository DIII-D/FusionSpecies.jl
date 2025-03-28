using FusionSpecies
using Test

@testset "FusionSpecies.jl" begin
    ss = @species_set D C e⁻
    FusionSpecies.import_species!(ss, @__MODULE__)
    FusionSpecies.set_main_species!(ss, D)
    @test true
end
