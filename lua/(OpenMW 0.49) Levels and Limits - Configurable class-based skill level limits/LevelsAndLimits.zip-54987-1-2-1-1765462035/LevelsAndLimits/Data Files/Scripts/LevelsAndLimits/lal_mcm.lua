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
        },
        {
            key = "lalRacialSkillToggle",
            name = "lalRacialSkillToggleName",
            description = "lalRacialSkillToggleDesc",
            default = true,
            renderer = "checkbox"
        },
        {
            key = "lalRacialSkillMalus",
            name = "lalRacialSkillMalusName",
            description = "lalRacialSkillMalusDesc",
            default = 5,
            renderer = "number"
        },
        {
            key = "lalDisableTrainingToggle",
            name = "lalDisableTrainingToggleName",
            description = "lalDisableTrainingToggleDesc",
            default = false,
            renderer = "checkbox"
        },
        {
            key = "lalDisableBooksToggle",
            name = "lalDisableBooksToggleName",
            description = "lalDisableBooksToggleDesc",
            default = false,
            renderer = "checkbox"
        },
    }
}
    
    
I.Settings.registerGroup {
    key = "SettingsLevelsAndLimitsXP",
    l10n = "LevelsAndLimits",
    name = "settingsTitleXP",
    page = "LevelsAndLimits",
    description = "settingsDescXP",
    permanentStorage = false,
    settings = {
        {
            key = "lalXPToggle",
            name = "lalXPToggleName",
            description = "lalXPToggleDesc",
            default = true,
            renderer = "checkbox"
        },
        {
            key = "lalXPGlobalMultiplier",
            name = "lalXPGlobalMultiplierName",
            description = "lalXPGlobalMultiplierDesc",
            default = 1,
            renderer = "number"
        },
        {
            key = "lalXPDiminishingToggle",
            name = "lalXPDiminishingToggleName",
            description = "lalXPDiminishingToggleDesc",
            default = false,
            renderer = "checkbox"
        },
        {
            key = "lalXPDiminishingMultiplier",
            name = "lalXPDiminishingMultiplierName",
            description = "lalXPDiminishingMultiplierDesc",
            default = 1,
            renderer = "number"
        },
        {
            key = "lalXPDisableToggle",
            name = "lalXPDisableToggleName",
            description = "lalXPDisableToggleDesc",
            default = false,
            renderer = "checkbox"
        }
    }
}
    
I.Settings.registerGroup {
    key = "SettingsLevelsAndLimitsY",
    l10n = "LevelsAndLimits",
    name = "settingsTitleY",
    page = "LevelsAndLimits",
    description = "settingsDescY",
    permanentStorage = false,
    settings = {
                {
            key = "lalLevelProgressLimitToggle",
            name = "lalLevelProgressLimitToggleName",
            description = "lalLevelProgressLimitToggleDesc",
            default = true,
            renderer = "checkbox"
        },
        {
            key = "lalLevelProgressLimit",
            name = "lalLevelProgressLimitName",
            description = "lalLevelProgressLimitDesc",
            default = 10,
            renderer = "number"
        },
        {
            key = "lalShowDebugInfo",
            name = "lalShowDebugInfoName",
            description = "lalShowDebugInfoDesc",
            default = false,
            renderer = "checkbox"
        }
    }
}

