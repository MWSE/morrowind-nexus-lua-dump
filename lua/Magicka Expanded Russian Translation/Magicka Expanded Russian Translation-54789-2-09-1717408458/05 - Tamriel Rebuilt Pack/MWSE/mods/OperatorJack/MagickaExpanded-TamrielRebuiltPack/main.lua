local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

require("OperatorJack.MagickaExpanded-TamrielRebuiltPack.effects.summonEffectSet")
require("OperatorJack.MagickaExpanded-TamrielRebuiltPack.effects.teleportationEffectSet")

local teleportSpellIds = {
  akamora = "OJ_ME_TeleportToAkamora",
  firewatch = "OJ_ME_TeleportToFirewatch",
  helnim = "OJ_ME_TeleportToHelnim",
  necrom = "OJ_ME_TeleportToNecrom",
  oldEbonheart = "OJ_ME_TeleportToOldEbonheart",
  portTelvannis = "OJ_ME_TeleportToPortTelvannis",

  altBosara = "OJ_ME_TeleportToAltBosara",
  balOrya = "OJ_ME_TeleportToBalOrya",
  gahSadrith = "OJ_ME_TeleportToGahSadrith",
  gorne = "OJ_ME_TeleportToGorne",
  llothanis = "OJ_ME_TeleportToLlothanis",
  marog = "OJ_ME_TeleportToMarog",
  meralag = "OJ_ME_TeleportToMeralag",
  telAranyon = "OJ_ME_TeleportToTelAranyon",
  telMothrivra = "OJ_ME_TeleportToTelMothrivra",
  telMuthada = "OJ_ME_TeleportToTelMuthada",
  telOuada = "OJ_ME_TeleportToTelOuada"
}

local summonSpellIds = {
  alfiq = "OJ_ME_SummAlfiq",
  armorCenturion = "OJ_ME_SummArmorCent",
  armorCenturionChampion = "OJ_ME_SummArmorCentChamp",
  draugrHousecarl = "OJ_ME_SummDraugrHsCrl",
  draugrLord = "OJ_ME_SummDraugrLord",
  dridrea = "OJ_ME_SummDridrea",
  dridreaMonarch = "OJ_ME_SummDridreaMonarch",
  frostLich = "OJ_ME_SummFrostLich",
  giant = "OJ_ME_SummGiant",
  goblinShaman = "OJ_ME_SummGoblinShaman",
  greaterLich = "OJ_ME_SummGreaterLich",
  lamia = "OJ_ME_SummLamia",
  mammoth = "OJ_ME_SummMammoth",
  minotaur = "OJ_ME_SummMinotaur",
  mudGolem = "OJ_ME_SummMudGolem",
  parastylus = "OJ_ME_SummParastylus",
  plainStrider = "OJ_ME_SummPlainStrider",
  raki = "OJ_ME_SummRaki",
  sabreCat = "OJ_ME_SummSabreCat",
  siltStrider = "OJ_ME_SummSiltStrider",
  sload = "OJ_ME_SummSload",
  swampTroll = "OJ_ME_SummSwampTroll",
  welkyndSpirit = "OJ_ME_SummWelkSpirit",
  wereboar = "OJ_ME_SummWereBoar",
  velk = "OJ_ME_SummVelk",
  vermai = "OJ_ME_SummVermai",
  trebataur = "OJ_ME_SummTrebataur"
}

local teleportTomes = {
  {
    id = "OJ_ME_TomeTeleAkamora",
    spellId = teleportSpellIds.akamora,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleFirewatch",
    spellId = teleportSpellIds.firewatch,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleHelnim",
    spellId = teleportSpellIds.helnim,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleNecrom",
    spellId = teleportSpellIds.necrom,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleOldEbonheart",
    spellId = teleportSpellIds.oldEbonheart,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTelePortTelvannis",
    spellId = teleportSpellIds.portTelvannis,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleAltBosara",
    spellId = teleportSpellIds.altBosara,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleBalOrya",
    spellId = teleportSpellIds.balOrya,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleGahSadrith",
    spellId = teleportSpellIds.gahSadrith,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleGorne",
    spellId = teleportSpellIds.gorne,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleLlothanis",
    spellId = teleportSpellIds.llothanis,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleMarog",
    spellId = teleportSpellIds.marog,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleMeralag",
    spellId = teleportSpellIds.meralag,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleTelAranyon",
    spellId = teleportSpellIds.telAranyon,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleTelMothrivra",
    spellId = teleportSpellIds.telMothrivra,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleTelMuthada",
    spellId = teleportSpellIds.telMuthada,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeTeleTelOuada",
    spellId = teleportSpellIds.telOuada,
    list = "OJ_ME_LeveledList_Common"
  },
}

local summonTomes = {
  {
    id = "OJ_ME_TomeSummAlfiq",
    spellId = summonSpellIds.alfiq,
    list = "OJ_ME_LeveledList_Mythic"
  },
  {
    id = "OJ_ME_TomeSummArmorCent",
    spellId = summonSpellIds.armorCenturion,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeSummArmorCentChamp",
    spellId = summonSpellIds.armorCenturionChampion,
    list = "OJ_ME_LeveledList_Mythic"
  },
  {
    id = "OJ_ME_TomeSummDraugrHsCrl",
    spellId = summonSpellIds.draugrHousecarl,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeSummDraugrLord",
    spellId = summonSpellIds.draugrLord,
    list = "OJ_ME_LeveledList_Mythic"
  },
  {
    id = "OJ_ME_TomeSummDridrea",
    spellId = summonSpellIds.dridrea,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeSummDridreaMonarch",
    spellId = summonSpellIds.dridreaMonarch,
    list = "OJ_ME_LeveledList_Mythic"
  },
  {
    id = "OJ_ME_TomeSummFrostLich",
    spellId = summonSpellIds.frostLich,
    list = "OJ_ME_LeveledList_Mythic"
  },
  {
    id = "OJ_ME_TomeSummGiant",
    spellId = summonSpellIds.giant,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeSummGoblinShaman",
    spellId = summonSpellIds.goblinShaman,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeSummGreaterLich",
    spellId = summonSpellIds.greaterLich,
    list = "OJ_ME_LeveledList_Mythic"
  },
  {
    id = "OJ_ME_TomeSummLamia",
    spellId = summonSpellIds.lamia,
    list = "OJ_ME_LeveledList_Mythic"
  },
  {
    id = "OJ_ME_TomeSummMammoth",
    spellId = summonSpellIds.mammoth,
    list = "OJ_ME_LeveledList_Uncommon"
  },
  {
    id = "OJ_ME_TomeSummMinotaur",
    spellId = summonSpellIds.minotaur,
    list = "OJ_ME_LeveledList_Mythic"
  },
  {
    id = "OJ_ME_TomeSummMudGolem",
    spellId = summonSpellIds.mudGolem,
    list = "OJ_ME_LeveledList_Uncommon"
  },
  {
    id = "OJ_ME_TomeSummParastylus",
    spellId = summonSpellIds.parastylus,
    list = "OJ_ME_LeveledList_Uncommon"
  },
  {
    id = "OJ_ME_TomeSummPlainStrider",
    spellId = summonSpellIds.plainStrider,
    list = "OJ_ME_LeveledList_Uncommon"
  },
  {
    id = "OJ_ME_TomeSummRaki",
    spellId = summonSpellIds.raki,
    list = "OJ_ME_LeveledList_Uncommon"
  },
  {
    id = "OJ_ME_TomeSummSabreCat",
    spellId = summonSpellIds.sabreCat,
    list = "OJ_ME_LeveledList_Uncommon"
  },
  {
    id = "OJ_ME_TomeSummSiltStrider",
    spellId = summonSpellIds.siltStrider,
    list = "OJ_ME_LeveledList_Uncommon"
  },
  {
    id = "OJ_ME_TomeSummSload",
    spellId = summonSpellIds.sload,
    list = "OJ_ME_LeveledList_Uncommon"
  },
  {
    id = "OJ_ME_TomeSummSwampTroll",
    spellId = summonSpellIds.swampTroll,
    list = "OJ_ME_LeveledList_Uncommon"
  },
  {
    id = "OJ_ME_TomeSummWelkyndSpirit",
    spellId = summonSpellIds.welkyndSpirit,
    list = "OJ_ME_LeveledList_Uncommon"
  },
  {
    id = "OJ_ME_TomeSummWereboar",
    spellId = summonSpellIds.wereboar,
    list = "OJ_ME_LeveledList_Mythic"
  },
  {
    id = "OJ_ME_TomeSummVelk",
    spellId = summonSpellIds.velk,
    list = "OJ_ME_LeveledList_Common"
  },
  {
    id = "OJ_ME_TomeSummVermai",
    spellId = summonSpellIds.vermai,
    list = "OJ_ME_LeveledList_Uncommon"
  },
  {
    id = "OJ_ME_TomeSummTrebataur",
    spellId = summonSpellIds.trebataur,
    list = "OJ_ME_LeveledList_Mythic"
  }
}

local function addTomesToLists()
  if not tes3.isModActive("Tamriel_Data.esm") then
    return
  end

  for _, tome in pairs(teleportTomes) do
    mwscript.addToLevItem({
      list = tome.list,
      item = tome.id,
      level = 1
    })
  end
  for _, tome in pairs(summonTomes) do
    mwscript.addToLevItem({
      list = tome.list,
      item = tome.id,
      level = 1
    })
  end
end
event.register("initialized", addTomesToLists)
 

local function registerSpells()
  if not tes3.isModActive("Tamriel_Data.esm") then
    mwse.log("[Magicka Expanded - Tamriel Rebuilt Pack: INFO] Tamriel_Data.esm not loaded")
    tes3.messageBox("[Расширенная магия - пак Tamriel Rebuilt: INFO] Tamriel_Data.esm не загружен")
    return
  end

  framework.spells.createBasicSpell({
    id = teleportSpellIds.akamora,
    name = "Телепорт в Акамору",
    effect = tes3.effect.teleportToAkamora,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.firewatch,
    name = "Телепорт в Файрвотч",
    effect = tes3.effect.teleportToFirewatch,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.helnim,
    name = "Телепорт в Хелним",
    effect = tes3.effect.teleportToHelnim,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.necrom,
    name = "Телепорт в Некром",
    effect = tes3.effect.teleportToNecrom,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.oldEbonheart,
    name = "Телепорт в Старый Эбенгард",
    effect = tes3.effect.teleportToOldEbonheart,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.portTelvannis,
    name = "Телепорт в Порт Тельваннис",
    effect = tes3.effect.teleportToPortTelvannis,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.altBosara,
    name = "Телепорт в Альт Босару",
    effect = tes3.effect.teleportToAltBosara,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.balOrya,
    name = "Телепорт в Бал Ориа",
    effect = tes3.effect.teleportToBalOrya,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.gahSadrith,
    name = "Телепорт в Га Садрит",
    effect = tes3.effect.teleportToGahSadrith,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.gorne,
    name = "Телепорт в Горн",
    effect = tes3.effect.teleportToGorne,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.llothanis,
    name = "Телепорт в Ллотанис",
    effect = tes3.effect.teleportToLlothanis,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.marog,
    name = "Телепорт в Марог",
    effect = tes3.effect.teleportToMarog,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.meralag,
    name = "Телепорт в Мералаг",
    effect = tes3.effect.teleportToMeralag,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.telAranyon,
    name = "Телепорт в Тель Араньон",
    effect = tes3.effect.teleportToTelAranyon,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.telMothrivra,
    name = "Телепорт в Тель Мотривру",
    effect = tes3.effect.teleportToTelMothrivra,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.telMuthada,
    name = "Телепорт в Тель Мутаду",
    effect = tes3.effect.teleportToTelMuthada,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = teleportSpellIds.telOuada,
    name = "Телепорт в Тель Оуаду",
    effect = tes3.effect.teleportToTelOuada,
    range = tes3.effectRange.self
  })

  
  framework.spells.createBasicSpell({
    id = summonSpellIds.armorCenturion,
    name = "Вызов бронированного центуриона",
    effect = tes3.effect.summonArmorCent,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.armorCenturionChampion,
    name = "Вызов бронированного центуриона-чемпиона",
    effect = tes3.effect.summonArmorCentChamp,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.draugrHousecarl,
    name = "Вызов Драугра-хускарла",
    effect = tes3.effect.summonDraugrHsCrl,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.draugrLord,
    name = "Вызов Драугра-повелителя",
    effect = tes3.effect.summonDraugrLord,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.dridrea,
    name = "Вызов Дридреи",
    effect = tes3.effect.summonDridrea,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.dridreaMonarch,
    name = "Вызов Дридреи-монарха",
    effect = tes3.effect.summonDridreaMonarch,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.frostLich,
    name = "Вызов Морозного лича",
    effect = tes3.effect.summonFrostLich,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.giant,
    name = "Вызов Гиганта",
    effect = tes3.effect.summonGiant,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.goblinShaman,
    name = "Вызов Гоблина-шамана",
    effect = tes3.effect.summonGoblinShaman,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.greaterLich,
    name = "Вызов Великого лича",
    effect = tes3.effect.summonGreaterLich,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.lamia,
    name = "Вызов Ламии",
    effect = tes3.effect.summonLamia,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.mammoth,
    name = "Вызов Мамонта",
    effect = tes3.effect.summonMammoth,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.minotaur,
    name = "Вызов Минотавра",
    effect = tes3.effect.summonMinotaur,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.mudGolem,
    name = "Вызов Грязевого голема",
    effect = tes3.effect.summonMudGolem,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.parastylus,
    name = "Вызов Парастилуса",
    effect = tes3.effect.summonParastylus,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.plainStrider,
    name = "Вызов Плейн страйдера",
    effect = tes3.effect.summonPlainStrider,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.raki,
    name = "Вызов Раки",
    effect = tes3.effect.summonRaki,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.sabreCat,
    name = "Вызов Саблезуба",
    effect = tes3.effect.callSabreCat,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.siltStrider,
    name = "Вызов Силт Страйдера",
    effect = tes3.effect.summonSiltStrider,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.sload,
    name = "Вызов Слоада",
    effect = tes3.effect.summonSload,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.swampTroll,
    name = "Вызов Болотного Тролля",
    effect = tes3.effect.summonSwampTroll,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.welkyndSpirit,
    name = "Вызов Велкиндского духа",
    effect = tes3.effect.summonWelkyndSpirit,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.wereboar,
    name = "Вызов Кабана-оборотня",
    effect = tes3.effect.callWereboar,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.velk,
    name = "Вызов Велька",
    effect = tes3.effect.summonVelk,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.vermai,
    name = "Вызов Вермая",
    effect = tes3.effect.summonVermai,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.trebataur,
    name = "Вызов Требатавра",
    effect = tes3.effect.summonTrebataur,
    range = tes3.effectRange.self,
    duration = 30
  })
  framework.spells.createBasicSpell({
    id = summonSpellIds.alfiq,
    name = "Вызов Альфика",
    effect = tes3.effect.summonAlfiq,
    range = tes3.effectRange.self,
    duration = 30
  })
  
  framework.tomes.registerTomes(teleportTomes)
  framework.tomes.registerTomes(summonTomes)
end

event.register("MagickaExpanded:Register", registerSpells)