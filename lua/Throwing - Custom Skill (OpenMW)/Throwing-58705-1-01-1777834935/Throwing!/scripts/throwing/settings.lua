local I = require('openmw.interfaces')

local MODNAME = 'Throwing'

I.Settings.registerPage {
    key = MODNAME,
    l10n = MODNAME,
    name = 'PageName',
    description = 'PageDescription',
}

I.Settings.registerGroup {
    key = 'Settings_' .. MODNAME,
    page = MODNAME,
    l10n = MODNAME,
    name = 'SettingsName',
    description = 'SettingsDescription',
    permanentStorage = true,
    settings = {
        {
            key = 'enabled',
            renderer = 'checkbox',
            name = 'SettingEnabled',
            description = 'SettingEnabledDescription',
            default = true,
        },
        {
            key = 'replaceMarksman',
            renderer = 'checkbox',
            name = 'SettingReplaceMarksman',
            description = 'SettingReplaceMarksmanDescription',
            default = true,
        },
        {
            key = 'showFeedback',
            renderer = 'checkbox',
            name = 'SettingShowFeedback',
            description = 'SettingShowFeedbackDescription',
            default = false,
        },
        {
            key = 'quickThrowEnabled',
            renderer = 'checkbox',
            name = 'SettingQuickThrowEnabled',
            description = 'SettingQuickThrowEnabledDescription',
            default = true,
        },
        {
            key = 'shortRangeBonusEnabled',
            renderer = 'checkbox',
            name = 'SettingShortRangeBonusEnabled',
            description = 'SettingShortRangeBonusEnabledDescription',
            default = true,
        },
        {
            key = 'criticalEnabled',
            renderer = 'checkbox',
            name = 'SettingCriticalEnabled',
            description = 'SettingCriticalEnabledDescription',
            default = true,
        },
        {
            key = 'twinFlightEnabled',
            renderer = 'checkbox',
            name = 'SettingTwinFlightEnabled',
            description = 'SettingTwinFlightEnabledDescription',
            default = true,
        },
        {
            key = 'bleedEnabled',
            renderer = 'checkbox',
            name = 'SettingBleedEnabled',
            description = 'SettingBleedEnabledDescription',
            default = true,
        },
        {
            key = 'paralyzeEnabled',
            renderer = 'checkbox',
            name = 'SettingParalyzeEnabled',
            description = 'SettingParalyzeEnabledDescription',
            default = true,
        },
        {
            key = 'showMechanicTooltips',
            renderer = 'checkbox',
            name = 'SettingShowMechanicTooltips',
            description = 'SettingShowMechanicTooltipsDescription',
            default = true,
        },
        {
            key = 'showPerkTooltips',
            renderer = 'checkbox',
            name = 'SettingShowPerkTooltips',
            description = 'SettingShowPerkTooltipsDescription',
            default = true,
        },
        {
            key = 'tooltipUnlockedOnly',
            renderer = 'checkbox',
            name = 'SettingTooltipUnlockedOnly',
            description = 'SettingTooltipUnlockedOnlyDescription',
            default = false,
        },
        {
            key = 'debugMessages',
            renderer = 'checkbox',
            name = 'SettingDebugMessages',
            description = 'SettingDebugMessagesDescription',
            default = false,
        },
    },
}
