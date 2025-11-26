local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')

local l10n = core.l10n('StatsWindow')
local versionString = "1.2.3"

-- Settings page
I.Settings.registerPage {
    key = 'StatsWindow',
    l10n = 'StatsWindow',
    name = 'ConfigTitle',
    description = l10n('ConfigSummary'):gsub('%%{version}', versionString),
}

input.registerAction {
    key = 'SW_ToggleStatsWindow1',
    type = input.ACTION_TYPE.Boolean,
    l10n = 'StatsWindow',
    defaultValue = false,
}

input.registerAction {
    key = 'SW_ToggleStatsWindow2',
    type = input.ACTION_TYPE.Boolean,
    l10n = 'StatsWindow',
    defaultValue = false,
}

I.Settings.registerGroup  {
    key = 'Settings/StatsWindow/1_Keybinds',
    page = 'StatsWindow',
    l10n = 'StatsWindow',
    name = 'ConfigCategoryKeybinds',
    permanentStorage = true,
    settings = {
        {
            key = 'k_ToggleStatsWindow1',
            renderer = 'inputBinding',
            name = 'ToggleStatsWindow1',
            default = 'None1',
            argument = {
                key = 'SW_ToggleStatsWindow1',
                type = 'action',
            }
        },
        {
            key = 'k_ToggleStatsWindow2',
            renderer = 'inputBinding',
            name = 'ToggleStatsWindow2',
            default = 'None2',
            argument = {
                key = 'SW_ToggleStatsWindow2',
                type = 'action',
            }
        }
    }
}
I.Settings.registerGroup {
    key = 'Settings/StatsWindow/2_WindowOptions',
    page = 'StatsWindow',
    l10n = 'StatsWindow',
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
            key = 's_PaneArrangement',
            renderer = 'select',
            name = 'PaneArrangement',
            description = 'PaneArrangementDesc',
            default = 'Panes_Auto',
            argument = {
                l10n = 'StatsWindow',
                items = {
                    'Panes_SideBySide',
                    'Panes_Stacked',
                    'Panes_Auto',
                }
            }
        },
        {
            key = 'f_LeftPaneMinWidth',
            renderer = 'number',
            name = 'LeftPaneMinWidth',
            description = 'LeftPaneMinWidthDesc',
            default = 212,
            argument = {
                min = 0,
            },
        },
        {
            key = 'f_RightPaneMinWidth',
            renderer = 'number',
            name = 'RightPaneMinWidth',
            description = 'RightPaneMinWidthDesc',
            default = 160,
            argument = {
                min = 0,
            },
        },
        {
            key = 'f_LeftPaneRatio',
            renderer = 'number',
            name = 'LeftPaneRatio',
            description = 'LeftPaneRatioDesc',
            default = 0.44,
            argument = {
                min = 0,
                max = 1,
            }
        },
        {
            key = 'b_StatsPinned',
            renderer = 'checkbox',
            name = 'StatWindowPinned',
            default = false,
        },
        {
            key = 'f_StatsX',
            renderer = 'number',
            name = 'StatWindowX',
            default = 0.015,
            argument = {
                min = 0,
                max = 1,
            }
        },
        {
            key = 'f_StatsY',
            renderer = 'number',
            name = 'StatWindowY',
            default = 0.015,
            argument = {
                min = 0,
                max = 1,
            }
        },
        {
            key = 'f_StatsW',
            renderer = 'number',
            name = 'StatWindowW',
            default = 0.4275,
            argument = {
                min = 0,
                max = 1,
            }
        },
        {
            key = 'f_StatsH',
            renderer = 'number',
            name = 'StatWindowH',
            default = 0.45,
            argument = {
                min = 0,
                max = 1,
            }
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/StatsWindow/3_Tweaks',
    page = 'StatsWindow',
    l10n = 'StatsWindow',
    name = 'ConfigCategoryTweaks',
    description = 'RequiresReload',
    permanentStorage = true,
    settings = {
        {
            key = 'b_RestyleBountyAndRep',
            renderer = 'checkbox',
            name = 'RestyleBountyAndRep',
            description = 'RestyleBountyAndRepDesc',
            default = false,
        },
        {
            key = 'b_HideZeroBounty',
            renderer = 'checkbox',
            name = 'HideZeroBounty',
            description = 'HideZeroBountyDesc',
            default = false,
        },
        {
            key = 'b_FactionAndRepOnLeft',
            renderer = 'checkbox',
            name = 'FactionAndRepOnLeft',
            description = 'FactionAndRepOnLeftDesc',
            default = false,
        },
        {
            key = 'i_MaxFactionRepLines',
            renderer = 'number',
            name = 'MaxFactionRepLines',
            description = 'MaxFactionRepLinesDesc',
            default = 6,
            argument = {
                integer = true,
                min = 0,
            },
        },
        {
            key = 'b_BirthsignOnLeft',
            renderer = 'checkbox',
            name = 'BirthsignOnLeft',
            description = 'BirthsignOnLeftDesc',
            default = false,
        },
        {
            key = 'b_ShowFactionRankInList',
            renderer = 'select',
            name = 'ShowFactionRankInList',
            description = 'ShowFactionRankInListDesc',
            default = 'ShowFactionRankInList_Off',
            argument = {
                l10n = 'StatsWindow',
                items = {
                    'ShowFactionRankInList_Off',
                    'ShowFactionRankInList_Number',
                    'ShowFactionRankInList_Title',
                }
            }
        },
        {
            key = 'b_ShowFactionRepInTooltip',
            renderer = 'checkbox',
            name = 'ShowFactionRepInTooltip',
            description = 'ShowFactionRepInTooltipDesc',
            default = false,
        },
        {
            key = 's_HouseNameDisplay',
            renderer = 'select',
            name = 'HouseNameDisplay',
            description = 'HouseNameDisplayDesc',
            default = 'HouseNameDisplay_Full',
            argument = {
                l10n = 'StatsWindow',
                items = {
                    'HouseNameDisplay_Full',
                    'HouseNameDisplay_Partial',
                    'HouseNameDisplay_Minimal',
                }
            }
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/StatsWindow/4_ModIntegration',
    page = 'StatsWindow',
    l10n = 'StatsWindow',
    name = 'ConfigCategoryModIntegration',
    description = 'RequiresReload',
    permanentStorage = true,
    settings = {
        {
            key = 'b_EnableTDFactions',
            renderer = 'checkbox',
            name = 'EnableTDFactions',
            description = 'EnableTDFactionsDesc',
            default = true,
        },
        {
            key = 'b_EnableTDReputation',
            renderer = 'checkbox',
            name = 'EnableTDReputation',
            description = 'EnableTDReputationDesc',
            default = true,
        },
        {
            key = 'b_InterfaceReimagined',
            renderer = 'checkbox',
            name = 'InterfaceReimagined',
            description = 'InterfaceReimaginedDesc',
            default = false,
        }
    },
}

I.Settings.registerGroup {
    key = 'Settings/StatsWindow/5_Misc',
    page = 'StatsWindow',
    l10n = 'StatsWindow',
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