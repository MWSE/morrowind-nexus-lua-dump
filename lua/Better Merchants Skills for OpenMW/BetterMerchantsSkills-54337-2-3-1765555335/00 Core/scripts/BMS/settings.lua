local I = require("openmw.interfaces")
local storage = require('openmw.storage')

local D = require('scripts.BMS.definition')

local globalKey = "SettingsGlobal" .. D.MOD_NAME
local dispScalingKey = "SettingsDispScaling" .. D.MOD_NAME

local module = {
    globalKey = globalKey,
    globalStorage = storage.globalSection(globalKey),
    dispScalingStorage = storage.globalSection(dispScalingKey),
    difficultySettings = {
        serviceDifficulty = true,
        hagglingDifficulty = true,
        persuasionDifficulty = true,
    },
    minPercentArgument = {
        min = 0,
        max = 75,
        isPercent = true,
    },
    maxPercentArgument = {
        min = 25,
        max = 75,
        isPercent = true,
    },
}

module.difficultyArgument = {
    playerLevel = 1,
    from = {
        integer = true,
        min = 0,
        max = 500,
    },
    to = {
        integer = true,
        min = 0,
        max = 500,
    },
    maxLvl = {
        integer = true,
        min = 1,
        max = 500,
    },
}

module.initSettings = function()
    local settingGroups = {
        [globalKey] = {
            order = 0,
            description = false,
            settings = {
                {
                    key = "enabled",
                    description = false,
                    default = true,
                    renderer = "checkbox",
                },
                {
                    key = "debugMode",
                    description = false,
                    default = false,
                    renderer = "checkbox",
                },
                {
                    key = "minItemSalePricePercent",
                    default = 5,
                    renderer = D.renderers.number,
                    argument = module.minPercentArgument,
                },
                {
                    key = "maxItemSalePricePercent",
                    default = 50,
                    renderer = D.renderers.number,
                    argument = module.maxPercentArgument,
                },
                {
                    key = "serviceDifficulty",
                    default = { from = 75, to = 100, maxLvl = 20 },
                    renderer = D.renderers.scalingPercent,
                    argument = module.difficultyArgument,
                },
                {
                    key = "hagglingDifficulty",
                    default = { from = 50, to = 100, maxLvl = 20 },
                    renderer = D.renderers.scalingPercent,
                    argument = module.difficultyArgument,
                },
                {
                    key = "persuasionDifficulty",
                    default = { from = 50, to = 75, maxLvl = 20 },
                    renderer = D.renderers.scalingPercent,
                    argument = module.difficultyArgument,
                },
                {
                    key = "dispositionImpactOnPricesPercent",
                    default = 50,
                    renderer = D.renderers.number,
                    argument = { min = 0, max = 100, isPercent = true },
                },
                {
                    key = "preventSkillsBelowOriginalValues",
                    default = false,
                    renderer = "checkbox",
                },
            },
        },
        [dispScalingKey] = {
            order = 1,
            settings = {
                {
                    key = "dispScalingEnabled",
                    description = false,
                    default = true,
                    renderer = "checkbox",
                },
                {
                    key = "dispScalingNotify",
                    default = true,
                    renderer = "checkbox",
                },
                {
                    key = "dispScalingMaxBuyGain",
                    default = 10,
                    renderer = D.renderers.number,
                    argument = { min = 0, max = 100, integer = true },
                },
                {
                    key = "dispScalingMaxSellGain",
                    default = 4,
                    renderer = D.renderers.number,
                    argument = { min = 0, max = 100, integer = true },
                },
                {
                    key = "dispScalingMinBaseGold",
                    default = 500,
                    renderer = D.renderers.number,
                    argument = { min = 1, max = 9999, integer = true },
                },
                {
                    key = "dispScalingMaxLoss",
                    default = 4,
                    renderer = D.renderers.number,
                    argument = { min = 0, max = 100, integer = true },
                },
            },
        },
    }

    for key, group in pairs(settingGroups) do
        group.key = key
        group.page = D.MOD_NAME
        group.name = key .. "_name"
        if group.description ~= false then
            group.description = key .. "_desc"
        else
            group.description = nil
        end
        group.l10n = D.MOD_NAME
        group.permanentStorage = false
        for _, setting in ipairs(group.settings) do
            setting.name = setting.key .. "_name"
            if setting.description ~= false then
                setting.description = setting.key .. "_desc"
            else
                setting.description = nil
            end
            setting.argument = setting.argument or { disabled = false }
        end
    end

    I.Settings.registerGroup(settingGroups[globalKey])
    I.Settings.registerGroup(settingGroups[dispScalingKey])
end

return module