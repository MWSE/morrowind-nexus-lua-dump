local I = require("openmw.interfaces")
local storage = require('openmw.storage')

local mDef = require('scripts.MULE.definition')

local mainKey = "SettingsPlayer" .. mDef.MOD_NAME
local expKey = "SettingsExp" .. mDef.MOD_NAME
local skillsKey = "SettingsSkills" .. mDef.MOD_NAME
local decayKey = "SettingsDecay" .. mDef.MOD_NAME
local debugKey = "SettingsDebug" .. mDef.MOD_NAME

local module = {}

local groups = {
    [mainKey] = {
        order = 0,
        settings = {
            { key = "modEnabled", default = true, renderer = "checkbox" },
            { key = "attributeMaximum", default = 200, renderer = "number",
              argument = { integer = true, min = 1, max = 500 } },
            { key = "alternateHealthSystem", default = true, renderer = "checkbox" },
            { key = "flatHealthPerLevel", default = 5, renderer = "number",
              argument = { integer = true, min = 0, max = 100 } },
            { key = "healthPerEndurance", default = 2, renderer = "number",
              argument = { integer = true, min = 0, max = 50 } },
            { key = "luckPerLevel", default = 10, renderer = "number",
              argument = { integer = true, min = 0, max = 50 } },
            { key = "acrobaticsMod", default = 50, renderer = "number",
              argument = { integer = true, min = 0, max = 200 } },
        }
    },
    [expKey] = {
        order = 1,
        settings = {
            { key = "majorExpRate", default = 100, renderer = "number",
              argument = { integer = true, min = 0, max = 500 } },
            { key = "minorExpRate", default = 100, renderer = "number",
              argument = { integer = true, min = 0, max = 500 } },
            { key = "miscExpRate", default = 100, renderer = "number",
              argument = { integer = true, min = 0, max = 500 } },
        }
    },
    [skillsKey] = {
        order = 2,
        settings = {
            { key = "majorSkillRate", default = 50, renderer = "number",
              argument = { integer = true, min = 0, max = 500 } },
            { key = "majorSkillThreshold", default = 0, renderer = "number",
              argument = { integer = true, min = 0, max = 100 } },
            { key = "minorSkillRate", default = 50, renderer = "number",
              argument = { integer = true, min = 0, max = 500 } },
            { key = "minorSkillThreshold", default = 0, renderer = "number",
              argument = { integer = true, min = 0, max = 100 } },
            { key = "miscSkillRate", default = 30, renderer = "number",
              argument = { integer = true, min = 0, max = 500 } },
            { key = "miscSkillThreshold", default = 30, renderer = "number",
              argument = { integer = true, min = 0, max = 100 } },
            { key = "miscLevelThreshold", default = 3, renderer = "number",
              argument = { integer = true, min = 0, max = 50 } },
        }
    },
    [decayKey] = {
        order = 3,
        settings = {
            { key = "skillDecay", default = false, renderer = "checkbox" },
            { key = "skillDecayMessage", default = true, renderer = "checkbox" },
            { key = "skillDecayUseBase", default = false, renderer = "checkbox" },
            { key = "skillDecayTime", default = 15, renderer = "number",
              argument = { integer = true, min = 1, max = 365 } },
            { key = "skillDecayMin", default = 15, renderer = "number",
              argument = { integer = true, min = 0, max = 100 } },
        }
    },
    [debugKey] = {
        order = 4,
        settings = {
            { key = "debugMode", default = false, renderer = "checkbox" },
        }
    },
}

local function getStorage(key)
    if key == debugKey then
        return storage.globalSection(key)
    elseif storage.playerSection then
        return storage.playerSection(key)
    end
end

module.mainStorage = getStorage(mainKey)
module.expStorage = getStorage(expKey)
module.skillsStorage = getStorage(skillsKey)
module.decayStorage = getStorage(decayKey)
module.debugStorage = getStorage(debugKey)

for key, group in pairs(groups) do
    group.key = key
    group.page = mDef.MOD_NAME
    group.l10n = mDef.MOD_NAME
    group.name = key .. "_name"
    group.description = key .. "_desc"
    group.permanentStorage = false
    for _, setting in ipairs(group.settings) do
        setting.name = setting.key .. "_name"
        setting.description = setting.key .. "_desc"
    end
end

module.initGlobalSettings = function()
    I.Settings.registerGroup(groups[debugKey])
end

module.initPlayerSettings = function()
    I.Settings.registerPage {
        key = mDef.MOD_NAME,
        l10n = mDef.MOD_NAME,
        name = "name",
        description = "description",
    }
    I.Settings.registerGroup(groups[mainKey])
    I.Settings.registerGroup(groups[expKey])
    I.Settings.registerGroup(groups[skillsKey])
    I.Settings.registerGroup(groups[decayKey])
end

return module
