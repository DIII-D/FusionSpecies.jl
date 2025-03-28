
using FusionSpecies
show_elements()

@add_species D¹⁺
@add_species D⁰
@add_species C
@add_species Be
@add_species e⁻

FusionSpecies.get_species(1)

@reset_species
@add_species D¹⁺
@add_species D⁰
@add_species e⁻
@setup_species
FusionSpecies.get_species_iterators()