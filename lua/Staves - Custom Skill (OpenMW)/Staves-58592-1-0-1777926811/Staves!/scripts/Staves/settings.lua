--[[
    Staves! — Settings (MENU scope)
    Registered at menu scope so it is visible and mutable from the main menu
    as well as from inside a loaded game.
]]

local I = require('openmw.interfaces')

local MODNAME = 'Staves'

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
        -- Core
        { key = 'enabled', name = 'SettingEnabled', renderer = 'checkbox', default = true,
          description = 'SettingEnabledDescription' },
        { key = 'spellBonus', name = 'SettingSpellBonus', renderer = 'number', default = 25,
          description = 'SettingSpellBonusDescription',
          argument = { integer = true, min = 0, max = 50 } },
        { key = 'enchantSaving', name = 'SettingEnchantSaving', renderer = 'checkbox', default = true,
          description = 'SettingEnchantSavingDescription' },
        { key = 'maxSaveChance', name = 'SettingMaxSaveChance', renderer = 'number', default = 50,
          description = 'SettingMaxSaveChanceDescription',
          argument = { integer = true, min = 10, max = 75 } },
        { key = 'redirectXP', name = 'SettingRedirectXP', renderer = 'checkbox', default = true,
          description = 'SettingRedirectXPDescription' },
        { key = 'spellXpShare', name = 'SettingSpellXpShare', renderer = 'number', default = 25,
          description = 'SettingSpellXpShareDescription',
          argument = { integer = true, min = 0, max = 100 } },

        -- Perk toggles
        { key = 'concussiveEnabled', name = 'SettingConcussiveEnabled', renderer = 'checkbox', default = true,
          description = 'SettingConcussiveEnabledDescription' },
        { key = 'arcaneSiphonEnabled', name = 'SettingArcaneSiphonEnabled', renderer = 'checkbox', default = true,
          description = 'SettingArcaneSiphonEnabledDescription' },
        { key = 'resonantConduitEnabled', name = 'SettingResonantConduitEnabled', renderer = 'checkbox', default = true,
          description = 'SettingResonantConduitEnabledDescription' },
        { key = 'nullPulseEnabled', name = 'SettingNullPulseEnabled', renderer = 'checkbox', default = true,
          description = 'SettingNullPulseEnabledDescription' },

        -- UX
        { key = 'showFeedback', name = 'SettingShowFeedback', renderer = 'checkbox', default = false,
          description = 'SettingShowFeedbackDescription' },
        { key = 'showMechanicTooltips', name = 'SettingShowMechanicTooltips', renderer = 'checkbox', default = true,
          description = 'SettingShowMechanicTooltipsDescription' },
        { key = 'showPerkTooltips', name = 'SettingShowPerkTooltips', renderer = 'checkbox', default = true,
          description = 'SettingShowPerkTooltipsDescription' },
        { key = 'tooltipUnlockedOnly', name = 'SettingTooltipUnlockedOnly', renderer = 'checkbox', default = false,
          description = 'SettingTooltipUnlockedOnlyDescription' },
        { key = 'debugLogging', name = 'SettingDebugMessages', renderer = 'checkbox', default = false,
          description = 'SettingDebugMessagesDescription' },
    },
}
