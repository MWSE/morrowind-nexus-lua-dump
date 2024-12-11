local I = require("openmw.interfaces")

local mSettings = require('scripts.HBFS.settings')
local mTools = require('scripts.HBFS.tools')

local function getDescriptionIfOpenMWTooOld(key)
    if not mSettings.isLuaApiRecentEnough then
        if mSettings.isOpenMW049 then
            return "requiresNewerOpenmw49"
        else
            return "requiresOpenmw49"
        end
    end
    return key
end

local function addSettings(settingsKey, settings)
    for _, setting in mTools.spairs(mSettings.cfg, function(t, a, b) return t[a].order < t[b].order end, function(a) return a.section == settingsKey end) do
        table.insert(settings.settings, setting)
    end
    I.Settings.registerGroup(settings)
end

local globalSettings = {
    key = mSettings.globalKey,
    page = mSettings.MOD_NAME,
    l10n = mSettings.MOD_NAME,
    name = "settingsTitle",
    description = getDescriptionIfOpenMWTooOld("settingsDesc"),
    permanentStorage = false,
    order = 0,
    settings = {},
}
addSettings(mSettings.globalKey, globalSettings)

local playerSettings = {
    key = mSettings.playerKey,
    page = mSettings.MOD_NAME,
    l10n = mSettings.MOD_NAME,
    name = "playerSettingsTitle",
    description = "playerSettingsDesc",
    permanentStorage = false,
    order = 1,
    settings = {},
}
addSettings(mSettings.playerKey, playerSettings)

local actorsSettings = {
    key = mSettings.actorsKey,
    page = mSettings.MOD_NAME,
    l10n = mSettings.MOD_NAME,
    name = "actorsSettingsTitle",
    description = "actorsSettingsDesc",
    permanentStorage = false,
    order = 2,
    settings = {},
}
addSettings(mSettings.actorsKey, actorsSettings)

if not mSettings.isLuaApiRecentEnough then
    mSettings.globalSection():set("enabled", false)
end
