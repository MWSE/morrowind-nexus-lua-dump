local common = require("TeamVoluptuousVelks.DeeperDagothUr.common")
local magickaExpanded = include("OperatorJack.MagickaExpanded.magickaExpanded")

-- Register Spells --
local function registerSpells()
    magickaExpanded.spells.createBasicSpell({
      id = common.data.spellIds.dispelLevitation,
      name = "Dispel Levitation",
      effect = tes3.effect.dispelLevitate,
      range = tes3.effectRange.target
    })
    magickaExpanded.spells.createBasicSpell({
      id = common.data.spellIds.dispelLevitationJavelin,
      name = "Dispel Levitation - Javelin",
      effect = tes3.effect.dispelLevitateJavelin,
      range = tes3.effectRange.target
    })
    magickaExpanded.spells.createBasicSpell({
      id = common.data.spellIds.dispelLevitationSelf,
      name = "Dispel Levitation - Self",
      effect = tes3.effect.dispelLevitate,
      range = tes3.effectRange.self
    })
    magickaExpanded.spells.createComplexSpell({
        id = common.data.spellIds.dispelLevitationJavelin,
        name = "Dispel Levitation - Javelin",
        effects =
          {
            [1] = {
              id =tes3.effect.dispelLevitateJavelin,
              range = tes3.effectRange.target,
            },
            [2] = {
              id =tes3.effect.damageHealth,
              range = tes3.effectRange.target,
              duration = 2,
              min = 10,
              max = 50
            }
          }
      })

    magickaExpanded.spells.createComplexSpell({
        id = common.data.spellIds.ascendedSleeperSummonAshSlaves,
        name = "Summon Ash Slaves",
        effects =
          {
            [1] = {
              id =tes3.effect.summonAshSlave,
              range = tes3.effectRange.self,
              duration = 30
            },
            [2] = {
              id =tes3.effect.summonAshSlave,
              range = tes3.effectRange.self,
              duration = 30
            }
          }
      })
      magickaExpanded.spells.createComplexSpell({
          id = common.data.spellIds.ashVampireSummonAscendedSleepers,
          name = "Summon Ascended Sleepers",
          effects =
            {
              [1] = {
                id =tes3.effect.summonAscendedSleeper,
                range = tes3.effectRange.self,
                duration = 45
              },
              [2] = {
                id =tes3.effect.summonAscendedSleeper,
                range = tes3.effectRange.self,
                duration = 45
              },
              [3] = {
                id =tes3.effect.summonAshGhoul,
                range = tes3.effectRange.self,
                duration = 45
              },
              [4] = {
                id =tes3.effect.summonAshGhoul,
                range = tes3.effectRange.self,
                duration = 45
              },
              [5] = {
                id =tes3.effect.summonAshGhoul,
                range = tes3.effectRange.self,
                duration = 45
              }
            }
        })
  end
  
  event.register("MagickaExpanded:Register", registerSpells)
------------------------------------------