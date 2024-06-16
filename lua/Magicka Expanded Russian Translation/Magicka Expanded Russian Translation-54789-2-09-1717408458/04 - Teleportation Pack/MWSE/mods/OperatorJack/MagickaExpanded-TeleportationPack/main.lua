local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

require("OperatorJack.MagickaExpanded-TeleportationPack.effects.teleportationEffectSet")

local spellIds = {
  aldruhn = "OJ_ME_TeleportToAldRuhn",
  balmora = "OJ_ME_TeleportToBalmora",
  ebonheart = "OJ_ME_TeleportToEbonheart",
  vivec = "OJ_ME_TeleportToVivec",
  
  caldera = "OJ_ME_TeleportToCaldera",
  gnisis = "OJ_ME_TeleportToGnisis",
  maargan = "OJ_ME_TeleportToMaarGan",
  molagmar = "OJ_ME_TeleportToMolagMar",
  pelagiad = "OJ_ME_TeleportToPelagiad",
  suran = "OJ_ME_TeleportToSuran",
  telmora = "OJ_ME_TeleportToTelMora",

  mournhold = "OJ_ME_TeleportToMournhold"
}

local tomes = {
  {
    id = "OJ_ME_TomeTeleAldRuhn",
    spellId = spellIds.aldruhn,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleBalmora",
    spellId = spellIds.balmora,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleEbonheart",
    spellId = spellIds.ebonheart,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleVivec",
    spellId = spellIds.vivec,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleCaldera",
    spellId = spellIds.caldera,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleGnisis",
    spellId = spellIds.gnisis,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleMaarGan",
    spellId = spellIds.maargan,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleMolagMar",
    spellId = spellIds.molagmar,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTelePelagiad",
    spellId = spellIds.pelagiad,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleSuran",
    spellId = spellIds.suran,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleTelMora",
    spellId = spellIds.telmora,
    list = "OJ_ME_LeveledList_Common"
  },

  {
    id = "OJ_ME_TomeTeleMournhold",
    spellId = spellIds.mournhold,
    list = "OJ_ME_LeveledList_Common"
  },
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
    id = spellIds.mournhold,
    name = "Телепорт в Морнхолд",
    effect = tes3.effect.teleportToMournhold,
    range = tes3.effectRange.self
  })

  framework.spells.createBasicSpell({
    id = spellIds.aldruhn,
    name = "Телепорт в Альд'рун",
    effect = tes3.effect.teleportToAldRuhn,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = spellIds.balmora,
    name = "Телепорт в Балмору",
    effect = tes3.effect.teleportToBalmora,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = spellIds.ebonheart,
    name = "Телепорт в Эбенгард",
    effect = tes3.effect.teleportToEbonheart,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = spellIds.vivec,
    name = "Телепорт в Вивек",
    effect = tes3.effect.teleportToVivec,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = spellIds.caldera,
    name = "Телепорт в Кальдеру",
    effect = tes3.effect.teleportToCaldera,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = spellIds.gnisis,
    name = "Телепорт в Гнисис",
    effect = tes3.effect.teleportToGnisis,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = spellIds.maargan,
    name = "Телепорт в Маар Ган",
    effect = tes3.effect.teleportToMaarGan,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = spellIds.molagmar,
    name = "Телепорт в Молаг Мар",
    effect = tes3.effect.teleportToMolagMar,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = spellIds.pelagiad,
    name = "Телепорт в Пелагиад",
    effect = tes3.effect.teleportToPelagiad,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = spellIds.suran,
    name = "Телепорт в Суран",
    effect = tes3.effect.teleportToSuran,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = spellIds.telmora,
    name = "Телепорт в Тель Мору",
    effect = tes3.effect.teleportToTelMora,
    range = tes3.effectRange.self
  })
  
  framework.tomes.registerTomes(tomes)
end

event.register("MagickaExpanded:Register", registerSpells)