local I = require("openmw.interfaces")
local storage = require('openmw.storage')

local D = require('scripts.BMS.definition')

local globalKey = "SettingsGlobal" .. D.MOD_NAME

local module = {
    globalKey = globalKey,
    storage = storage.globalSection(globalKey),
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
    I.Settings.registerGroup {
        key = globalKey,
        l10n = D.MOD_NAME,
        name = "settingsTitle_name",
        page = D.MOD_NAME,
        permanentStorage = false,
        settings = {
            {
                key = "enabled",
                name = "enabled_name",
                description = "enabled_desc",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "debugMode",
                name = "debugMode_name",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "minItemSalePricePercent",
                name = "minItemSalePricePercent_name",
                description = "minItemSalePricePercent_desc",
                default = 5,
                renderer = D.renderers.number,
                argument = module.minPercentArgument,
            },
            {
                key = "maxItemSalePricePercent",
                name = "maxItemSalePricePercent_name",
                description = "maxItemSalePricePercent_desc",
                default = 50,
                renderer = D.renderers.number,
                argument = module.maxPercentArgument,
            },
            {
                key = "serviceDifficulty",
                name = "serviceDifficulty_name",
                description = "serviceDifficulty_desc",
                default = { from = 75, to = 100, maxLvl = 20 },
                renderer = D.renderers.scalingPercent,
                argument = module.difficultyArgument,
            },
            {
                key = "hagglingDifficulty",
                name = "hagglingDifficulty_name",
                description = "hagglingDifficulty_desc",
                default = { from = 50, to = 100, maxLvl = 20 },
                renderer = D.renderers.scalingPercent,
                argument = module.difficultyArgument,
            },
            {
                key = "persuasionDifficulty",
                name = "persuasionDifficulty_name",
                description = "persuasionDifficulty_desc",
                default = { from = 50, to = 75, maxLvl = 20 },
                renderer = D.renderers.scalingPercent,
                argument = module.difficultyArgument,
            },
            {
                key = "dispositionImpactOnPricesPercent",
                name = "dispositionImpactOnPricesPercent_name",
                description = "dispositionImpactOnPricesPercent_desc",
                default = 50,
                renderer = D.renderers.number,
                argument = {
                    min = 0,
                    max = 100,
                    isPercent = true,
                },
            },
            {
                key = "dispositionImpactOnHagglingPercent",
                name = "dispositionImpactOnHagglingPercent_name",
                description = "dispositionImpactOnHagglingPercent_desc",
                default = 50,
                renderer = D.renderers.number,
                argument = {
                    min = 0,
                    max = 100,
                    isPercent = true,
                },
            },
            {
                key = "preventSkillsBelowOriginalValues",
                name = "preventSkillsBelowOriginalValues_name",
                description = "preventSkillsBelowOriginalValues_desc",
                default = false,
                renderer = "checkbox",
            },
        }
    }
end

return module