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

module.new = {
    exclusionLists = function()
        return { actorIds = {}, containerIds = {} }
    end,
    requestEvent = function(name, object, input, output)
        return { name = name, object = object, input = input, output = output }
    end,
    cache = function()
        return { modifiers = {}, validItemIds = {}, modifierTypes = { props = {}, effects = {} } }
    end,
    playersEvent = function(event, data)
        return { event = event, data = data }
    end,
    message = function(text, quiet)
        return { text = text, quiet = quiet }
    end,
    averageStat = function()
        return { count = 0, sum = 0 }
    end,
    wealthStat = function()
        return { total = 0, spent = 0 }
    end,
    cellStat = function(cell, playerCount)
        return { cell = cell, playerCount = playerCount }
    end,
    lootBoosts = function(lock, trap, waterDepth)
        return { lock = lock, trap = trap, waterDepth = waterDepth }
    end,
    containerStats = function(container, actors, levelStatsOverride)
        return { container = container, actors = actors, levelStatsOverride = levelStatsOverride, levelStats = {} }
    end,
    containerLevelSource = function(ownerRecordId, isForSale, factionId, factionRank)
        return { ownerRecordId = ownerRecordId, isForSale = isForSale, factionId = factionId, factionRank = factionRank }
    end,
    lootKeeperStats = function(actorLevel, source, actorRecordId, isCreature, isPassive, distance, time, seeLoot)
        return { actorLevel = actorLevel, source = source, actorRecordId = actorRecordId, isCreature = isCreature, isPassive = isPassive,
                 distance = distance, time = time, seeLoot = seeLoot, still = nil, movesAround = nil }
    end,
    itemData = function(item, record)
        return { item = item, record = record }
    end,
    lootContext = function(loot, lootRecord, equipmentOnly, ownerId)
        return {
            loot = loot,
            lootRecord = lootRecord,
            equipmentOnly = equipmentOnly,
            ownerId = ownerId,
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
    convertedItem = function(item, oldCount, oldRecordId, lvlModIds)
        return { item = item, oldCount = oldCount, oldRecordId = oldRecordId, lvlModIds = lvlModIds }
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
    actorStatsRequest = function(id, count, requestEvent)
        return { stats = nil, requestId = id, requestCount = count, requestEvent = requestEvent }
    end,
    actorsStatsResponse = function(actorsStats, eventData)
        return { actorsStats = actorsStats, eventData = eventData }
    end,
}

return module