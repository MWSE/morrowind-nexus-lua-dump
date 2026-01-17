local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')

local l10n = core.l10n('MagicWindowExtender')
local versionString = "1.2.3"

-- Settings page
I.Settings.registerPage {
    key = 'MagicWindowExtender',
    l10n = 'MagicWindowExtender',
    name = 'ConfigTitle',
    description = l10n('ConfigSummary'):gsub('%%{version}', versionString),
}

input.registerAction {
    key = 'MWE_ToggleMagicWindow1',
    type = input.ACTION_TYPE.Boolean,
    l10n = 'MagicWindowExtender',
    defaultValue = false,
}

input.registerAction {
    key = 'MWE_ToggleMagicWindow2',
    type = input.ACTION_TYPE.Boolean,
    l10n = 'MagicWindowExtender',
    defaultValue = false,
}

I.Settings.registerGroup  {
    key = 'Settings/MagicWindowExtender/1_Keybinds',
    page = 'MagicWindowExtender',
    l10n = 'MagicWindowExtender',
    name = 'ConfigCategoryKeybinds',
    permanentStorage = true,
    settings = {
        {
            key = 'k_ToggleMagicWindow1',
            renderer = 'inputBinding',
            name = 'ToggleMagicWindow1',
            default = 'MWE_ToggleMagicWindow1',
            argument = {
                key = 'MWE_ToggleMagicWindow1',
                type = 'action',
            }
        },
        {
            key = 'k_ToggleMagicWindow2',
            renderer = 'inputBinding',
            name = 'ToggleMagicWindow2',
            default = 'MWE_ToggleMagicWindow2',
            argument = {
                key = 'MWE_ToggleMagicWindow2',
                type = 'action',
            }
        }
    }
}
I.Settings.registerGroup {
    key = 'Settings/MagicWindowExtender/2_WindowOptions',
    page = 'MagicWindowExtender',
    l10n = 'MagicWindowExtender',
    name = 'ConfigCategoryWindowOptions',
    description = 'RequiresReload',
    permanentStorage = true,
    settings = {
        {
            key = 'b_ReplaceVanillaWindow',
            renderer = 'checkbox',
            name = 'ReplaceVanillaWindow',
            description = 'ReplaceVanillaWindowDesc',
            default = true,
        },
        {
            key = 'i_FontSize',
            renderer = 'number',
            name = 'FontSize',
            description = 'FontSizeDesc',
            default = 16,
            argument = {
                integer = true,
                min = 12,
                max = 18,
            }
        },
        {
            key = 'b_MagicWindowPinned',
            renderer = 'checkbox',
            name = 'MagicWindowPinned',
            default = false,
        },
        {
            key = 'f_MagicWindowX',
            renderer = 'number',
            name = 'MagicWindowX',
            default = 0.63,
            argument = {
                min = 0,
                max = 1,
            }
        },
        {
            key = 'f_MagicWindowY',
            renderer = 'number',
            name = 'MagicWindowY',
            default = 0.39,
            argument = {
                min = 0,
                max = 1,
            }
        },
        {
            key = 'f_MagicWindowW',
            renderer = 'number',
            name = 'MagicWindowW',
            default = 0.36,
            argument = {
                min = 0,
                max = 1,
            }
        },
        {
            key = 'f_MagicWindowH',
            renderer = 'number',
            name = 'MagicWindowH',
            default = 0.51,
            argument = {
                min = 0,
                max = 1,
            }
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/MagicWindowExtender/3_Tweaks',
    page = 'MagicWindowExtender',
    l10n = 'MagicWindowExtender',
    name = 'ConfigCategoryTweaks',
    description = 'RequiresReload',
    permanentStorage = true,
    settings = {
        {
            key = 'b_SpellIcons',
            renderer = 'checkbox',
            name = 'TweakSpellIcons',
            description = 'TweakSpellIconsDesc',
            default = true,
        },
        {
            key = 'b_SchoolFilter',
            renderer = 'checkbox',
            name = 'TweakSchoolFilter',
            description = 'TweakSchoolFilterDesc',
            default = true,
        },
        {
            key = 'b_ColoredSchoolIcons',
            renderer = 'checkbox',
            name = 'TweakColoredSchoolIcons',
            description = 'TweakColoredSchoolIconsDesc',
            default = true,
        },
        {
            key = 'b_ListEditing',
            renderer = 'checkbox',
            name = 'TweakListEditing',
            description = 'TweakListEditingDesc',
            default = true,
        },
        {
            key = 'b_SmartSpellCycling',
            renderer = 'checkbox',
            name = 'TweakSmartSpellCycling',
            description = 'TweakSmartSpellCyclingDesc',
            default = true,
        },
        {
            key = 'b_SeparatePinnedSpells',
            renderer = 'checkbox',
            name = 'TweakSeparatePinnedSpells',
            description = 'TweakSeparatePinnedSpellsDesc',
            default = true,
        },
        {
            key = 'b_PinnedSpellIcons',
            renderer = 'checkbox',
            name = 'TweakPinnedSpellIcons',
            description = 'TweakPinnedSpellIconsDesc',
            default = false,
        },
        {
            key = 'b_MarkUsedPowers',
            renderer = 'checkbox',
            name = 'TweakMarkUsedPowers',
            description = 'TweakMarkUsedPowersDesc',
            default = true,
        },
        {
            key = 'b_SearchBarOnTop',
            renderer = 'checkbox',
            name = 'TweakSearchBarOnTop',
            description = 'TweakSearchBarOnTopDesc',
            default = false,
        },
        {
            key = 'b_DeleteButtonIcon',
            renderer = 'checkbox',
            name = 'TweakDeleteButtonIcon',
            description = 'TweakDeleteButtonIconDesc',
            default = true,
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/MagicWindowExtender/4_ModIntegration',
    page = 'MagicWindowExtender',
    l10n = 'MagicWindowExtender',
    name = 'ConfigCategoryModIntegration',
    description = 'RequiresReload',
    permanentStorage = true,
    settings = {
        {
            key = 'b_InterfaceReimagined',
            renderer = 'checkbox',
            name = 'InterfaceReimagined',
            description = 'InterfaceReimaginedDesc',
            default = false,
        },
        {
            key = 's_CustomSpellIconStyle',
            renderer = 'select',
            name = 'CustomSpellIconStyle',
            description = 'CustomSpellIconStyleDesc',
            default = 'CustomSpellIconStyle_Flat',
            argument = {
                l10n = 'MagicWindowExtender',
                items = {
                    'CustomSpellIconStyle_Flat',
                    'CustomSpellIconStyle_Textured',
                }
            }
        }
    },
}

I.Settings.registerGroup {
    key = 'Settings/MagicWindowExtender/5_Misc',
    page = 'MagicWindowExtender',
    l10n = 'MagicWindowExtender',
    name = 'ConfigCategoryMisc',
    permanentStorage = true,
    settings = {
        {
            key = 'b_ShowControllerWarning',
            renderer = 'checkbox',
            name = 'ShowControllerWarning',
            description = 'ShowControllerWarningDesc',
            default = true,
        }
    },
}