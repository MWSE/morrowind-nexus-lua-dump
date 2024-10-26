local framework = require("OperatorJack.MagickaExpanded")

local spellIds = {
    warDurzog = "OJ_ME_SummWarDurzogSpell",
    goblinGrunt = "OJ_ME_SummGoblinGruntSpell",
    goblinOfficer = "OJ_ME_SummGoblinOfficerSpell",
    goblinWarchief = "OJ_ME_SummGoblinWarchiefSpell",
    hulkingFabricant = "OJ_ME_SummHulkingFabSpell",
    imperfect = "OJ_ME_SummImperfectSpell",
    ascendedSleeper = "OJ_ME_SummAscendedSleeperSpell",
    ashGhoul = "OJ_ME_SummAshGhoulSpell",
    ashZombie = "OJ_ME_SummAshZombieSpell",
    ashSlave = "OJ_ME_SummAshSlaveSpell",
    draugr = "OJ_ME_SummDraugrSpell",
    lich = "OJ_ME_SummLichSpell",
    ogrim = "OJ_ME_SummOgrimSpell",
    spriggran = "OJ_ME_SummSprigganSpell",
    centurionSteam = "OJ_ME_SummCenturionSteamSpell",
    centurionArcher = "OJ_ME_SummCenturionArcherSpell",
    centurionSpider = "OJ_ME_SummCenturionSpiderSpell",
    centurionSphere = "OJ_ME_SummCenturionSphereSpell"
}

local grimoires = {
    {
        id = "OJ_ME_GrimoireSummGoblin",
        spellIds = {
            spellIds.warDurzog, spellIds.goblinGrunt, spellIds.goblinOfficer,
            spellIds.goblinWarchief
        },
        list = "OJ_ME_LeveledList_Mythic"
    }, {
        id = "OJ_ME_GrimoireSumm6thHouse",
        spellIds = {spellIds.ashGhoul, spellIds.ashSlave, spellIds.ashZombie},
        list = "OJ_ME_LeveledList_Mythic"
    }, {
        id = "OJ_ME_GrimoireSummUndead",
        spellIds = {spellIds.lich, spellIds.draugr},
        list = "OJ_ME_LeveledList_Mythic"
    }, {
        id = "OJ_ME_GrimoireSummCenturion",
        spellIds = {
            spellIds.centurionArcher, spellIds.centurionSpider, spellIds.centurionSteam,
            spellIds.centurionSphere
        },
        list = "OJ_ME_LeveledList_Mythic"
    }
}

local tomes = {
    {
        id = "OJ_ME_TomeSummWarDurzog",
        spellId = spellIds.warDurzog,
        list = "OJ_ME_LeveledList_Common"
    },
    {id = "OJ_ME_TomeSummGoblin", spellId = spellIds.goblinGrunt, list = "OJ_ME_LeveledList_Common"},
    {
        id = "OJ_ME_TomeSummGoblinOfficer",
        spellId = spellIds.goblinOfficer,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeSummGoblinWarChf",
        spellId = spellIds.goblinWarchief,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeSummHulkingFbrt",
        spellId = spellIds.hulkingFabricant,
        list = "OJ_ME_LeveledList_Rare"
    },
    {
        id = "OJ_ME_TomeSummImperfect",
        spellId = spellIds.imperfect,
        list = "OJ_ME_LeveledList_Mythic"
    }, {
        id = "OJ_ME_TomeSummAscdSlper",
        spellId = spellIds.ascendedSleeper,
        list = "OJ_ME_LeveledList_Rare"
    },
    {
        id = "OJ_ME_TomeSummAshGhoul",
        spellId = spellIds.ashGhoul,
        list = "OJ_ME_LeveledList_Uncommon"
    },
    {
        id = "OJ_ME_TomeSummAshSlave",
        spellId = spellIds.ashSlave,
        list = "OJ_ME_LeveledList_Uncommon"
    },
    {
        id = "OJ_ME_TomeSummAshZombie",
        spellId = spellIds.ashZombie,
        list = "OJ_ME_LeveledList_Uncommon"
    },
    {id = "OJ_ME_TomeSummDraugr", spellId = spellIds.draugr, list = "OJ_ME_LeveledList_Uncommon"},
    {id = "OJ_ME_TomeSummLich", spellId = spellIds.lich, list = "OJ_ME_LeveledList_Rare"},
    {id = "OJ_ME_TomeSummOgrim", spellId = spellIds.ogrim, list = "OJ_ME_LeveledList_Rare"},
    {
        id = "OJ_ME_TomeSummSpriggan",
        spellId = spellIds.spriggran,
        list = "OJ_ME_LeveledList_Uncommon"
    }, {
        id = "OJ_ME_TomeSummCentArcher",
        spellId = spellIds.centurionArcher,
        list = "OJ_ME_LeveledList_Uncommon"
    }, {
        id = "OJ_ME_TomeSummCentSpdr",
        spellId = spellIds.centurionSpider,
        list = "OJ_ME_LeveledList_Common"
    },
    {
        id = "OJ_ME_TomeSummCentStm",
        spellId = spellIds.centurionSteam,
        list = "OJ_ME_LeveledList_Rare"
    }
}

event.register(tes3.event.initialized, function()
    require("OperatorJack.MagickaExpanded-SummoningPack.effects.basicSummonEffects")

    for _, tome in pairs(tomes) do
        local item = tes3.getObject(tome.id)

        local list = tes3.getObject(tome.list) --[[@as tes3leveledItem]]
        list:insert(item, 1)
    end
    for _, grimoire in pairs(grimoires) do
        local item = tes3.getObject(grimoire.id)

        local list = tes3.getObject(grimoire.list) --[[@as tes3leveledItem]]
        list:insert(item, 1)
    end
end)

local function registerSpells()
    framework.spells.createBasicSpell({
        id = spellIds.warDurzog,
        name = "Вызов Боевого дурзога",
        distribute = true,
        effect = tes3.effect.summonWarDurzog,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.goblinGrunt,
        name = "Вызов Гоблина",
        distribute = true,
        effect = tes3.effect.summonGoblinGrunt,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.goblinOfficer,
        name = "Вызов Гоблина-офицера",
        distribute = true,
        effect = tes3.effect.summonGoblinOfficer,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.goblinWarchief,
        name = "Вызов Гоблина-предводителя",
        distribute = true,
        effect = tes3.effect.summonGoblinWarchief,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.hulkingFabricant,
        name = "Вызов Гигантского фабриканта",
        distribute = true,
        effect = tes3.effect.summonHulkingFabricant,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.imperfect,
        name = "Вызов Несовершенства",
        distribute = true,
        effect = tes3.effect.summonImperfect,
        rangeType = tes3.effectRange.self,
        duration = 15
    })
    framework.spells.createBasicSpell({
        id = spellIds.ascendedSleeper,
        name = "Вызов Поднявшегося спящего",
        distribute = true,
        effect = tes3.effect.summonAscendedSleeper,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.ashGhoul,
        name = "Вызов Пепельного упыря",
        distribute = true,
        effect = tes3.effect.summonAshGhoul,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.ashZombie,
        name = "Вызов Пепельного зомби",
        distribute = true,
        effect = tes3.effect.summonAshZombie,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.ashSlave,
        name = "Вызов Раба пепла",
        distribute = true,
        effect = tes3.effect.summonAshSlave,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.draugr,
        name = "Вызов Драугра",
        distribute = true,
        effect = tes3.effect.summonDraugr,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.lich,
        name = "Вызов Лича",
        distribute = true,
        effect = tes3.effect.summonLich,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.ogrim,
        name = "Вызов Огрима",
        distribute = true,
        effect = tes3.effect.summonOgrim,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.spriggran,
        name = "Вызов Сприггана",
        distribute = true,
        effect = tes3.effect.summonSpriggan,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.centurionSteam,
        name = "Вызов Парового центуриона",
        distribute = true,
        effect = tes3.effect.summonCenturionSteam,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.centurionArcher,
        name = "Вызов Центуриона-лучника",
        distribute = true,
        effect = tes3.effect.summonCenturionProjectile,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.centurionSpider,
        name = "Вызов Паука-центуриона",
        distribute = true,
        effect = tes3.effect.summonCenturionSpider,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.centurionSphere,
        name = "Вызов Сферы-Центуриона",
        distribute = true,
        effect = tes3.effect.summonCenturionSphere,
        rangeType = tes3.effectRange.self,
        duration = 30
    })

    framework.grimoires.registerGrimoires(grimoires)
    framework.tomes.registerTomes(tomes)
end

event.register("MagickaExpanded:Register", registerSpells)
