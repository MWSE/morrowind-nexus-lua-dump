local magickaExpanded = include("OperatorJack.MagickaExpanded.magickaExpanded")
local common = require("TeamVoluptuousVelks.FortifiedMolagMar.common")

local tomes = {
  {
    id = "FMM_TomeLesserBanishDaedra",
    spellId = common.data.spellIds.banishDaedra
  }, 
}

local function createSlowTimeEnchantment()
  local enchantment = tes3.getObject(common.data.enchantmentIds.slowTime)

  if (enchantment == nil) then
    return nil
  end

  local effect = enchantment.effects[1]
  effect.id = tes3.effect.slowTime
  effect.rangeType = tes3.effectRange.self
  effect.min = 50
  effect.max = 50
  effect.duration = 10
  effect.radius = 0

  return enchantment
end

local function createBucketHelmEnchantment()
  local enchantment = tes3.getObject(common.data.enchantmentIds.bucketHelm)

  if (enchantment == nil) then
    return nil
  end

  local effect = enchantment.effects[1]
  effect.id = tes3.effect.spawnChair
  effect.rangeType = tes3.effectRange.target
  effect.min = 1
  effect.max = 1
  effect.duration = 1
  effect.radius = 0

  return enchantment
end

local function createBanishDaedraEnchantment()
  local enchantment = tes3.getObject(common.data.enchantmentIds.banishDaedra)

  if (enchantment == nil) then
    return nil
  end

  local effect = enchantment.effects[1]
  effect.id = tes3.effect.banishDaedra
  effect.rangeType = tes3.effectRange.touch
  effect.min = 5
  effect.max = 15
  effect.duration = 1
  effect.radius = 0

  return enchantment
end

-- Register Spells --
local function registerSpells()
  magickaExpanded.spells.createBasicSpell({
    id = common.data.spellIds.slowTime,
    name = "Slow Time",
    effect = tes3.effect.slowTime,
    range = tes3.effectRange.self,
    duration = 10,
    min = 50,
    max = 50
  })
  magickaExpanded.spells.createBasicSpell({
    id = common.data.spellIds.slowTimeShrine,
    name = "Slow Time - Shrine",
    effect = tes3.effect.slowTime,
    range = tes3.effectRange.target,
    duration = 600,
    min = 10,
    max = 10
  })
  magickaExpanded.spells.createBasicSpell({
    id = common.data.spellIds.annihilate,
    name = "Annihilate",
    effect = tes3.effect.annihilate,
    range = tes3.effectRange.target,
    radius = 10
  })
  magickaExpanded.spells.createBasicSpell({
    id = common.data.spellIds.banishDaedra,
    name = "Lesser Banish Daedra",
    effect = tes3.effect.banishDaedra,
    range = tes3.effectRange.touch,
    min = 5,
    max = 15
  })
  
  magickaExpanded.spells.createBasicSpell({
    id = common.data.spellIds.firesOfOblivion,
    name = "Fires of Oblivion",
    effect = tes3.effect.firesOfOblivion,
    range = tes3.effectRange.target
  })
  
  createBanishDaedraEnchantment()
  createBucketHelmEnchantment()
  createSlowTimeEnchantment()

  magickaExpanded.tomes.registerTomes(tomes)
end
  
  event.register("MagickaExpanded:Register", registerSpells)
------------------------------------------