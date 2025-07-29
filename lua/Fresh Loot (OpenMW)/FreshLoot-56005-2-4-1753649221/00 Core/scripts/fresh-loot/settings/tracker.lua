local core = require("openmw.core")
local async = require("openmw.async")
local I = require("openmw.interfaces")

local mDef = require("scripts.fresh-loot.config.definition")
local mStore = require("scripts.fresh-loot.settings.store")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local module = {}

local settingChanges = {}

local function updateSettingRequirement(state)
    for key, setting in pairs(mStore.cfg) do
        local argument = setting.argument
        if setting.requires and argument.disabled ~= not state.settings[setting.requires] then
            argument.disabled = not state.settings[setting.requires]
            if argument.disabled then
                state.settings[key] = false
            else
                state.settings[key] = setting.get()
            end
            I.Settings.updateRendererArgument(setting.section.key, key, argument)
            return true
        end
    end
    return false
end

local function updateSettingsRequirements(state)
    -- for loop because an empty "while" produces an IDE warning...
    for _ = 1, 100 do
        if not updateSettingRequirement(state) then return end
    end
end

local function trackSettingChanges(state, key)
    if key == mStore.cfg.itemLists.key then
        -- event because otherwise OpenMW complains about possible infinite recursion on settings changes
        if #state.cache.itemLists > 0 and mStore.cfg.itemLists.get() == "" then
            core.sendGlobalEvent(mDef.events.setItemListsSetting)
        end
    end
    local newValue = mStore.cfg[key].get()
    if not settingChanges[key] then
        settingChanges[key] = { old = state.settings[key] }
    end
    state.settings[key] = newValue
    updateSettingsRequirements(state)
    settingChanges[key].new = state.settings[key]
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
    updateSettingsRequirements(state)
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