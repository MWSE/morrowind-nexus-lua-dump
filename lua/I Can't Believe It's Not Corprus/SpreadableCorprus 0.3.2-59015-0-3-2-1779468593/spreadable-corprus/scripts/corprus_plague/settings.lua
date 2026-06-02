local I = require('openmw.interfaces')
local config = require('scripts.corprus_plague.config')

local dayItems = {}
for day = config.minIncubationDays, config.maxIncubationDays do
    dayItems[#dayItems + 1] = day
end

local dispositionModifierItems = {}
local dispositionModifierSteps = math.floor(
    (config.maxDispositionModifier - config.minDispositionModifier) / config.dispositionModifierStep + 0.5
)
for step = 0, dispositionModifierSteps do
    local value = config.minDispositionModifier + step * config.dispositionModifierStep
    dispositionModifierItems[#dispositionModifierItems + 1] = math.floor(value * 10 + 0.5) / 10
end

local M = {}

function M.registerPage()
    I.Settings.registerPage({
        key = config.settingsPageKey,
        l10n = 'CorprusPlague',
        name = 'CorprusPlague',
        description = 'settingsPageDescription',
    })
end

function M.registerGroup()
    I.Settings.registerGroup({
        key = config.settingsGroupKey,
        page = config.settingsPageKey,
        l10n = 'CorprusPlague',
        name = 'pandemicSettings',
        description = 'pandemicSettingsDescription',
        permanentStorage = false,
        order = 0,
        settings = {
            {
                key = 'incubationDays',
                renderer = 'select',
                name = 'incubationDays',
                description = 'incubationDaysDescription',
                default = config.defaultIncubationDays,
                argument = {
                    l10n = 'CorprusPlague',
                    items = dayItems,
                },
            },
            {
                key = 'dispositionModifier',
                renderer = 'select',
                name = 'dispositionModifier',
                description = 'dispositionModifierDescription',
                default = config.defaultDispositionModifier,
                argument = {
                    l10n = 'CorprusPlagueDisposition',
                    items = dispositionModifierItems,
                },
            },
        },
    })
end

return M
