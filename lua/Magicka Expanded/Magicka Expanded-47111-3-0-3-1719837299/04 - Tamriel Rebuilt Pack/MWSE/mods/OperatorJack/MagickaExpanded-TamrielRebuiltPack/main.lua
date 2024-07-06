local framework = require("OperatorJack.MagickaExpanded")

if not tes3.isModActive("Tamriel_Data.esm") then
    mwse.log("[Magicka Expanded - Tamriel Rebuilt Pack: INFO] Tamriel_Data.esm not loaded")
    tes3.messageBox("[Magicka Expanded - Tamriel Rebuilt Pack: INFO] Tamriel_Data.esm not loaded")
    return
end

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
    velk = "OJ_ME_SummVelk",
    vermai = "OJ_ME_SummVermai",
    trebataur = "OJ_ME_SummTrebataur"
}

local teleportTomes = {
    {
        id = "OJ_ME_TomeTeleAkamora",
        spellId = teleportSpellIds.akamora,
        list = "OJ_ME_LeveledList_Common"
    }, {
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
    }, {
        id = "OJ_ME_TomeTeleOldEbonheart",
        spellId = teleportSpellIds.oldEbonheart,
        list = "OJ_ME_LeveledList_Common"
    }, {
        id = "OJ_ME_TomeTelePortTelvannis",
        spellId = teleportSpellIds.portTelvannis,
        list = "OJ_ME_LeveledList_Common"
    }, {
        id = "OJ_ME_TomeTeleAltBosara",
        spellId = teleportSpellIds.altBosara,
        list = "OJ_ME_LeveledList_Common"
    }, {
        id = "OJ_ME_TomeTeleBalOrya",
        spellId = teleportSpellIds.balOrya,
        list = "OJ_ME_LeveledList_Common"
    }, {
        id = "OJ_ME_TomeTeleGahSadrith",
        spellId = teleportSpellIds.gahSadrith,
        list = "OJ_ME_LeveledList_Common"
    },
    {
        id = "OJ_ME_TomeTeleGorne",
        spellId = teleportSpellIds.gorne,
        list = "OJ_ME_LeveledList_Common"
    }, {
        id = "OJ_ME_TomeTeleLlothanis",
        spellId = teleportSpellIds.llothanis,
        list = "OJ_ME_LeveledList_Common"
    },
    {
        id = "OJ_ME_TomeTeleMarog",
        spellId = teleportSpellIds.marog,
        list = "OJ_ME_LeveledList_Common"
    }, {
        id = "OJ_ME_TomeTeleMeralag",
        spellId = teleportSpellIds.meralag,
        list = "OJ_ME_LeveledList_Common"
    }, {
        id = "OJ_ME_TomeTeleTelAranyon",
        spellId = teleportSpellIds.telAranyon,
        list = "OJ_ME_LeveledList_Common"
    }, {
        id = "OJ_ME_TomeTeleTelMothrivra",
        spellId = teleportSpellIds.telMothrivra,
        list = "OJ_ME_LeveledList_Common"
    }, {
        id = "OJ_ME_TomeTeleTelMuthada",
        spellId = teleportSpellIds.telMuthada,
        list = "OJ_ME_LeveledList_Common"
    }, {
        id = "OJ_ME_TomeTeleTelOuada",
        spellId = teleportSpellIds.telOuada,
        list = "OJ_ME_LeveledList_Common"
    }
}

local summonTomes = {
    {id = "OJ_ME_TomeSummAlfiq", spellId = summonSpellIds.alfiq, list = "OJ_ME_LeveledList_Mythic"},
    {
        id = "OJ_ME_TomeSummArmorCent",
        spellId = summonSpellIds.armorCenturion,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeSummArmorCentChamp",
        spellId = summonSpellIds.armorCenturionChampion,
        list = "OJ_ME_LeveledList_Mythic"
    }, {
        id = "OJ_ME_TomeSummDraugrHsCrl",
        spellId = summonSpellIds.draugrHousecarl,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeSummDraugrLord",
        spellId = summonSpellIds.draugrLord,
        list = "OJ_ME_LeveledList_Mythic"
    },
    {
        id = "OJ_ME_TomeSummDridrea",
        spellId = summonSpellIds.dridrea,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeSummDridreaMonarch",
        spellId = summonSpellIds.dridreaMonarch,
        list = "OJ_ME_LeveledList_Mythic"
    }, {
        id = "OJ_ME_TomeSummFrostLich",
        spellId = summonSpellIds.frostLich,
        list = "OJ_ME_LeveledList_Mythic"
    },
    {id = "OJ_ME_TomeSummGiant", spellId = summonSpellIds.giant, list = "OJ_ME_LeveledList_Rare"},
    {
        id = "OJ_ME_TomeSummGoblinShaman",
        spellId = summonSpellIds.goblinShaman,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeSummGreaterLich",
        spellId = summonSpellIds.greaterLich,
        list = "OJ_ME_LeveledList_Mythic"
    },
    {id = "OJ_ME_TomeSummLamia", spellId = summonSpellIds.lamia, list = "OJ_ME_LeveledList_Mythic"},
    {
        id = "OJ_ME_TomeSummMammoth",
        spellId = summonSpellIds.mammoth,
        list = "OJ_ME_LeveledList_Uncommon"
    }, {
        id = "OJ_ME_TomeSummMinotaur",
        spellId = summonSpellIds.minotaur,
        list = "OJ_ME_LeveledList_Mythic"
    }, {
        id = "OJ_ME_TomeSummMudGolem",
        spellId = summonSpellIds.mudGolem,
        list = "OJ_ME_LeveledList_Uncommon"
    }, {
        id = "OJ_ME_TomeSummParastylus",
        spellId = summonSpellIds.parastylus,
        list = "OJ_ME_LeveledList_Uncommon"
    }, {
        id = "OJ_ME_TomeSummPlainStrider",
        spellId = summonSpellIds.plainStrider,
        list = "OJ_ME_LeveledList_Uncommon"
    },
    {id = "OJ_ME_TomeSummRaki", spellId = summonSpellIds.raki, list = "OJ_ME_LeveledList_Uncommon"},
    {
        id = "OJ_ME_TomeSummSabreCat",
        spellId = summonSpellIds.sabreCat,
        list = "OJ_ME_LeveledList_Uncommon"
    }, {
        id = "OJ_ME_TomeSummSiltStrider",
        spellId = summonSpellIds.siltStrider,
        list = "OJ_ME_LeveledList_Uncommon"
    },
    {
        id = "OJ_ME_TomeSummSload",
        spellId = summonSpellIds.sload,
        list = "OJ_ME_LeveledList_Uncommon"
    }, {
        id = "OJ_ME_TomeSummSwampTroll",
        spellId = summonSpellIds.swampTroll,
        list = "OJ_ME_LeveledList_Uncommon"
    }, {
        id = "OJ_ME_TomeSummWelkyndSpirit",
        spellId = summonSpellIds.welkyndSpirit,
        list = "OJ_ME_LeveledList_Uncommon"
    },
    {id = "OJ_ME_TomeSummVelk", spellId = summonSpellIds.velk, list = "OJ_ME_LeveledList_Common"},
    {
        id = "OJ_ME_TomeSummVermai",
        spellId = summonSpellIds.vermai,
        list = "OJ_ME_LeveledList_Uncommon"
    }, {
        id = "OJ_ME_TomeSummTrebataur",
        spellId = summonSpellIds.trebataur,
        list = "OJ_ME_LeveledList_Mythic"
    }
}

event.register(tes3.event.initialized, function()
    require("OperatorJack.MagickaExpanded-TamrielRebuiltPack.effects")

    for _, tome in pairs(teleportTomes) do
        local item = tes3.getObject(tome.id)
        local list = tes3.getObject(tome.list) --[[@as tes3leveledItem]]
        list:insert(item, 1)
    end
    for _, tome in pairs(summonTomes) do
        local item = tes3.getObject(tome.id)
        local list = tes3.getObject(tome.list) --[[@as tes3leveledItem]]
        list:insert(item, 1)
    end
end)

local function registerSpells()

    framework.spells.createBasicSpell({
        id = teleportSpellIds.akamora,
        name = "Teleport to Akamora",
        distribute = true,
        effect = tes3.effect.teleportToAkamora,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.firewatch,
        name = "Teleport to Firewatch",
        distribute = true,
        effect = tes3.effect.teleportToFirewatch,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.helnim,
        name = "Teleport to Helnim",
        distribute = true,
        effect = tes3.effect.teleportToHelnim,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.necrom,
        name = "Teleport to Necrom",
        distribute = true,
        effect = tes3.effect.teleportToNecrom,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.oldEbonheart,
        name = "Teleport to Old Ebonheart",
        distribute = true,
        effect = tes3.effect.teleportToOldEbonheart,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.portTelvannis,
        name = "Teleport to Port Telvannis",
        distribute = true,
        effect = tes3.effect.teleportToPortTelvannis,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.altBosara,
        name = "Teleport to Alt Bosara",
        distribute = true,
        effect = tes3.effect.teleportToAltBosara,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.balOrya,
        name = "Teleport to Bal Orya",
        distribute = true,
        effect = tes3.effect.teleportToBalOrya,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.gahSadrith,
        name = "Teleport to Gah Sadrith",
        distribute = true,
        effect = tes3.effect.teleportToGahSadrith,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.gorne,
        name = "Teleport to Gorne",
        distribute = true,
        effect = tes3.effect.teleportToGorne,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.llothanis,
        name = "Teleport to Llothanis",
        distribute = true,
        effect = tes3.effect.teleportToLlothanis,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.marog,
        name = "Teleport to Marog",
        distribute = true,
        effect = tes3.effect.teleportToMarog,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.meralag,
        name = "Teleport to Meralag",
        distribute = true,
        effect = tes3.effect.teleportToMeralag,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.telAranyon,
        name = "Teleport to Tel Aranyon",
        distribute = true,
        effect = tes3.effect.teleportToTelAranyon,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.telMothrivra,
        name = "Teleport to Tel Mothrivra",
        distribute = true,
        effect = tes3.effect.teleportToTelMothrivra,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.telMuthada,
        name = "Teleport to Tel Muthada",
        distribute = true,
        effect = tes3.effect.teleportToTelMuthada,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })
    framework.spells.createBasicSpell({
        id = teleportSpellIds.telOuada,
        name = "Teleport to Tel Ouada",
        distribute = true,
        effect = tes3.effect.teleportToTelOuada,
        rangeType = tes3.effectRange.self,
        magickaCost = 50
    })

    framework.spells.createBasicSpell({
        id = summonSpellIds.armorCenturion,
        name = "Summon Armor Centurion",
        distribute = true,
        effect = tes3.effect.summonArmorCent,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.armorCenturionChampion,
        name = "Summon Armor Centurion Champion",
        distribute = true,
        effect = tes3.effect.summonArmorCentChamp,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.draugrHousecarl,
        name = "Summon Draugr Housecarl",
        distribute = true,
        effect = tes3.effect.summonDraugrHsCrl,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.draugrLord,
        name = "Summon Draugr Lord",
        distribute = true,
        effect = tes3.effect.summonDraugrLord,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.dridrea,
        name = "Summon Dridrea",
        distribute = true,
        effect = tes3.effect.summonDridrea,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.dridreaMonarch,
        name = "Summon Dridrea Monarch",
        distribute = true,
        effect = tes3.effect.summonDridreaMonarch,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.frostLich,
        name = "Summon Frost Lich",
        distribute = true,
        effect = tes3.effect.summonFrostLich,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.giant,
        name = "Summon Giant",
        distribute = true,
        effect = tes3.effect.summonGiant,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.goblinShaman,
        name = "Summon Goblin Shaman",
        distribute = true,
        effect = tes3.effect.summonGoblinShaman,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.greaterLich,
        name = "Summon Greater Lich",
        distribute = true,
        effect = tes3.effect.summonGreaterLich,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.lamia,
        name = "Summon Lamia",
        distribute = true,
        effect = tes3.effect.summonLamia,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.mammoth,
        name = "Summon Mammoth",
        distribute = true,
        effect = tes3.effect.summonMammoth,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.minotaur,
        name = "Summon Minotaur",
        distribute = true,
        effect = tes3.effect.summonMinotaur,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.mudGolem,
        name = "Summon Mud Golem",
        distribute = true,
        effect = tes3.effect.summonMudGolem,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.parastylus,
        name = "Summon Parastylus",
        distribute = true,
        effect = tes3.effect.summonParastylus,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.plainStrider,
        name = "Summon Plain Strider",
        distribute = true,
        effect = tes3.effect.summonPlainStrider,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.raki,
        name = "Summon Raki",
        distribute = true,
        effect = tes3.effect.summonRaki,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.sabreCat,
        name = "Call Sabre Cat",
        distribute = true,
        effect = tes3.effect.callSabreCat,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.siltStrider,
        name = "Summon Silt Strider",
        distribute = true,
        effect = tes3.effect.summonSiltStrider,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.sload,
        name = "Summon Sload",
        distribute = true,
        effect = tes3.effect.summonSload,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.swampTroll,
        name = "Summon Swamp Troll",
        distribute = true,
        effect = tes3.effect.summonSwampTroll,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.welkyndSpirit,
        name = "Summon Welkynd Spirit",
        distribute = true,
        effect = tes3.effect.summonWelkyndSpirit,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.velk,
        name = "Summon Velk",
        distribute = true,
        effect = tes3.effect.summonVelk,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.vermai,
        name = "Summon Vermai",
        distribute = true,
        effect = tes3.effect.summonVermai,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.trebataur,
        name = "Summon Trebataur",
        distribute = true,
        effect = tes3.effect.summonTrebataur,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = summonSpellIds.alfiq,
        name = "Summon Alfiq",
        distribute = true,
        effect = tes3.effect.summonAlfiq,
        rangeType = tes3.effectRange.self,
        duration = 30
    })

    framework.tomes.registerTomes(teleportTomes)
    framework.tomes.registerTomes(summonTomes)
end

event.register("MagickaExpanded:Register", registerSpells)
