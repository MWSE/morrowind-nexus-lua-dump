local core = require("openmw.core")
local async = require("openmw.async")
local I = require("openmw.interfaces")

local mDef = require("scripts.fresh-loot.config.definition")
local mStore = require("scripts.fresh-loot.settings.store")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local module = {}

local settingChanges = {}

local function updateSettingDependencies(state)
    local changed = false
    for key, setting in pairs(mStore.cfg) do
        local argument = setting.argument
        local disabled

        if setting.requires then
            if not state.settings[setting.requires] then
                disabled = true
                state.settings[key] = false
            elseif argument.disabled then
                disabled = false
                state.settings[key] = setting.get()
            end
        end

        if setting.lockIf then
            argument.locked = false
            if state.settings[setting.lockIf.key] == setting.lockIf.value then
                disabled = true
                argument.locked = true
            elseif argument.disabled and not disabled then
                disabled = false
            end
        end

        if disabled ~= nil and argument.disabled ~= disabled then
            argument.disabled = disabled
            I.Settings.updateRendererArgument(setting.section.key, key, argument)
            changed = true
        end
    end
    return changed
end

local function updateAllSettingsDependencies(state)
    for _ = 1, 10 do
        if not updateSettingDependencies(state) then return end
    end
    error("Failed to update the settings dependencies.")
end

local function applyPresets(state)
    for presetKey, presetValue in pairs(mStore.presets[state.settings[mStore.cfg.chancePresets.key]]) do
        mStore.cfg[presetKey].set(presetValue)
    end
end

local function trackSettingChanges(state, key)
    local newValue = mStore.cfg[key].get()
    if not settingChanges[key] then
        settingChanges[key] = { old = state.settings[key] }
    end
    state.settings[key] = newValue
    updateAllSettingsDependencies(state)
    settingChanges[key].new = state.settings[key]

    if key == mStore.cfg.itemLists.key then
        if #state.cache.itemLists > 0 and newValue == "" then
            -- event because otherwise OpenMW complains about possible infinite recursion on settings changes
            core.sendGlobalEvent(mDef.events.setItemListsSetting)
        end
    elseif (key == mStore.cfg.enableChancePresets.key and newValue) or (key == mStore.cfg.chancePresets.key and state.settings[mStore.cfg.enableChancePresets.key]) then
        applyPresets(state)
    end
end

module.checkSettings = function()
    local restoreTypes = {}
    for key, values in pairs(settingChanges) do
        if values.old ~= values.new and mStore.cfg[key].triggerRestoreTypes then
            mHelpers.addAllToHashset(restoreTypes, mStore.cfg[key].triggerRestoreTypes)
        end
    end
    settingChanges = {}
    if next(restoreTypes) then
        return restoreTypes
    end
end

module.loadSettings = function(state)
    for _, setting in pairs(mStore.cfg) do
        state.settings[setting.key] = setting.get()
    end
    if state.settings[mStore.cfg.enableChancePresets.key] then
        applyPresets(state)
    end
    updateAllSettingsDependencies(state)

    if type(state.settings[mStore.cfg.itemsWindowKey.key]) == "number" then
        mStore.cfg.itemsWindowKey.set("")
    end
end

module.setItemListsSetting = function(state)
    mStore.cfg.itemLists.set(table.concat(state.cache.itemLists, "\n"))
end

module.trackSettings = function(state)
    for _, section in pairs(mStore.section) do
        section.get():subscribe(async:callback(function(_, key) trackSettingChanges(state, key) end))
    end
end

return module