local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')

local l10n = core.l10n('ShowGoldAmount')
local versionString = "1.0.0"

-- Settings page
I.Settings.registerPage {
    key = 'ShowGoldAmount',
    l10n = 'ShowGoldAmount',
    name = 'ConfigTitle',
    description = l10n('ConfigSummary'):gsub('%%{version}', versionString),
}

I.Settings.registerGroup {
    key = 'Settings/ShowGoldAmount/ClientOptions',
    page = 'ShowGoldAmount',
    l10n = 'ShowGoldAmount',
    name = 'ConfigCategoryClientOptions',
    permanentStorage = true,
    settings = {        
        {
            key = 'n_InfoWindowOffsetXRelative',
            renderer = 'number',
            name = 'InfoWindowOffsetXRelative',
            argument = {
                min = 0.0,
                max = 1.0,
            },
            default = 0.01,
        },
        {
            key = 'n_InfoWindowOffsetYRelative',
            renderer = 'number',
            name = 'InfoWindowOffsetYRelative',
            argument = {
                min = 0.0,
                max = 1.0,
            },
            default = 0.985,
        },
        {
            key = 'n_TextSize',
            renderer = 'number',
            name = 'TextSize',
            argument = {
                min = 1.0,
                max = 50.0,
            },
            default = 20.0,
        },
        {
            key = 's_GoldName',
            renderer = 'select',
            name = 'GoldName',
            argument = {
                l10n = 'showGoldAmount',
                items = {
                    'Gold',
                    'Septim',
                    'Drake',
                    'None'
                }
            },
            default = 'Gold',
        },
        {
            key = 'b_ShowGoldAmountOnGamePaused',
            renderer = 'checkbox',
            name = 'ShowGoldAmountOnGamePaused',
            description = 'ShowGoldAmountOnGamePausedDesc',
            default = false,
        },
    },
}