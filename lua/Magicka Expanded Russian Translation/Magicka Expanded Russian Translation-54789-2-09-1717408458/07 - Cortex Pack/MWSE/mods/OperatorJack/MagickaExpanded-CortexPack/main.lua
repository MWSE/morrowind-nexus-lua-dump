local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

require("OperatorJack.MagickaExpanded-CortexPack.effects.cloneEffect")
require("OperatorJack.MagickaExpanded-CortexPack.effects.mindScanEffect")
require("OperatorJack.MagickaExpanded-CortexPack.effects.mindRipEffect")
require("OperatorJack.MagickaExpanded-CortexPack.effects.soulScryeEffect")
require("OperatorJack.MagickaExpanded-CortexPack.effects.coalesceEffect")
require("OperatorJack.MagickaExpanded-CortexPack.effects.permutationEffect")
require("OperatorJack.MagickaExpanded-CortexPack.effects.darknessEffect")
require("OperatorJack.MagickaExpanded-CortexPack.effects.blinkEffect")

local spellIds = {
  blink = "OJ_ME_BlinkSpell",
  clone = "OJ_ME_Clone",
  veilOfDarkness = "OJ_ME_DarknessSpell",
  mindScan = "OJ_ME_MindScan",
  mindRip = "OJ_ME_MindRip",
  soulScrye = "OJ_ME_SoulScrye",
  coalesce = "OJ_ME_Coalesce",
  permutation = "OJ_ME_Permutation"
}

local tomes = {
  {
    id = "OJ_ME_TomeBlink",
    spellId = spellIds.blink,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeDarkness",
    spellId = spellIds.veilOfDarkness,
    list = "OJ_ME_LeveledList_Rare"
  }, 
  {
    id = "OJ_ME_TomeClone",
    spellId = spellIds.clone,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeMindScan",
    spellId = spellIds.mindScan,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeMindRip",
    spellId = spellIds.mindRip,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeSoulScrye",
    spellId = spellIds.soulScrye,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeCoalesce",
    spellId = spellIds.coalesce,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomePermutation",
    spellId = spellIds.permutation,
    list = "OJ_ME_LeveledList_Rare"
  }
}

local function addTomesToLists()
  for _, tome in pairs(tomes) do
    mwscript.addToLevItem({
      list = tome.list,
      item = tome.id,
      level = 1
    })
  end
end
event.register("initialized", addTomesToLists)

local function registerSpells()
  framework.spells.createBasicSpell({
    id = spellIds.blink,
    name = "Мигание",
    effect = tes3.effect.blink,
    range = tes3.effectRange.target
  })

	framework.spells.createBasicSpell({
    id = spellIds.veilOfDarkness,
    name = "Завеса тьмы",
    effect = tes3.effect.darkness,
    range = tes3.effectRange.target,
    duration = 10
  })

  framework.spells.createBasicSpell({
    id = spellIds.clone,
    name = "Клонирование",
    effect = tes3.effect.clone,
    range = tes3.effectRange.target,
    duration = 10,
    min = 10,
    max = 30
  })

  framework.spells.createBasicSpell({
    id = spellIds.mindScan,
    name = "Проницательность Вондакира",
    effect = tes3.effect.mindScan,
    range = tes3.effectRange.self,
    duration = 10,
  })

  framework.spells.createBasicSpell({
    id = spellIds.mindRip,
    name = "Вторжение Вондакира",
    effect = tes3.effect.mindRip,
    range = tes3.effectRange.touch
  })

  framework.spells.createBasicSpell({
    id = spellIds.soulScrye,
    name = "Исследование Вондакира",
    effect = tes3.effect.soulScrye,
    range = tes3.effectRange.self,
    duration = 10,
  })

  framework.spells.createBasicSpell({
    id = spellIds.coalesce,
    name = "Слияние",
    effect = tes3.effect.coalesce,
    range = tes3.effectRange.target
  })

  framework.spells.createBasicSpell({
    id = spellIds.permutation,
    name = "Перестановка",
    effect = tes3.effect.permutation,
    range = tes3.effectRange.self,
    duration = 30
  })
  
  framework.tomes.registerTomes(tomes)
end

event.register("MagickaExpanded:Register", registerSpells)