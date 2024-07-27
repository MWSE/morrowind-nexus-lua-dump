local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = "LevelsAndLimits",
    l10n = "LevelsAndLimits",
    name = 'name',
    description = 'description'
}

I.Settings.registerGroup {
    key = "SettingsLevelsAndLimits",
    l10n = "LevelsAndLimits",
    name = "settingsTitle",
    page = "LevelsAndLimits",
    description = "settingsDesc",
    permanentStorage = false,
    settings = {
        {
            key = "lalToggle",
            name = "lalToggleName",
            description = "lalToggleDesc",
            default = true,
            renderer = "checkbox"
        },
        {
            key = "lalLimitMajor",
            name = "lalLimitMajorName",
            description = "lalLimitMajorDesc",
            default = 100,
            renderer = "number"
        },
        {
            key = "lalLimitMinor",
            name = "lalLimitMinorName",
            description = "lalLimitMinorDesc",
            default = 75,
            renderer = "number"
        },
        {
            key = "lalLimitMisc",
            name = "lalLimitMiscName",
            description = "lalLimitMiscDesc",
            default = 35,
            renderer = "number"
        },
        {
            key = "lalSpecializationToggle",
            name = "lalSpecializationToggleName",
            description = "lalSpecializationToggleDesc",
            default = true,
            renderer = "checkbox"
        },
        {
            key = "lalSpecializationMalus",
            name = "lalSpecializationMalusName",
            description = "lalSpecializationMalusDesc",
            default = 5,
            renderer = "number"
        },
        {
            key = "lalFavoredAttributesToggle",
            name = "lalFavoredAttributesToggleName",
            description = "lalFavoredAttributesToggleDesc",
            default = true,
            renderer = "checkbox"
        },
        {
            key = "lalFavoredAttributesMalus",
            name = "lalFavoredAttributesMalusName",
            description = "lalFavoredAttributesMalusDesc",
            default = 5,
            renderer = "number"
        }   
    }
}


