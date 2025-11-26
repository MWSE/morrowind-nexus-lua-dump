local core = require("openmw.core")
local T = require("openmw.types")

local EffectTypes = core.magic.EFFECT_TYPE
local RangeTypes = core.magic.RANGE

local module = {}

module.logLevels = { None = 1, Info = 2, Debug = 3 }

module.chancePresets = { VeryRare = 1, Rare = 2, Common = 3, VeryCommon = 4 }

module.affixes = { Prefix = "prefix", Suffix = "suffix", Any = "affix" }
module.affixes.other = function(affixType)
    return affixType == module.affixes.Prefix and module.affixes.Suffix or module.affixes.Prefix
end
module.affixes.pick = function()
    if math.random() < 0.5 then
        return { module.affixes.Prefix, module.affixes.Suffix }
    else
        return { module.affixes.Suffix, module.affixes.Prefix }
    end
end

module.castTypesWithCharges = {
    [core.magic.ENCHANTMENT_TYPE.CastOnUse] = true,
    [core.magic.ENCHANTMENT_TYPE.CastOnStrike] = true,
}

local modEffectConflicts = {
    [EffectTypes.Burden] = { EffectTypes.Feather },
    [EffectTypes.Lock] = { EffectTypes.Open },
    [EffectTypes.Levitate] = { EffectTypes.WaterBreathing, EffectTypes.WaterWalking, EffectTypes.SwiftSwim, EffectTypes.Jump },
    [EffectTypes.WaterWalking] = { EffectTypes.WaterBreathing, EffectTypes.SwiftSwim },
    [EffectTypes.DemoralizeHumanoid] = { EffectTypes.RallyHumanoid },
    [EffectTypes.DemoralizeCreature] = { EffectTypes.RallyCreature },
    [EffectTypes.WeaknessToFire] = { EffectTypes.ResistFire, EffectTypes.FireShield },
    [EffectTypes.WeaknessToFrost] = { EffectTypes.ResistFrost, EffectTypes.FrostShield },
    [EffectTypes.WeaknessToShock] = { EffectTypes.ResistShock, EffectTypes.LightningShield },
    [EffectTypes.WeaknessToMagicka] = { EffectTypes.ResistMagicka },
    [EffectTypes.WeaknessToPoison] = { EffectTypes.ResistPoison, EffectTypes.CurePoison },
    [EffectTypes.WeaknessToCommonDisease] = { EffectTypes.ResistCommonDisease, EffectTypes.CureCommonDisease },
    [EffectTypes.WeaknessToBlightDisease] = { EffectTypes.ResistBlightDisease, EffectTypes.CureBlightDisease },
}

module.modEffectConflicts = {}

for effect1, effects in pairs(modEffectConflicts) do
    module.modEffectConflicts[effect1] = {}
    for _, effect2 in ipairs(effects) do
        module.modEffectConflicts[effect1][effect2] = true
        module.modEffectConflicts[effect2] = module.modEffectConflicts[effect2] or {}
        module.modEffectConflicts[effect2][effect1] = true
    end
end

module.modRangeTypeConflicts = {
    [EffectTypes.Open] = {
        [RangeTypes.Touch] = true,
        [RangeTypes.Target] = true,
    },
    [EffectTypes.Lock] = {
        [RangeTypes.Touch] = true,
        [RangeTypes.Target] = true,
    },
}

module.armorClasses = { Light = "Light", Medium = "Medium", Heavy = "Heavy" }

local itemRecordFields = { "weight" }

module.itemTypes = {
    [T.Armor] = {
        recordFields = { "baseArmor", "health", table.unpack(itemRecordFields) },
        classes = { module.armorClasses.Light, module.armorClasses.Medium, module.armorClasses.Heavy },
        convertWholeStackTypes = {},
        areGreaterFields = {},
    },
    [T.Clothing] = {
        recordFields = { table.unpack(itemRecordFields) },
        classes = {},
        convertWholeStackTypes = {},
        areGreaterFields = {},
    },
    [T.Weapon] = {
        recordFields = { "chopMaxDamage", "chopMinDamage", "health", "isMagical", "isSilver", "reach", "slashMaxDamage",
                         "slashMinDamage", "speed", "thrustMaxDamage", "thrustMinDamage", table.unpack(itemRecordFields) },
        classes = {},
        convertWholeStackTypes = {
            [T.Weapon.TYPE.MarksmanThrown] = true,
            [T.Weapon.TYPE.Arrow] = true,
            [T.Weapon.TYPE.Bolt] = true,
        },
        areGreaterFields = {
            chopMaxDamage = "chopMinDamage",
            slashMaxDamage = "slashMinDamage",
            thrustMaxDamage = "thrustMinDamage",
        }
    }
}

module.itemRestoreTypes = { All = 0, Equipped = 1, InLoot = 2, Armors = 3, Clothing = 4, Weapons = 5 }

module.effectExclusions = {
    actorsEquippedConstantEffects = {
        [EffectTypes.Levitate] = true,
        [EffectTypes.SlowFall] = true,
        [EffectTypes.Jump] = true,
        [EffectTypes.WaterWalking] = true,
        [EffectTypes.Light] = true,
    },
    passiveActorsEquippedConstantEffects = {
        [EffectTypes.Chameleon] = true,
        [EffectTypes.Invisibility] = true,
        [EffectTypes.Shield] = true,
        [EffectTypes.FireShield] = true,
        [EffectTypes.FrostShield] = true,
        [EffectTypes.LightningShield] = true,
    }
}

module.weaknessEffects = {
    [EffectTypes.WeaknessToFire] = true,
    [EffectTypes.WeaknessToFrost] = true,
    [EffectTypes.WeaknessToShock] = true,
    [EffectTypes.WeaknessToPoison] = true,
    [EffectTypes.WeaknessToMagicka] = true,
    [EffectTypes.WeaknessToCommonDisease] = true,
    [EffectTypes.WeaknessToBlightDisease] = true,
    [EffectTypes.WeaknessToCorprusDisease] = true,
    [EffectTypes.WeaknessToNormalWeapons] = true,
}

module.calmEffects = {
    [EffectTypes.CalmHumanoid] = true,
    [EffectTypes.CalmCreature] = true,
}

module.isAccessed = function(objectData)
    return objectData and objectData.accessed
end

module.isAnalyzed = function(objectData)
    return objectData and objectData.analyzed
end

module.isEquipped = function(objectData)
    return objectData and objectData.equipped
end

module.hasWares = function(objectData)
    return objectData and objectData.hasWares
end

module.setAccessed = function(map, object, factory)
    map[object.id] = map[object.id] or factory(object)
    map[object.id].accessed = true
end

module.setAnalyzed = function(map, object, factory)
    map[object.id] = map[object.id] or factory(object)
    map[object.id].analyzed = true
end

module.setEquipped = function(map, object, factory)
    map[object.id] = map[object.id] or factory(object)
    map[object.id].equipped = true
end

module.new = {
    cache = function()
        return { validItems = {}, itemLists = {}, excluded = module.new.exclusionLists(), modifiers = {}, modifierTypes = { props = {}, effects = {} } }
    end,
    exclusionLists = function()
        return { actorIds = {}, containerIds = {} }
    end,
    requestEvent = function(name, object, data, requestId)
        return { name = name, object = object, data = data, requestId = requestId }
    end,
    playersEvent = function(event, data)
        return { event = event, data = data }
    end,
    message = function(text, quiet)
        return { text = text, quiet = quiet }
    end,
    newContainerData = function(container, toBeAnalyzed)
        return { object = container, toBeAnalyzed = toBeAnalyzed }
    end,
    newContainersData = function(containersData, actors, player)
        return { containersData = containersData, actors = actors, player = player }
    end,
    cellData = function(cell, player)
        return { cell = cell, player = player }
    end,
    actorData = function(object)
        return { object = object, accessed = false, analyzed = false, equipped = false }
    end,
    containerData = function(object)
        return { object = object, accessed = false, analyzed = false, hasWares = false, levelStats = {}, levelStatsOverride = nil, boosts = nil, doorsBoosts = nil }
    end,
    itemData = function(object, oldCount, oldRecordId, lvlModIds)
        return { object = object, oldCount = oldCount, oldRecordId = oldRecordId, lvlModIds = lvlModIds }
    end,
    actorsToRefreshData = function(object, restoreTypes)
        return { object = object, restoreTypes = restoreTypes }
    end,
    averageStat = function(count, sum)
        return { count = count or 0, sum = sum or 0 }
    end,
    wealthStat = function(total, npcCount)
        return { total = total or 0, spent = 0, npcCount = npcCount or 0 }
    end,
    lockableBoosts = function(lock, trap, waterDepth)
        return { lock = lock, trap = trap, waterDepth = waterDepth }
    end,
    containerGlobalStats = function(container, toBeAnalyzed, actors, levelStatsOverride)
        return { container = container, toBeAnalyzed = toBeAnalyzed, actors = actors, levelStatsOverride = levelStatsOverride }
    end,
    containerLocalStats = function(container, levelStats, levelStatsOverride, doorsBoosts)
        return { container = container, levelStats = levelStats, levelStatsOverride = levelStatsOverride, doorsBoosts = doorsBoosts }
    end,
    lootKeeperStats = function(actorLevel, actorRecordId, isCreature, isPassive, distance, time, seeLoot)
        return { actorLevel = actorLevel, actorRecordId = actorRecordId,
                 isCreature = isCreature, isPassive = isPassive,
                 watchedLoots = 0,
                 distance = distance, time = time, seeLoot = seeLoot, still = nil, movesAround = nil }
    end,
    lootKeeperStatsOverride = function(ownerRecordId, factionId, factionRank)
        return { ownerRecordId = ownerRecordId, factionId = factionId, factionRank = factionRank }
    end,
    validItem = function(item, record)
        return { item = item, record = record }
    end,
    lootContext = function(loot, lootRecord, ownerId, ownerWealth, maxWealthValue)
        return {
            loot = loot,
            lootRecord = lootRecord,
            ownerId = ownerId,
            ownerWealth = ownerWealth,
            maxWealthValue = maxWealthValue,
            lootLevel = 1,
            lootLevelChanceBonus = 0,
            boosts = nil,
            chanceBoost = 0,
            item = nil,
        }
    end,
    itemContext = function(record, type)
        return {
            record = record,
            type = type,
            levelReasons = {},
            lvlMods = {},
            tooExpensiveMods = 0,
        }
    end,
    lootLevelStats = function(level, chanceBonus, reasons)
        return { level = level, chanceBonus = chanceBonus, reasons = reasons }
    end,
    lvlModId = function(id, level)
        return { id = id, lvl = level }
    end,
    lvlMod = function(mod, level)
        return { mod = mod, lvl = level }
    end,
    modLayoutData = function(mod)
        return { id = mod.id, affixType = mod.affixType, modifiers = mod.modifiers, multipliers = mod.multipliers, effects = mod.effects }
    end,
    inventoryItem = function(item, slot, valueDiff)
        return { item = item, slot = slot, valueDiff = valueDiff }
    end,
    itemRestoreFilter = function(restoreTypes, onlyLoot, notLootIds)
        return { types = restoreTypes, onlyLoot = onlyLoot, notLootIds = notLootIds }
    end,
    convertedItemEventData = function(item, name, lvlMods)
        return { item = item, name = name, lvlMods = lvlMods }
    end,
    actorStats = function(actor, packageType, wanderDistance)
        return { actor = actor, packageType = packageType, wanderDistance = wanderDistance }
    end,
}

return module