local ashfall = include('mer.ashfall.interop')
if ashfall then
    ashfall.registerTeas{
        T_IngFlor_Ginseng_01 = {
          teaName = "Чай из женьшеня",
          teaDescription = "Этот землистый чай повышает магические способности.",
          effectDescription = "Увеличить магию 20 п.",
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
         teaName = "Чай из зверобоя",
         teaDescription = "Этот цветочный чай повышает сопротивляемость к электричеству.",
         effectDescription = "Сопротивление электричеству 30 п.",
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
         teaName = "Чай из Корня Нирна",
         teaDescription = "Чай, заваренный из этого редкого растения, помогает ускорить восстановление магии.",
         effectDescription = "Восстановление магии 2 п.",
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
         teaName = "Аспир-чай",
         teaDescription = "Аспир-чай помогает ускорить восстановление запаса сил.",
         effectDescription = "Восстановление запаса сил 1 п.",
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
         teaName = "Чай из медовой лилии",
         teaDescription = "Этот сладкий цветочный чай повышает сопротивляемость к ядам.",
         effectDescription = "Сопротивление ядам 40 п.",
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