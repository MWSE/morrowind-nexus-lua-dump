local ashfall = include('mer.ashfall.interop')
if ashfall then
    ashfall.registerTeas{
        ab_ingflor_bluekanet_01 = {
          teaName = "Blue Kanet Tea",
          teaDescription = "An aromatic tea providing stimulating, slighty psychotropic properties that help focus the mind and body.",
          effectDescription = "Fortify Intelligence and Agility 5 Points",
          duration = 7,
          spell = {
              id = "blue_kanet_spell_effect",
              effects = {
                  {
                      id = tes3.effect.fortifyAttribute,
                      attribute = tes3.attribute.agility,
                      amount = 5
                  },
                  {
                      id = tes3.effect.fortifyAttribute,
                      attribute = tes3.attribute.intelligence,
                      amount = 5
                  }
              }
          }
       }
    }
end