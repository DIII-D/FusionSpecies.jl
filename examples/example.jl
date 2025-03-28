
using FusionSpecies
import FusionSpecies: @_add_species, @species_set
show_elements()

@_add_species D
@_add_species D⁰
@_add_species C
@_add_species Be
@_add_species e⁻

FusionSpecies.get_species(e⁻)

species_set = @species_set D W C e⁻


