local storage = require("openmw.storage")

local mDef = require("scripts.fresh-loot.config.definition")
local mTypes = require("scripts.fresh-loot.config.types")

local module = {}

module.section = {
    global = { name = "Global" },
    chance = { name = "Chance" },
    level = { name = "Level" },
    misc = { name = "Misc" },
}

for _, section in pairs(module.section) do
    section.key = "Settings" .. section.name .. mDef.MOD_NAME
    section.get = function(key)
        local group = storage.globalSection(section.key)
        if key then
            return group:get(key)
        else
            return group
        end
    end
    section.set = function(key, value)
        storage.globalSection(section.key):set(key, value)
    end
end

module.cfg = {
    -- GLOBAL
    itemLists = {
        section = module.section.global,
    },
    enabled = {
        section = module.section.global,
        argument = { disabled = not mDef.isLuaApiRecentEnough },
        triggerRestoreTypes = { mTypes.itemRestoreTypes.All, mTypes.itemRestoreTypes.Equipped, mTypes.itemRestoreTypes.ForSale },
    },
    doUnlevelledItems = {
        section = module.section.global,
    },
    doEquippedItems = {
        section = module.section.global,
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Equipped },
    },
    doArmors = {
        section = module.section.global,
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Armors, mTypes.itemRestoreTypes.Equipped, mTypes.itemRestoreTypes.ForSale },
    },
    doClothing = {
        section = module.section.global,
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Clothing, mTypes.itemRestoreTypes.Equipped, mTypes.itemRestoreTypes.ForSale },
    },
    doWeapons = {
        section = module.section.global,
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Weapons, mTypes.itemRestoreTypes.Equipped, mTypes.itemRestoreTypes.ForSale },
    },
    endGameLootLevel = {
        section = module.section.global,
        argument = { integer = true, min = 1, max = 999 },
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Equipped },
    },
    itemsWindowKey = {
        section = module.section.global,
    },
    logMode = {
        section = module.section.global,
        enum = mTypes.logLevels,
    },
    -- CHANCE
    firstModifierChance = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100 },
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Equipped, mTypes.itemRestoreTypes.ForSale },
    },
    secondModifierChance = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100 },
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Equipped, mTypes.itemRestoreTypes.ForSale },
    },
    propsModifiersChance = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100 },
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Equipped, mTypes.itemRestoreTypes.ForSale },
    },
    enableCrowdChanceBoost = {
        section = module.section.chance,
    },
    equippedWeaponSecondChanceBoost = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100 },
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Equipped },
    },
    maxLootLevelChanceBoost = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100 },
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Equipped },
    },
    maxLockChanceBoost = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100 },
    },
    maxTrapChanceBoost = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100 },
    },
    maxWaterDepthChanceBoost = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100 },
    },
    secondModifierChanceBoostReduction = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100 },
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Equipped },
    },
    -- LEVEL
    passiveActorsLevelRatio = {
        section = module.section.level,
        argument = { integer = true, min = 0, max = 100 },
    },
    playerLevelScaling = {
        section = module.section.level,
        argument = { integer = true, min = 0, max = 100 },
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Equipped },
    },
    maxLockLevelBoost = {
        section = module.section.level,
        argument = { integer = true, min = 0, max = 100 },
    },
    maxTrapLevelBoost = {
        section = module.section.level,
        argument = { integer = true, min = 0, max = 100 },
    },
    maxWaterDepthLevelBoost = {
        section = module.section.level,
        argument = { integer = true, min = 0, max = 100 },
    },
    -- MISC
    convertMerchantItems = {
        section = module.section.misc,
        triggerRestoreTypes = { mTypes.itemRestoreTypes.ForSale },
    },
    maxModsValueOverNpcWealth = {
        section = module.section.misc,
        argument = { integer = true, min = 0, max = 9999 },
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Equipped, mTypes.itemRestoreTypes.ForSale },
    },
    maxModsValueOverCreatureWealth = {
        section = module.section.misc,
        argument = { integer = true, min = 0, max = 9999 },
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Equipped, mTypes.itemRestoreTypes.ForSale },
    },
    projectileStackReduction = {
        section = module.section.misc,
        argument = { integer = true, min = 0, max = 100 },
        triggerRestoreTypes = { mTypes.itemRestoreTypes.Equipped, mTypes.itemRestoreTypes.ForSale },
    },
    maxItemWindowRowsPerPage = {
        section = module.section.misc,
        argument = { integer = true, min = 1, max = 100 },
    }
}

for key, cfg in pairs(module.cfg) do
    cfg.key = key
    cfg.get = function()
        if cfg.enum then return cfg.values[cfg.section.get(key)] end
        return cfg.section.get(key)
    end
    cfg.set = function(value)
        if cfg.enum then return cfg.section.set(key, cfg.keys[value]) end
        return cfg.section.set(key, value)
    end
    if cfg.enum then
        local items = {}
        cfg.keys = {}
        cfg.values = {}
        for vKey, value in pairs(cfg.enum) do
            local itemKey = key .. vKey
            table.insert(items, itemKey)
            cfg.keys[value] = itemKey
            cfg.values[itemKey] = value
        end
        cfg.argument = { l10n = mDef.MOD_NAME, items = items }
    else
        cfg.argument = cfg.argument or { disabled = false }
    end
end

for key, cfg in pairs(module.cfg) do
    if key ~= module.cfg.enabled.key then
        cfg.requires = module.cfg.enabled.key
    end
end

module.cfg.equippedWeaponSecondChanceBoost.requires = module.cfg.doEquippedItems.key

return module