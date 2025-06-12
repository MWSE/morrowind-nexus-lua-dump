local core = require("openmw.core")
local T = require("openmw.types")

local module = {}

module.logLevels = { None = 1, Info = 2, Debug = 3 }

module.affixTypes = { Prefix = "prefix", Suffix = "suffix", Any = "affix" }
module.affixTypes.other = function(affixType)
    return affixType == module.affixTypes.Prefix and module.affixTypes.Suffix or module.affixTypes.Prefix
end
module.affixTypes.pick = function()
    if math.random() < 0.5 then
        return { module.affixTypes.Prefix, module.affixTypes.Suffix }
    else
        return { module.affixTypes.Suffix, module.affixTypes.Prefix }
    end
end

module.castTypesWithCharges = {
    [core.magic.ENCHANTMENT_TYPE.CastOnUse] = true,
    [core.magic.ENCHANTMENT_TYPE.CastOnStrike] = true,
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

module.itemRestoreTypes = { All = 0, Equipped = 1, ForSale = 2, InLoot = 3, Armors = 4, Clothing = 5, Weapons = 6 }

local effectTypes = core.magic.EFFECT_TYPE
module.effectExclusions = {
    actorsEquippedConstantEffects = {
        [effectTypes.Levitate] = true,
        [effectTypes.SlowFall] = true,
        [effectTypes.Jump] = true,
        [effectTypes.WaterWalking] = true,
        [effectTypes.Light] = true,
    },
    passiveActorsEquippedConstantEffects = {
        [effectTypes.Chameleon] = true,
        [effectTypes.Invisibility] = true,
        [effectTypes.Shield] = true,
        [effectTypes.FireShield] = true,
        [effectTypes.FrostShield] = true,
        [effectTypes.LightningShield] = true,
    }
}

module.weaknessEffects = {
    [effectTypes.WeaknessToFire] = true,
    [effectTypes.WeaknessToFrost] = true,
    [effectTypes.WeaknessToShock] = true,
    [effectTypes.WeaknessToPoison] = true,
    [effectTypes.WeaknessToMagicka] = true,
    [effectTypes.WeaknessToCommonDisease] = true,
    [effectTypes.WeaknessToBlightDisease] = true,
    [effectTypes.WeaknessToCorprusDisease] = true,
    [effectTypes.WeaknessToNormalWeapons] = true,
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

module.setAccessed = function(map, object, factory, value)
    map[object.id] = map[object.id] or factory(object)
    map[object.id].accessed = value
end

module.setAnalyzed = function(map, object, factory, value)
    map[object.id] = map[object.id] or factory(object)
    map[object.id].analyzed = value
end

module.setEquipped = function(map, object, factory, value)
    map[object.id] = map[object.id] or factory(object)
    map[object.id].equipped = value
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
    actorData = function(object)
        return { object = object, accessed = false, analyzed = false, equipped = false }
    end,
    containerData = function(object)
        return { object = object, accessed = false, analyzed = false, hasWares = false, levelStats = {}, levelStatsOverride = nil, boosts = nil, doorsBoosts = nil }
    end,
    itemData = function(object, oldCount, oldRecordId, lvlModIds)
        return { object = object, oldCount = oldCount, oldRecordId = oldRecordId, lvlModIds = lvlModIds }
    end,
    averageStat = function(count, sum)
        return { count = count or 0, sum = sum or 0 }
    end,
    wealthStat = function(total, npcCount)
        return { total = total or 0, spent = 0, npcCount = npcCount or 0 }
    end,
    cellStat = function(cell, player)
        return { cell = cell, players = { player } }
    end,
    lockableBoosts = function(lock, trap, waterDepth)
        return { lock = lock, trap = trap, waterDepth = waterDepth }
    end,
    containerCellStats = function(container, actors, levelStatsOverride, checkDoors)
        return { container = container, actors = actors, levelStatsOverride = levelStatsOverride, checkDoors = checkDoors }
    end,
    containerLocalStats = function(container, levelStats, levelStatsOverride, doorsBoosts)
        return { container = container, levelStats = levelStats, levelStatsOverride = levelStatsOverride, doorsBoosts = doorsBoosts }
    end,
    containerLevelStats = function(levelStats, levelStatsOverride)
        return { levelStats = levelStats, levelStatsOverride = levelStatsOverride }
    end,
    lootKeeperStats = function(actorLevel, actorRecordId, isCreature, isPassive, distance, time, seeLoot)
        return { actorLevel = actorLevel, actorRecordId = actorRecordId, isCreature = isCreature, isPassive = isPassive,
                 distance = distance, time = time, seeLoot = seeLoot, still = nil, movesAround = nil }
    end,
    lootKeeperStatsOverride = function(ownerRecordId, hasWares, factionId, factionRank)
        return { ownerRecordId = ownerRecordId, hasWares = hasWares, factionId = factionId, factionRank = factionRank }
    end,
    validItem = function(item, record)
        return { item = item, record = record }
    end,
    lootContext = function(loot, lootRecord, equipmentOnly, ownerId, ownerWealth)
        return {
            loot = loot,
            lootRecord = lootRecord,
            equipmentOnly = equipmentOnly,
            ownerId = ownerId,
            ownerWealth = ownerWealth,
            lootLevel = 1,
            crowdChanceBoost = 0,
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
    itemRestoreFilter = function(restoreTypes, onlyCells, notCells, onlyLootId)
        return { types = restoreTypes, onlyCells = onlyCells, notCells = notCells, onlyLootId = onlyLootId }
    end,
    convertedItemEventData = function(item, name, lvlMods)
        return { item = item, name = name, lvlMods = lvlMods }
    end,
    actorStats = function(actor, packageType, wanderDistance)
        return { actor = actor, packageType = packageType, wanderDistance = wanderDistance }
    end,
}

return module