local I = require("openmw.interfaces")
local storage = require('openmw.storage')

local mDef = require("scripts.TakeCover.definition")

local module = {}

local globalSettingsKey = "SettingsGlobal" .. mDef.MOD_NAME

local function getDescriptionIfOpenMWTooOld(key)
    if not mDef.isLuaApiRecentEnough then
        if mDef.isOpenMW049 then
            return "requiresNewerOpenmw49"
        else
            return "requiresOpenmw49"
        end
    end
    return key
end

local settingGroups = {
    [globalSettingsKey] = {
        order = 0,
        key = globalSettingsKey,
        l10n = mDef.MOD_NAME,
        name = "settingsTitle",
        page = mDef.MOD_NAME,
        description = getDescriptionIfOpenMWTooOld("settingsDesc"),
        permanentStorage = false,
        settings = {
            {
                key = "enabled",
                name = "enabled_name",
                default = true,
                renderer = "checkbox",
                argument = {
                    disabled = not mDef.isLuaApiRecentEnough,
                }
            },
            {
                key = "debugMode",
                name = "debugMode_name",
                default = false,
                renderer = "checkbox",
            },
        },
    },
}

module.globalStorage = storage.globalSection(globalSettingsKey)

module.initSettings = function()
    I.Settings.registerGroup(settingGroups[globalSettingsKey])

    if not mDef.isLuaApiRecentEnough then
        module.globalStorage:set("enabled", false)
    end
end

return module