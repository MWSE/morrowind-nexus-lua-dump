local storage = require("openmw.storage")
local I = require("openmw.interfaces")

local context = 'GreaterIntervention'

I.Settings.registerPage {
    key = 'GreaterIntervention',
    l10n = context,
    name = 'mod_name',
    description = 'mod_description'
}

I.Settings.registerGroup {
    key = 'GreaterInterventionSettings',
    page = 'GreaterIntervention',
    l10n = context,
    name = 'settings_window_name',
    permanentStorage = false,
    settings = {
        {
            key = 'TextSize',
            renderer = 'number',
            name = 'text_size',
            description = 'text_size_desc',
            default = 20,
            argument = {min = 2, max = 100, integer = true},
        },
        {
            key = 'MaxPerColumn',
            renderer = 'number',
            name = 'max_items_per_column',
            description = 'max_items_per_column_desc',
            default = 16,
            argument = {min = 2, max = 100, integer = true},
        },
        {
            key = 'EnableStandardInterventionEnhance',
            renderer = 'checkbox',
            name = 'enable_standard_intervention_enhance',
            description = 'enable_standard_intervention_enhance_desc',
            default = true,
        },
        {
            key = 'EnableStandardInterventionEnhanceMWE',
            renderer = 'checkbox',
            name = 'enable_standard_intervention_enhance_MWE',
            description = 'enable_standard_intervention_enhance_MWE_desc',
            default = true,
        },
        {
            key = 'UpdateFrequency',
            renderer = 'number',
            name = 'update_frequency',
            description = 'update_frequency_desc',
            default = 5,
            argument = {min = 1, max = 60, integer = true},
        },
    },
}