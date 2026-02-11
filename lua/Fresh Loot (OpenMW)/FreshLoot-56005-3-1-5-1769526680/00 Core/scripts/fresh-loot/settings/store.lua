local storage = require("openmw.storage")

local mDef = require("scripts.fresh-loot.config.definition")
local mT = require("scripts.fresh-loot.config.types")
local mHelpers = require("scripts.fresh-loot.util.helpers")

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
    enabled = {
        section = module.section.global,
        argument = { disabled = not mDef.isLuaApiRecentEnough },
        triggerRestoreTypes = { mT.itemRestoreTypes.All, mT.itemRestoreTypes.Equipped },
    },
    chancePresets = {
        section = module.section.global,
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
        enum = mT.chancePresets,
    },
    enableChancePresets = {
        section = module.section.global,
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    doUnlevelledItems = {
        section = module.section.global,
    },
    doEquippedItems = {
        section = module.section.global,
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    doArmors = {
        section = module.section.global,
        triggerRestoreTypes = { mT.itemRestoreTypes.Armors, mT.itemRestoreTypes.Equipped },
    },
    doClothing = {
        section = module.section.global,
        triggerRestoreTypes = { mT.itemRestoreTypes.Clothing, mT.itemRestoreTypes.Equipped },
    },
    doWeapons = {
        section = module.section.global,
        triggerRestoreTypes = { mT.itemRestoreTypes.Weapons, mT.itemRestoreTypes.Equipped },
    },
    endGameLootLevel = {
        section = module.section.global,
        argument = { integer = true, min = 1, max = 999 },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    itemsWindowKeyKeyboard = {
        section = module.section.global,
    },
    itemsWindowKeyController = {
        section = module.section.global,
        argument = { key = mDef.actions.showItems, type = "action" },
    },
    itemLists = {
        section = module.section.global,
    },
    logMode = {
        section = module.section.global,
        enum = mT.logLevels,
    },
    -- CHANCE
    firstModifierChance = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    secondModifierChance = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    propsModifiersChance = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    maxLootLevelChanceBoost = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    maxLockChanceBoost = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
    },
    maxTrapChanceBoost = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
    },
    maxWaterDepthChanceBoost = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
    },
    nextConversionInSameLootChance = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    equippedWeaponMinChance = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    secondModifierChanceBoostReduction = {
        section = module.section.chance,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    -- LEVEL
    passiveActorsLevelRatio = {
        section = module.section.level,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
    },
    playerLevelScaling = {
        section = module.section.level,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
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
    maxModsValueOverNpcWealth = {
        section = module.section.misc,
        argument = { integer = true, min = 0, max = 9999, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    projectileStackReduction = {
        section = module.section.misc,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
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
        for vKey, value in mHelpers.spairs(cfg.enum, function(t, a, b) return t[a] < t[b] end) do
            local itemKey = key .. vKey
            table.insert(items, itemKey)
            cfg.keys[value] = itemKey
            cfg.values[itemKey] = value
        end
        cfg.argument = { l10n = mDef.MOD_NAME, items = items }
    else
        cfg.argument = cfg.argument or {}
    end
    cfg.argument.disabled = cfg.argument.disabled or false
end

for key, cfg in pairs(module.cfg) do
    if key ~= module.cfg.enabled.key then
        cfg.requires = module.cfg.enabled.key
    end
end

module.cfg.equippedWeaponMinChance.requires = module.cfg.doEquippedItems.key
module.cfg.chancePresets.requires = module.cfg.enableChancePresets.key

module.cfg.firstModifierChance.lockIf = { key = module.cfg.enableChancePresets.key, value = true }
module.cfg.secondModifierChance.lockIf = { key = module.cfg.enableChancePresets.key, value = true }
module.cfg.maxLootLevelChanceBoost.lockIf = { key = module.cfg.enableChancePresets.key, value = true }
module.cfg.maxLockChanceBoost.lockIf = { key = module.cfg.enableChancePresets.key, value = true }
module.cfg.maxTrapChanceBoost.lockIf = { key = module.cfg.enableChancePresets.key, value = true }
module.cfg.maxWaterDepthChanceBoost.lockIf = { key = module.cfg.enableChancePresets.key, value = true }
module.cfg.nextConversionInSameLootChance.lockIf = { key = module.cfg.enableChancePresets.key, value = true }
module.cfg.equippedWeaponMinChance.lockIf = { key = module.cfg.enableChancePresets.key, value = true }
module.cfg.secondModifierChanceBoostReduction.lockIf = { key = module.cfg.enableChancePresets.key, value = true }
module.cfg.maxModsValueOverNpcWealth.lockIf = { key = module.cfg.enableChancePresets.key, value = true }

module.presets = {
    [mT.chancePresets.VeryRare] = {
        [module.cfg.firstModifierChance.key] = 1,
        [module.cfg.secondModifierChance.key] = 10,
        [module.cfg.maxLootLevelChanceBoost.key] = 30,
        [module.cfg.maxLockChanceBoost.key] = 30,
        [module.cfg.maxTrapChanceBoost.key] = 15,
        [module.cfg.maxWaterDepthChanceBoost.key] = 15,
        [module.cfg.nextConversionInSameLootChance.key] = 20,
        [module.cfg.equippedWeaponMinChance.key] = 5,
        [module.cfg.secondModifierChanceBoostReduction.key] = 35,
        [module.cfg.maxModsValueOverNpcWealth.key] = 25,
    },
    [mT.chancePresets.Rare] = {
        [module.cfg.firstModifierChance.key] = 3,
        [module.cfg.secondModifierChance.key] = 20,
        [module.cfg.maxLootLevelChanceBoost.key] = 40,
        [module.cfg.maxLockChanceBoost.key] = 50,
        [module.cfg.maxTrapChanceBoost.key] = 25,
        [module.cfg.maxWaterDepthChanceBoost.key] = 25,
        [module.cfg.nextConversionInSameLootChance.key] = 35,
        [module.cfg.equippedWeaponMinChance.key] = 10,
        [module.cfg.secondModifierChanceBoostReduction.key] = 50,
        [module.cfg.maxModsValueOverNpcWealth.key] = 25,
    },
    [mT.chancePresets.Common] = {
        [module.cfg.firstModifierChance.key] = 5,
        [module.cfg.secondModifierChance.key] = 30,
        [module.cfg.maxLootLevelChanceBoost.key] = 50,
        [module.cfg.maxLockChanceBoost.key] = 50,
        [module.cfg.maxTrapChanceBoost.key] = 50,
        [module.cfg.maxWaterDepthChanceBoost.key] = 50,
        [module.cfg.nextConversionInSameLootChance.key] = 50,
        [module.cfg.equippedWeaponMinChance.key] = 15,
        [module.cfg.secondModifierChanceBoostReduction.key] = 65,
        [module.cfg.maxModsValueOverNpcWealth.key] = 50,
    },
    [mT.chancePresets.VeryCommon] = {
        [module.cfg.firstModifierChance.key] = 10,
        [module.cfg.secondModifierChance.key] = 40,
        [module.cfg.maxLootLevelChanceBoost.key] = 60,
        [module.cfg.maxLockChanceBoost.key] = 50,
        [module.cfg.maxTrapChanceBoost.key] = 50,
        [module.cfg.maxWaterDepthChanceBoost.key] = 50,
        [module.cfg.nextConversionInSameLootChance.key] = 75,
        [module.cfg.equippedWeaponMinChance.key] = 20,
        [module.cfg.secondModifierChanceBoostReduction.key] = 80,
        [module.cfg.maxModsValueOverNpcWealth.key] = 0,
    },
    [mT.chancePresets.Maximum] = {
        [module.cfg.firstModifierChance.key] = 100,
        [module.cfg.secondModifierChance.key] = 50,
        [module.cfg.maxLootLevelChanceBoost.key] = 60,
        [module.cfg.maxLockChanceBoost.key] = 50,
        [module.cfg.maxTrapChanceBoost.key] = 50,
        [module.cfg.maxWaterDepthChanceBoost.key] = 50,
        [module.cfg.nextConversionInSameLootChance.key] = 100,
        [module.cfg.equippedWeaponMinChance.key] = 20,
        [module.cfg.secondModifierChanceBoostReduction.key] = 80,
        [module.cfg.maxModsValueOverNpcWealth.key] = 0,
    },
}

return module