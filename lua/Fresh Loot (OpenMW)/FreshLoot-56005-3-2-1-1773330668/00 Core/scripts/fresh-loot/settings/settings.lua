local core = require("openmw.core")
local I = require("openmw.interfaces")

local mDef = require("scripts.fresh-loot.config.definition")
local mT = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local module = {}

local settings = mStore.settings

local presets = {
    [mT.chancePresets.VeryRare] = {
        [settings.firstModifierChance.key] = 1,
        [settings.secondModifierChance.key] = 10,
        [settings.maxLootLevelChanceBoost.key] = 30,
        [settings.maxLockChanceBoost.key] = 30,
        [settings.maxTrapChanceBoost.key] = 15,
        [settings.maxWaterDepthChanceBoost.key] = 15,
        [settings.nextConversionInSameLootChance.key] = 20,
        [settings.equippedWeaponMinChance.key] = 5,
        [settings.secondModifierChanceBoostReduction.key] = 35,
        [settings.maxModsValueOverNpcWealth.key] = 25,
    },
    [mT.chancePresets.Rare] = {
        [settings.firstModifierChance.key] = 3,
        [settings.secondModifierChance.key] = 20,
        [settings.maxLootLevelChanceBoost.key] = 40,
        [settings.maxLockChanceBoost.key] = 50,
        [settings.maxTrapChanceBoost.key] = 25,
        [settings.maxWaterDepthChanceBoost.key] = 25,
        [settings.nextConversionInSameLootChance.key] = 35,
        [settings.equippedWeaponMinChance.key] = 10,
        [settings.secondModifierChanceBoostReduction.key] = 50,
        [settings.maxModsValueOverNpcWealth.key] = 25,
    },
    [mT.chancePresets.Common] = {
        [settings.firstModifierChance.key] = 5,
        [settings.secondModifierChance.key] = 30,
        [settings.maxLootLevelChanceBoost.key] = 50,
        [settings.maxLockChanceBoost.key] = 50,
        [settings.maxTrapChanceBoost.key] = 50,
        [settings.maxWaterDepthChanceBoost.key] = 50,
        [settings.nextConversionInSameLootChance.key] = 50,
        [settings.equippedWeaponMinChance.key] = 15,
        [settings.secondModifierChanceBoostReduction.key] = 65,
        [settings.maxModsValueOverNpcWealth.key] = 50,
    },
    [mT.chancePresets.VeryCommon] = {
        [settings.firstModifierChance.key] = 10,
        [settings.secondModifierChance.key] = 40,
        [settings.maxLootLevelChanceBoost.key] = 60,
        [settings.maxLockChanceBoost.key] = 50,
        [settings.maxTrapChanceBoost.key] = 50,
        [settings.maxWaterDepthChanceBoost.key] = 50,
        [settings.nextConversionInSameLootChance.key] = 75,
        [settings.equippedWeaponMinChance.key] = 20,
        [settings.secondModifierChanceBoostReduction.key] = 80,
        [settings.maxModsValueOverNpcWealth.key] = 0,
    },
    [mT.chancePresets.Maximum] = {
        [settings.firstModifierChance.key] = 100,
        [settings.secondModifierChance.key] = 50,
        [settings.maxLootLevelChanceBoost.key] = 60,
        [settings.maxLockChanceBoost.key] = 50,
        [settings.maxTrapChanceBoost.key] = 50,
        [settings.maxWaterDepthChanceBoost.key] = 50,
        [settings.nextConversionInSameLootChance.key] = 100,
        [settings.equippedWeaponMinChance.key] = 20,
        [settings.secondModifierChanceBoostReduction.key] = 80,
        [settings.maxModsValueOverNpcWealth.key] = 0,
    },
}

local settingChanges = {}

local function applyPresets()
    for presetKey, presetValue in pairs(presets[settings.chancePresets.get()]) do
        settings[presetKey].set(presetValue)
    end
end

module.setItemListsSetting = function(state)
    settings.itemLists.set(table.concat(state.cache.itemLists, "\n"))
end

local function updateSettingDependencies()
    local changed = false
    for key, setting in pairs(settings) do
        local argument = setting.argument
        local disabled

        if setting.requires then
            if not settings[setting.requires].get() then
                disabled = true
            elseif argument.disabled then
                disabled = false
            end
        end

        if setting.lockIf then
            argument.locked = false
            if settings[setting.lockIf.key].get() == setting.lockIf.value then
                disabled = true
                argument.locked = true
            elseif argument.disabled and not disabled then
                disabled = false
            end
        end

        if disabled ~= nil and argument.disabled ~= disabled then
            argument.disabled = disabled
            if I.Activation then
                -- only from a global script
                I.Settings.updateRendererArgument(setting.section.key, key, argument)
            end
            changed = true
        end
    end
    return changed
end

module.updateAllSettingsDependencies = function()
    for _ = 1, 10 do
        if not updateSettingDependencies() then return end
    end
    error("Failed to update the settings dependencies.")
end

module.trackSettingChanges = function(state, key, oldValue)
    local newValue = settings[key].get()
    if newValue == nil then
        local preset = presets[settings.chancePresets.get()][key]
        if preset ~= nil then
            core.sendGlobalEvent(mDef.events.setSetting, { key = key, value = preset })
            return
        end
    end
    if newValue == oldValue then
        return
    end
    if not settingChanges[key] then
        settingChanges[key] = { old = oldValue }
    end
    settingChanges[key].new = newValue
    module.updateAllSettingsDependencies()

    if key == settings.itemLists.key then
        if #state.cache.itemLists > 0 and newValue == "" then
            -- event because otherwise OpenMW complains about possible infinite recursion on settings changes
            core.sendGlobalEvent(mDef.events.setItemListsSetting)
        end
    elseif (newValue and key == settings.enableChancePresets.key) or (key == settings.chancePresets.key and settings.enableChancePresets.get()) then
        applyPresets()
    end
end

module.checkSettings = function()
    local restoreTypes = {}
    for key, values in pairs(settingChanges) do
        if values.old ~= values.new and settings[key].triggerRestoreTypes then
            mHelpers.addAllToHashset(restoreTypes, settings[key].triggerRestoreTypes)
        end
    end
    settingChanges = {}
    if next(restoreTypes) then
        return restoreTypes
    end
end

module.initSettings = function()
    if settings.enableChancePresets.get() then
        applyPresets()
    end
    module.updateAllSettingsDependencies()

    if type(settings.itemsWindowKeyController.get()) == "number" then
        settings.itemsWindowKey.set("")
    end
end

return module