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
        name = "Summon War Durzog",
        distribute = true,
        effect = tes3.effect.summonWarDurzog,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.goblinGrunt,
        name = "Summon Goblin",
        distribute = true,
        effect = tes3.effect.summonGoblinGrunt,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.goblinOfficer,
        name = "Summon Goblin Officer",
        distribute = true,
        effect = tes3.effect.summonGoblinOfficer,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.goblinWarchief,
        name = "Summon Goblin Warchief",
        distribute = true,
        effect = tes3.effect.summonGoblinWarchief,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.hulkingFabricant,
        name = "Summon Hulking Fabricant",
        distribute = true,
        effect = tes3.effect.summonHulkingFabricant,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.imperfect,
        name = "Summon Imperfect",
        distribute = true,
        effect = tes3.effect.summonImperfect,
        rangeType = tes3.effectRange.self,
        duration = 15
    })
    framework.spells.createBasicSpell({
        id = spellIds.ascendedSleeper,
        name = "Summon Ascended Sleeper",
        distribute = true,
        effect = tes3.effect.summonAscendedSleeper,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.ashGhoul,
        name = "Summon Ash Ghoul",
        distribute = true,
        effect = tes3.effect.summonAshGhoul,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.ashZombie,
        name = "Summon Ash Zombie",
        distribute = true,
        effect = tes3.effect.summonAshZombie,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.ashSlave,
        name = "Summon Ash Slave",
        distribute = true,
        effect = tes3.effect.summonAshSlave,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.draugr,
        name = "Summon Draugr",
        distribute = true,
        effect = tes3.effect.summonDraugr,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.lich,
        name = "Summon Lich",
        distribute = true,
        effect = tes3.effect.summonLich,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.ogrim,
        name = "Summon Ogrim",
        distribute = true,
        effect = tes3.effect.summonOgrim,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.spriggran,
        name = "Summon Spriggan",
        distribute = true,
        effect = tes3.effect.summonSpriggan,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.centurionSteam,
        name = "Summon Steam Centurion",
        distribute = true,
        effect = tes3.effect.summonCenturionSteam,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.centurionArcher,
        name = "Summon Centurion Archer",
        distribute = true,
        effect = tes3.effect.summonCenturionProjectile,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.centurionSpider,
        name = "Summon Centurion Spider",
        distribute = true,
        effect = tes3.effect.summonCenturionSpider,
        rangeType = tes3.effectRange.self,
        duration = 30
    })
    framework.spells.createBasicSpell({
        id = spellIds.centurionSphere,
        name = "Summon Centurion Sphere",
        distribute = true,
        effect = tes3.effect.summonCenturionSphere,
        rangeType = tes3.effectRange.self,
        duration = 30
    })

    framework.grimoires.registerGrimoires(grimoires)
    framework.tomes.registerTomes(tomes)
end

event.register("MagickaExpanded:Register", registerSpells)
