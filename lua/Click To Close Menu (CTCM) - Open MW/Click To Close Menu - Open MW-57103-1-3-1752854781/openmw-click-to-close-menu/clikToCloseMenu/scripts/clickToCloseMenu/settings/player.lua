local core = require('openmw.core')
local I = require('openmw.interfaces')

local l10n = core.l10n('ClickToCloseMenu')
local versionString = "1.0.0"

-- Settings page
I.Settings.registerPage {
    key = 'ClickToCloseMenu',
    l10n = 'ClickToCloseMenu',
    name = 'ConfigTitle',
    description = l10n('ConfigSummary'):gsub('%%{version}', versionString),
}

I.Settings.registerGroup {
    key = 'Settings/ClickToCloseMenu/ClientOptions',
    page = 'ClickToCloseMenu',
    l10n = 'ClickToCloseMenu',
    name = 'ConfigCategoryClientOptions',
    permanentStorage = true,
    settings = {                
        {
            key = 's_Click',
            renderer = 'select',
            name = 'Click',
            argument = {
                l10n = 'ClickToCloseMenu',
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