local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require('openmw.async')

local mDef = require("scripts.fresh-loot.config.definition")
local mCfg = require("scripts.fresh-loot.config.configuration")
local mT = require("scripts.fresh-loot.config.types")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local trackerCallbacks = {}

local module = {
    sections = {
        global = { name = "Global", order = 0 },
        chance = { name = "Chance", order = 1 },
        level = { name = "Level", order = 2 },
        misc = { name = "Misc", order = 3 },
    },
}

local sections = module.sections

module.settings = {
    -- GLOBAL
    enabled = {
        order = 0,
        section = sections.global,
        renderer = "checkbox",
        argument = { disabled = not mDef.isLuaApiRecentEnough },
        default = true,
        triggerRestoreTypes = { mT.itemRestoreTypes.All, mT.itemRestoreTypes.Equipped },
    },
    chancePresets = {
        order = 1,
        section = sections.global,
        renderer = "select",
        default = mT.chancePresets.Rare,
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
        enum = mT.chancePresets,
    },
    enableChancePresets = {
        order = 2,
        section = sections.global,
        renderer = "checkbox",
        default = true,
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    doUnlevelledItems = {
        order = 3,
        section = sections.global,
        renderer = "checkbox",
        default = true,
    },
    doEquippedItems = {
        order = 4,
        section = sections.global,
        renderer = "checkbox",
        default = true,
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    doArmors = {
        order = 5,
        section = sections.global,
        renderer = "checkbox",
        default = true,
        triggerRestoreTypes = { mT.itemRestoreTypes.Armors, mT.itemRestoreTypes.Equipped },
    },
    doClothing = {
        order = 6,
        section = sections.global,
        renderer = "checkbox",
        default = true,
        triggerRestoreTypes = { mT.itemRestoreTypes.Clothing, mT.itemRestoreTypes.Equipped },
    },
    doWeapons = {
        order = 7,
        section = sections.global,
        renderer = "checkbox",
        default = true,
        triggerRestoreTypes = { mT.itemRestoreTypes.Weapons, mT.itemRestoreTypes.Equipped },
    },
    endGameLootLevel = {
        order = 8,
        section = sections.global,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 1, max = 999 },
        default = mCfg.lootLevel.endGameLootLevel,
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    itemsWindowKeyKeyboard = {
        order = 9,
        section = sections.global,
        renderer = mDef.renderers.hotkeyKeyboard,
        default = nil,
    },
    itemsWindowKeyController = {
        order = 10,
        section = sections.global,
        renderer = "inputBinding",
        argument = { key = mDef.actions.showItems, type = "action" },
        default = mDef.inputKeys.defaultItemsKey,
    },
    itemLists = {
        order = 11,
        section = sections.global,
        renderer = mDef.renderers.multilines,
        default = "",
    },
    logMode = {
        order = 12,
        section = sections.global,
        renderer = "select",
        enum = mT.logLevels,
        default = mT.logLevels.None,
    },
    -- CHANCE
    firstModifierChance = {
        order = 0,
        section = sections.chance,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    secondModifierChance = {
        order = 1,
        section = sections.chance,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    propsModifiersChance = {
        order = 2,
        section = sections.chance,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        default = mCfg.modifierChance.props,
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    maxLootLevelChanceBoost = {
        order = 3,
        section = sections.chance,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    maxLockChanceBoost = {
        order = 4,
        section = sections.chance,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
    },
    maxTrapChanceBoost = {
        order = 5,
        section = sections.chance,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
    },
    maxWaterDepthChanceBoost = {
        order = 6,
        section = sections.chance,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
    },
    nextConversionInSameLootChance = {
        order = 7,
        section = sections.chance,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    equippedWeaponMinChance = {
        order = 8,
        section = sections.chance,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    secondModifierChanceBoostReduction = {
        order = 9,
        section = sections.chance,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    -- LEVEL
    passiveActorsLevelRatio = {
        order = 0,
        section = sections.level,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        default = mCfg.lootLevel.passiveActorsLevelRatio,
    },
    playerLevelScaling = {
        order = 1,
        section = sections.level,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        default = mCfg.modifierLevel.playerLevelScaling,
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    maxLockLevelBoost = {
        order = 2,
        section = sections.level,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100 },
        default = mCfg.lootLevel.maxLockBoost,
    },
    maxTrapLevelBoost = {
        order = 3,
        section = sections.level,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100 },
        default = mCfg.lootLevel.maxTrapBoost,
    },
    maxWaterDepthLevelBoost = {
        order = 4,
        section = sections.level,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100 },
        default = mCfg.lootLevel.maxWaterDepthBoost,
    },
    -- MISC
    maxModsValueOverNpcWealth = {
        order = 0,
        section = sections.misc,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 9999, isPercent = true },
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    projectileStackReduction = {
        order = 1,
        section = sections.misc,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        default = mCfg.itemConversion.projectileStackReduction,
        triggerRestoreTypes = { mT.itemRestoreTypes.Equipped },
    },
    maxItemWindowRowsPerPage = {
        order = 2,
        section = sections.misc,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 1, max = 100 },
        default = mCfg.itemWindow.maxRowsPerPage,
    }
}

local settings = module.settings

module.registerGroups = function()
    for _, section in pairs(sections) do
        section.page = mDef.MOD_NAME
        section.l10n = mDef.MOD_NAME
        local name = section.name
        section.name = name .. "SectionTitle"
        section.description = mDef.getMessageKeyIfOpenMWTooOld(name .. "SectionDesc")
        section.permanentStorage = false
        section.settings = {}
        if mDef.isLuaApiRecentEnough then
            for _, setting in mHelpers.spairs(settings,
                    function(t, a, b) return t[a].order < t[b].order end,
                    function(item) return item.section == section end) do
                setting.name = setting.key .. "_name"
                setting.description = setting.key .. "_desc"
                table.insert(section.settings, setting)
            end
        end
        I.Settings.registerGroup(section)
    end
end

module.addTrackerCallback = function(callback)
    table.insert(trackerCallbacks, callback)
end

local function serializeValue(setting, value)
    return setting.enum and setting.keys[value] or value
end

local function deserializeValue(setting, value)
    return setting.enum and setting.values[value] or value
end

for _, section in pairs(sections) do
    section.key = "Settings" .. section.name .. mDef.MOD_NAME
    section.get = function()
        return storage.globalSection(section.key)
    end
end

for key, setting in pairs(settings) do
    setting.key = key
    setting.get = function()
        -- disabled settings shall return either false or the default value, except for those locked by a preset
        if setting.argument.disabled and not setting.argument.locked then
            if type(setting.value) == "boolean" then
                return false
            else
                return deserializeValue(setting, setting.default)
            end
        end
        return setting.value
    end
    setting.set = function(value)
        return setting.section.get():set(key, serializeValue(setting, value))
    end
    if setting.enum then
        local items = {}
        setting.keys = {}
        setting.values = {}
        for vKey, value in mHelpers.spairs(setting.enum, function(t, a, b) return t[a] < t[b] end) do
            local itemKey = key .. vKey
            table.insert(items, itemKey)
            setting.keys[value] = itemKey
            setting.values[itemKey] = value
        end
        setting.default = setting.keys[setting.default]
        setting.argument = { l10n = mDef.MOD_NAME, items = items }
    else
        setting.argument = setting.argument or {}
    end
    setting.argument.disabled = setting.argument.disabled or false
    setting.value = deserializeValue(setting, setting.default)
end

for key, cfg in pairs(settings) do
    if key ~= settings.enabled.key then
        cfg.requires = settings.enabled.key
    end
end

settings.equippedWeaponMinChance.requires = settings.doEquippedItems.key
settings.chancePresets.requires = settings.enableChancePresets.key

settings.firstModifierChance.lockIf = { key = settings.enableChancePresets.key, value = true }
settings.secondModifierChance.lockIf = { key = settings.enableChancePresets.key, value = true }
settings.maxLootLevelChanceBoost.lockIf = { key = settings.enableChancePresets.key, value = true }
settings.maxLockChanceBoost.lockIf = { key = settings.enableChancePresets.key, value = true }
settings.maxTrapChanceBoost.lockIf = { key = settings.enableChancePresets.key, value = true }
settings.maxWaterDepthChanceBoost.lockIf = { key = settings.enableChancePresets.key, value = true }
settings.nextConversionInSameLootChance.lockIf = { key = settings.enableChancePresets.key, value = true }
settings.equippedWeaponMinChance.lockIf = { key = settings.enableChancePresets.key, value = true }
settings.secondModifierChanceBoostReduction.lockIf = { key = settings.enableChancePresets.key, value = true }
settings.maxModsValueOverNpcWealth.lockIf = { key = settings.enableChancePresets.key, value = true }

-- Don't read the store when building enchantments with the Lua CLI
if I.dummy then return module end

for _, section in pairs(sections) do
    for key, value in pairs(section.get():asTable()) do
        local setting = settings[key]
        if not setting then
            -- key used in an older mod version: Remove the entry
            if I.Activation then
                -- only set the setting from a global script
                section.get():set(key, nil)
            end
        else
            if value == nil
                    or setting.default and type(value) ~= type(setting.default)
                    or setting.enum and not setting.values[value] then
                -- broken storage: Restore the default value
                value = setting.default
                if I.Activation then
                    -- only set the setting from a global script
                    section.get():set(key, value)
                end
            end

            setting.value = deserializeValue(setting, value)
        end
    end
end

for _, section in pairs(sections) do
    section.get():subscribe(async:callback(function(_, key)
        local setting = settings[key]
        if not setting then return end
        local oldValue = setting.value
        setting.value = deserializeValue(setting, section.get():getCopy(key))
        for _, callback in ipairs(trackerCallbacks) do
            callback(key, oldValue)
        end
    end))
end

return module