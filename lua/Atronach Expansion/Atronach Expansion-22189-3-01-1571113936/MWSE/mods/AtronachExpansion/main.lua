local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[Atronach Expansion ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

require("AtronachExpansion.effects.atronachSummonEffects")

local spellIds = {
  ashGolem = "md_ashgolem_summon",
  boneGolem = "md_bonegolem_summon",
  crystalGolem = "md_crystalGolem_summon",
  fleshAtronach = "md_fleshatronach_summon",
  ironGolem = "md_ironatronach_summon",
  swampMyconid = "md_swampatronach_summon",
  telvanniMyconid = "md_telvanniatronach_summon",
}

local function registerSpells()
  framework.spells.createBasicSpell({
    id = spellIds.ashGolem,
    name = "Summon Ash Golem",
    effect = tes3.effect.summonAshGolem,
    range = tes3.effectRange.self,
    duration = 60
  })
  framework.spells.createBasicSpell({
    id = spellIds.boneGolem,
    name = "Summon Bone Golem",
    effect = tes3.effect.summonBoneGolem,
    range = tes3.effectRange.self,
    duration = 60
  })
  framework.spells.createBasicSpell({
    id = spellIds.crystalGolem,
    name = "Summon Crystal Golem",
    effect = tes3.effect.summonCrystalGolem,
    range = tes3.effectRange.self,
    duration = 60
  })
  framework.spells.createBasicSpell({
    id = spellIds.fleshAtronach,
    name = "Summon Flesh Atronach",
    effect = tes3.effect.summonFleshAtronach,
    range = tes3.effectRange.self,
    duration = 60
  })
  framework.spells.createBasicSpell({
    id = spellIds.ironGolem,
    name = "Summon Iron Golem",
    effect = tes3.effect.summonIronGolem,
    range = tes3.effectRange.self,
    duration = 60
  })
  framework.spells.createBasicSpell({
    id = spellIds.swampMyconid,
    name = "Summon Swamp Myconid",
    effect = tes3.effect.summonSwampMyconid,
    range = tes3.effectRange.self,
    duration = 60
  })
  framework.spells.createBasicSpell({
    id = spellIds.telvanniMyconid,
    name = "Summon Telvanni Myconid",
    effect = tes3.effect.summonTelvanniMyconid,
    range = tes3.effectRange.self,
    duration = 60
  })

end

event.register("MagickaExpanded:Register", registerSpells)