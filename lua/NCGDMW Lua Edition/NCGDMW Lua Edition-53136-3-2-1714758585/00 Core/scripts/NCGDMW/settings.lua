local core = require('openmw.core')
local async = require('openmw.async')
local input = require('openmw.input')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')
local self = require('openmw.self')

local MOD_NAME = "NCGDMW"

local isLuaApiRecentEnough = core.API_REVISION >= 56
local isOpenMW049 = core.API_REVISION > 29

local globalSettingsKey = "SettingsPlayer" .. MOD_NAME
local skillsSettingsKey = "SettingsPlayerSkills" .. MOD_NAME
local attributesSettingsKey = "SettingsPlayerAttributes" .. MOD_NAME
local mbspSettingsKey = "SettingsPlayerMBSP" .. MOD_NAME

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

local function initSettings()
    I.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = "name",
        description = "description"
    }

    if not isLuaApiRecentEnough then
        -- THANKS:
        -- https://gitlab.com/urm-openmw-mods/camerahim/-/blob/1a12e3f8c902291d5629f2d8cc8649eac315533a/Data%20Files/scripts/CameraHIM/settings.lua#L23-35
        I.Settings.registerRenderer(
                'NCGDMW_hotkey', function(value, set)
                    return {
                        template = I.MWUI.templates.textEditLine,
                        props = {
                            text = value and input.getKeyName(value) or '',
                        },
                        events = {
                            keyPress = async:callback(function(e)
                                set(e.code)
                            end)
                        }
                    }
                end)
    end

    I.Settings.registerGroup {
        key = globalSettingsKey,
        l10n = MOD_NAME,
        name = "settingsTitle",
        page = MOD_NAME,
        order = 0,
        description = "settingsDesc",
        permanentStorage = false,
        settings = {
            {
                key = "statsMenuKey",
                name = "statsMenuKey_name",
                default = nil,
                renderer = "NCGDMW_hotkey",
            },
            {
                key = "showIntro",
                name = "showIntro_name",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "starwindNames",
                name = "starwindNames_name",
                default = false,
                renderer = "checkbox"
            },
            {
                key = "debugMode",
                name = "debugMode_name",
                default = false,
                renderer = "checkbox"
            },
        }
    }

    I.Settings.registerGroup {
        key = skillsSettingsKey,
        l10n = MOD_NAME,
        name = "settingsTitle_skills",
        page = MOD_NAME,
        order = 1,
        description = "settingsDesc_skills",
        permanentStorage = false,
        settings = {
            {
                key = "uncapperEnabled",
                name = "uncapperEnabled_name",
                default = true,
                renderer = "checkbox",
                description = "uncapperEnabled_description",
            },
            {
                key = "decayRate",
                name = "decayRate_name",
                description = "decayRate_description",
                default = "fast",
                argument = {
                    l10n = MOD_NAME,
                    items = { "fast", "standard", "slow", "none" }
                },
                renderer = "select"
            },
            {
                key = "skillIncreaseFromBooks",
                name = "skillIncreaseFromBooks_name",
                default = true,
                argument = {
                    disabled = not isLuaApiRecentEnough,
                },
                renderer = "checkbox",
                description = getDescriptionIfOpenMWTooOld(""),
            },
            {
                key = "skillIncreaseConstantFactor",
                name = "skillIncreaseConstantFactor_name",
                description = getDescriptionIfOpenMWTooOld("skillIncreaseConstantFactor_description"),
                default = "vanilla",
                argument = {
                    l10n = MOD_NAME,
                    items = { "vanilla", "half", "quarter" },
                    disabled = not isLuaApiRecentEnough,
                },
                renderer = "select",
            },
            {
                key = "skillIncreaseSquaredLevelFactor",
                name = "skillIncreaseSquaredLevelFactor_name",
                description = getDescriptionIfOpenMWTooOld("skillIncreaseSquaredLevelFactor_description"),
                default = "disabled",
                argument = {
                    l10n = MOD_NAME,
                    items = { "disabled", "downToHalf", "downToAQuarter", "downToAEighth" },
                    disabled = not isLuaApiRecentEnough,
                },
                renderer = "select",
            },
            {
                key = "carryOverExcessSkillGain",
                name = "carryOverExcessSkillGain_name",
                default = true,
                renderer = "checkbox",
                description = getDescriptionIfOpenMWTooOld("carryOverExcessSkillGain_description"),
                argument = {
                    disabled = not isLuaApiRecentEnough,
                }
            },
        }
    }

    I.Settings.registerGroup {
        key = attributesSettingsKey,
        l10n = MOD_NAME,
        name = "settingsTitle_attributes",
        page = MOD_NAME,
        order = 2,
        description = "settingsDesc_attributes",
        permanentStorage = false,
        settings = {
            {
                key = "growthRate",
                name = "growthRate_name",
                default = "slow",
                argument = {
                    l10n = MOD_NAME,
                    items = { "fast", "standard", "slow" }
                },
                renderer = "select"
            },
            {
                key = "stateBasedHP",
                name = "stateBasedHP_name",
                description = "stateBasedHP_description",
                default = false,
                renderer = "checkbox"
            },
            {
                key = "baseHPRatio",
                name = "baseHPRatio_name",
                description = "baseHPRatio_description",
                default = "full",
                argument = {
                    l10n = MOD_NAME,
                    items = { "full", "3/4", "1/2", "1/4" }
                },
                renderer = "select"
            },
            {
                key = "perLevelHPGain",
                name = "perLevelHPGain_name",
                description = "perLevelHPGain_description",
                default = "high",
                argument = {
                    l10n = MOD_NAME,
                    items = { "high", "low" }
                },
                renderer = "select"
            },
        }
    }

    I.Settings.registerGroup {
        key = mbspSettingsKey,
        l10n = MOD_NAME,
        name = "settingsTitle_MBSP",
        page = MOD_NAME,
        order = 3,
        description = "settingsDesc_MBSP",
        permanentStorage = true,
        settings = {
            {
                key = "mbspEnabled",
                name = "mbspEnabled",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "magickaXPRate",
                name = "magickaXPRate",
                default = '10',
                argument = {
                    l10n = MOD_NAME,
                    items = { '5', '10', '15', '20', '25' }
                },
                renderer = "select",
                description = "magickaXPRate_desc",
            },
            {
                key = "refundEnabled",
                name = "refundEnabled",
                default = true,
                renderer = "checkbox",
                description = "refundEnabled_desc",
            },
            {
                key = "refundMult",
                name = "refundMult",
                default = '4',
                argument = {
                    l10n = MOD_NAME,
                    items = { '1', '2', '3', '4', '5' }
                },
                renderer = "select",
                description = "refundMult_desc"
            },
            {
                key = "refundStart",
                default = 35,
                renderer = 'number',
                name = "Refund Skill Start",
                description = "refundStart_desc",
                argument = {
                    integer = true,
                    min = 1,
                    max = 1000,
                },
            },
        }
    }
end

local playerGlobalStorage = storage.playerSection(globalSettingsKey)
local playerSkillsStorage = storage.playerSection(skillsSettingsKey)
local playerAttributesStorage = storage.playerSection(attributesSettingsKey)
local playerMBSPStorage = storage.playerSection(mbspSettingsKey)

local baseHPRatioFactors = {
    ["3/4"] = 3 / 4,
    ["1/2"] = 1 / 2,
    ["1/4"] = 1 / 4,
}
local function getBaseHPRatioFactor(key)
    return baseHPRatioFactors[key]
end

local skillIncreaseSquaredLevelFactors = {
    downToHalf = 2,
    downToAQuarter = 4,
    downToAEighth = 8,
}
local function getSkillIncreaseSquaredLevelFactor(key)
    return skillIncreaseSquaredLevelFactors[key]
end

local skillIncreaseConstantFactors = {
    half = 2,
    quarter = 4,
}
local function getSkillIncreaseConstantFactor(key)
    return skillIncreaseConstantFactors[key]
end

if not isLuaApiRecentEnough then
    -- clear settings in case the player downgrade from 0.49 to 0.48
    playerSkillsStorage:set("carryOverExcessSkillGain", false)
    playerSkillsStorage:set("skillIncreaseConstantFactor", "vanilla")
    playerSkillsStorage:set("skillIncreaseSquaredLevelFactor", "disabled")
    playerSkillsStorage:set("skillIncreaseFromBooks", true)
end

playerAttributesStorage:subscribe(async:callback(function(_, key)
    if key == "growthRate" then
        self:sendEvent('updatePlayerStatsAndHealth', true)
    else
        self:sendEvent('updateHealth')
    end
end))

playerSkillsStorage:subscribe(async:callback(function(_, key)
    if key == "decayRate" then
        self:sendEvent('logDecayTime')
    end
end))

return {
    MOD_NAME = MOD_NAME,
    isLuaApiRecentEnough = isLuaApiRecentEnough,
    isOpenMW049 = isOpenMW049,
    initSettings = initSettings,
    playerGlobalStorage = playerGlobalStorage,
    playerSkillsStorage = playerSkillsStorage,
    playerAttributesStorage = playerAttributesStorage,
    playerMBSPStorage = playerMBSPStorage,
    getBaseHPRatioFactor = getBaseHPRatioFactor,
    getSkillIncreaseSquaredLevelFactor = getSkillIncreaseSquaredLevelFactor,
    getSkillIncreaseConstantFactor = getSkillIncreaseConstantFactor,
}