local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

require("OperatorJack.MagickaExpanded-LoreFriendlyPack.effects.banishDaedraEffect")
require("OperatorJack.MagickaExpanded-LoreFriendlyPack.effects.basicBoundWeaponEffects")
require("OperatorJack.MagickaExpanded-LoreFriendlyPack.effects.basicBoundArmorEffects")

local spellIds = {
  banishDaedra = "OJ_ME_BanishDaedraSpell",
  boundGreaves = "OJ_ME_BoundGreavesSpell",
  boundPauldrons = "OJ_ME_BoundPauldronsSpell",
  boundClaymore = "OJ_ME_BoundClaymoreSpell",
  boundClub = "OJ_ME_BoundClubSpell",
  boundDaiKatana = "OJ_ME_BoundDaiKatanaSpell",
  boundKatana = "OJ_ME_BoundKatanaSpell",
  boundShortSword = "OJ_ME_BoundShortswordSpell",
  boundStaff = "OJ_ME_BoundStaffSpell",
  boundTanto = "OJ_ME_BoundTantoSpell",
  boundWakizashi = "OJ_ME_BoundWakizashiSpell",
  boundWarAxe = "OJ_ME_BoundWarAxeSpell",
  boundWarhammer = "OJ_ME_BoundWarhammerSpell"
}

local tomes = {
  {
    id = "OJ_ME_TomeBanishDaedra",
    spellId = spellIds.banishDaedra
  }, 
  {
    id = "OJ_ME_TomeBoundGreaves",
    spellId = spellIds.boundGreaves
  }, 
  {
    id = "OJ_ME_TomeBoundPauldrons",
    spellId = spellIds.boundPauldrons
  }, 
  {
    id = "OJ_ME_TomeBoundClaymore",
    spellId = spellIds.boundClaymore
  }, 
  {
    id = "OJ_ME_TomeBoundClub",
    spellId = spellIds.boundClub
  }, 
  {
    id = "OJ_ME_TomeBoundDaiKatana",
    spellId = spellIds.boundDaiKatana
  }, 
  {
    id = "OJ_ME_TomeBoundKatana",
    spellId = spellIds.boundKatana
  }, 
  {
    id = "OJ_ME_TomeBoundShortsword",
    spellId = spellIds.boundShortSword
  }, 
  {
    id = "OJ_ME_TomeBoundStaff",
    spellId = spellIds.boundStaff
  }, 
  {
    id = "OJ_ME_TomeBoundTanto",
    spellId = spellIds.boundTanto
  }, 
  {
    id = "OJ_ME_TomeBoundWakizashi",
    spellId = spellIds.boundWakizashi
  }, 
  {
    id = "OJ_ME_TomeBoundWaraxe",
    spellId = spellIds.boundWarAxe
  }, 
  {
    id = "OJ_ME_TomeBoundWarhammer",
    spellId = spellIds.boundWarhammer
  }, 
}

local function addTomesToLists()
  local listId = "OJ_ME_LeveledList_Common"
  for _, tome in pairs(tomes) do
    mwscript.addToLevItem({
      list = listId,
      item = tome.id,
      level = 1
    })
  end
end
event.register("initialized", addTomesToLists)

local function registerSpells()
	framework.spells.createBasicSpell({
    id = spellIds.banishDaedra,
    name = "Banish Daedra",
    effect = tes3.effect.banishDaedra,
    range = tes3.effectRange.touch,
    min = 30,
    max = 50
  })
  framework.spells.createBasicSpell({
    id = spellIds.boundGreaves,
    name = "Bound Greaves",
    effect = tes3.effect.boundGreaves,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createComplexSpell({
    id = spellIds.boundPauldrons,
    name = "Bound Pauldrons",
    effects =
      {
        [1] = {
          id =tes3.effect.boundLeftPauldron,
          range = tes3.effectRange.self,
          duration = 30
        },
        [2] = {
          id =tes3.effect.boundRightPauldron,
          range = tes3.effectRange.self,
          duration = 30
        }
      }
  })
  framework.spells.createBasicSpell({
    id = spellIds.boundClaymore,
    name = "Bound Claymore",
    effect = tes3.effect.boundClaymore,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = spellIds.boundClub,
    name = "Bound Club",
    effect = tes3.effect.boundClub,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = spellIds.boundDaiKatana,
    name = "Bound Dai-Katana",
    effect = tes3.effect.boundDaiKatana,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = spellIds.boundKatana,
    name = "Bound Katana",
    effect = tes3.effect.boundKatana,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = spellIds.boundShortSword,
    name = "Bound Shortsword",
    effect = tes3.effect.boundShortSword,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = spellIds.boundStaff,
    name = "Bound Staff",
    effect = tes3.effect.boundStaff,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = spellIds.boundTanto,
    name = "Bound Tanto",
    effect = tes3.effect.boundTanto,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = spellIds.boundWakizashi,
    name = "Bound Wakizashi",
    effect = tes3.effect.boundWakizashi,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = spellIds.boundWarAxe,
    name = "Bound War Axe",
    effect = tes3.effect.boundWarAxe,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = spellIds.boundWarhammer,
    name = "Bound Warhammer",
    effect = tes3.effect.boundWarhammer,
    range = tes3.effectRange.self,
    duration = 30
  })

  framework.tomes.registerTomes(tomes)
end

event.register("MagickaExpanded:Register", registerSpells)