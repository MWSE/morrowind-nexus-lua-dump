local ashfall = include('mer.ashfall.interop')
if ashfall then
    ashfall.registerTeas{
        T_IngFlor_Ginseng_01 = {
          teaName = "Ginseng Tea",
          teaDescription = "This earthy tea provides a fortification effect to magicka.",
          effectDescription = "Fortify Magicka 20 points",
          duration = 1,
          spell = {
              id = "ginseng_tea_spell_effect",
              effects = {
                  {
                      id = tes3.effect.fortifyMagicka,
                      amount = 20
                  },
              }
          }
       }
    }
       
    ashfall.registerTeas{
        T_IngFlor_StJahnsWort_01 = {
         teaName = "St. Jahn's Tea",
         teaDescription = "This floral tea provides mild resistance to shock.",
         effectDescription = "Resist Shock 30 points",
         duration = 1,
         spell = {
             id = "st_jahns_spell_effect",
             effects = {
                 {
                     id = tes3.effect.resistShock,
                     amount = 30
                 },
             }
         }
      }
    }

    ashfall.registerTeas{
       T_IngFlor_Nirnroot_01 = {
         teaName = "Nirnroot Tea",
         teaDescription = "Tea brewed from this rare plant can boost magicka regeneration.",
         effectDescription = "Restore Magicka 2 points",
         duration = 1,
         spell = {
             id = "nirnroot_tea_spell_effect",
             effects = {
                {
                     id = tes3.effect.restoreMagicka,
                     amount = 2
                },
            }
        }
      }
    }

    ashfall.registerTeas{ 
    T_IngFlor_AspyrTea_01 = {
         teaName = "Aspyr Tea",
         teaDescription = "Aspyr Tea provides a slight boost to fatigue regeneration.",
         effectDescription = "Restore Fatigue 1 point",
         duration = 1,
         spell = {
             id = "aspyr_tea_spell_effect",
             effects = {
                {
                     id = tes3.effect.restoreFatigue,
                     amount = 2
                },
            }
        }
     }
    }

    ashfall.registerTeas{
     T_IngFlor_HoneyLily_02 = {
         teaName = "Honey Lily Tea",
         teaDescription = "This sweet, floral tea provides a modest boost to poison resistance.",
         effectDescription = "Resist Poison 40 points",
         duration = 1,
         spell = {
             id = "honey_lily_tea_spell_effect",
             effects = {
                {
                     id = tes3.effect.resistPoison,
                     amount = 40
                },
            }
        }
      }
    }
end