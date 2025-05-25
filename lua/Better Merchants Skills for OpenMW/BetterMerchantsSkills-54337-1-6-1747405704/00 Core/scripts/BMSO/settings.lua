local core = require('openmw.core')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')

local MOD_NAME = "BMSO"

-- 44 for UiModeChanged
local isLuaApiRecentEnough = core.API_REVISION >= 44
local isOpenMW049 = core.API_REVISION > 29

local function initSettings()
    I.Settings.registerGroup {
        key = "SettingsGlobal" .. MOD_NAME,
        l10n = MOD_NAME,
        name = "settingsTitle_name",
        page = MOD_NAME,
        permanentStorage = true,
        settings = {
            {
                key = "enabled",
                name = "enabled_name",
                default = true,
                renderer = "checkbox",
                argument = {
                    disabled = not isLuaApiRecentEnough,
                }
            },
            {
                key = "maxMercantileDifference",
                name = "maxMercantileDifference_name",
                description = "maxMercantileDifference_description",
                default = 30,
                renderer = "number",
                argument = {
                    integer = true,
                    min = 0,
                    max = 100,
                    disabled = not isLuaApiRecentEnough,
                },
            },
            {
                key = "maxSpeechcraftDifference",
                name = "maxSpeechcraftDifference_name",
                description = "maxSpeechcraftDifference_description",
                default = 30,
                renderer = "number",
                argument = {
                    integer = true,
                    min = 0,
                    max = 100,
                    disabled = not isLuaApiRecentEnough,
                },
            },
            {
                key = "playerLevelBasedSkillsBoost",
                name = "playerLevelBasedSkillsBoost_name",
                description = "playerLevelBasedSkillsBoost_description",
                default = "1/2",
                renderer = "select",
                argument = {
                    l10n = MOD_NAME,
                    items = { "no", "1/4", "1/2", "3/4" },
                    disabled = not isLuaApiRecentEnough,
                },
            },
            {
                key = "debugMode",
                name = "debugMode_name",
                default = false,
                renderer = "checkbox",
            },
        }
    }
end

local playerLevelBasedSkillsBoosts = {
    ["1/4"] = 1 / 4,
    ["1/2"] = 1 / 2,
    ["3/4"] = 3 / 4,
}
local function getPlayerLevelBasedSkillsBoost(key)
    return playerLevelBasedSkillsBoosts[key]
end

return {
    MOD_NAME = MOD_NAME,
    isLuaApiRecentEnough = isLuaApiRecentEnough,
    isOpenMW049 = isOpenMW049,
    initSettings = initSettings,
    getPlayerLevelBasedSkillsBoost = getPlayerLevelBasedSkillsBoost,
    globalStorage = storage.globalSection("SettingsGlobal" .. MOD_NAME)
}