local core = require('openmw.core')
local I = require('openmw.interfaces')

local l10n = core.l10n('ClickToPrepareWeapon')
local versionString = "1.0.0"

-- Settings page
I.Settings.registerPage {
    key = 'ClickToPrepareWeapon',
    l10n = 'ClickToPrepareWeapon',
    name = 'ConfigTitle',
    description = l10n('ConfigSummary'):gsub('%%{version}', versionString),
}

I.Settings.registerGroup {
    key = 'Settings/ClickToPrepareWeapon/ClientOptions',
    page = 'ClickToPrepareWeapon',
    l10n = 'ClickToPrepareWeapon',
    name = 'ConfigCategoryClientOptions',
    permanentStorage = true,
    settings = {                
        {
            key = 's_ClickPrepare',
            renderer = 'select',
            name = 'ClickPrepare',
            argument = {
                l10n = 'ClickToPrepareWeapon',
                items = {
                    'Right',
                    'Left',
                    'Middle',
                    'None'
                }
            },
            default = 'Left',
        },
        {
            key = 's_ClickSheath',
            renderer = 'select',
            name = 'ClickSheath',
            argument = {
                l10n = 'ClickToPrepareWeapon',
                items = {
                    'Right',
                    'Left',
                    'Middle',
                    'None'
                }
            },
            default = 'Right',
        }      
    },
}