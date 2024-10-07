local core = require('openmw.core')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')

local mShared = require('scripts.FairCare.shared')

local settingsModule = {}

local MOD_NAME = "FairCare"
settingsModule.MOD_NAME = MOD_NAME

local isLuaApiRecentEnough = core.API_REVISION >= 68
settingsModule.isLuaApiRecentEnough = isLuaApiRecentEnough

local isOpenMW049 = core.API_REVISION > 29
settingsModule.isOpenMW049 = isOpenMW049

local globalSettingsKey = "SettingsGlobal" .. MOD_NAME
local creaturesSettingsKey = "SettingsCreatures" .. MOD_NAME

local function getDescriptionIfOpenMWTooOld(key)
    if not isLuaApiRecentEnough then
        if isOpenMW049 then
            return "requiresNewerOpenmw49"
        else
            return "requiresOpenmw49"
        end
    end
    return key
end

local settingGroups = {
    [globalSettingsKey] = {
        key = globalSettingsKey,
        l10n = MOD_NAME,
        name = "settingsTitle",
        page = MOD_NAME,
        order = 0,
        description = getDescriptionIfOpenMWTooOld("settingsDesc"),
        permanentStorage = false,
        settings = {
            {
                key = "enabled",
                name = "enabled_name",
                description = getDescriptionIfOpenMWTooOld(""),
                default = true,
                renderer = "checkbox",
                argument = {
                    disabled = not isLuaApiRecentEnough,
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
    [creaturesSettingsKey] = {
        key = creaturesSettingsKey,
        l10n = MOD_NAME,
        name = "creaturesSettingsTitle",
        page = MOD_NAME,
        order = 1,
        description = "creaturesSettingsDescription",
        permanentStorage = false,
        settings = {},
    },
}

for _, creatureTypeName in pairs(mShared.creatureTypes) do
    table.insert(settingGroups[creaturesSettingsKey].settings, {
        key = creatureTypeName,
        name = creatureTypeName .. "_name",
        description = creatureTypeName .. "_description",
        -- Exclude creatures of type Creature by default
        default = creatureTypeName ~= "Creatures",
        renderer = "checkbox",
        argument = {
            disabled = not isLuaApiRecentEnough,
        }
    })
end

local function getStorage(key)
    return storage.globalSection(key)
end
settingsModule.globalStorage = getStorage(globalSettingsKey)
settingsModule.creaturesStorage = getStorage(creaturesSettingsKey)

local function getSetting(groupKey, settingKey)
    local group = settingGroups[groupKey]
    if group ~= nil then
        for _, setting in ipairs(group.settings) do
            if setting.key == settingKey then
                return setting
            end
        end
    end
    print(string.format("Cannot find setting \"%s\" in group \"%s\"", settingKey, groupKey))
    return nil
end

local function setSetting(groupKey, settingKey, value)
    local setting = getSetting(groupKey, settingKey)
    if setting ~= nil then
        getStorage(groupKey):set(settingKey, value)
    end
    return nil
end

local function initSettings()
    I.Settings.registerGroup(settingGroups[globalSettingsKey])
    I.Settings.registerGroup(settingGroups[creaturesSettingsKey])

    if not isLuaApiRecentEnough then
        setSetting(globalSettingsKey, "enabled", false)
    end
end
settingsModule.initSettings = initSettings

return settingsModule
