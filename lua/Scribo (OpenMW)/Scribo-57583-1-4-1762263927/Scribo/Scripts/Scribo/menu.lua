local I = require('openmw.interfaces')
local async = require('openmw.async')
local input = require('openmw.input')
local ui = require('openmw.ui')
local core = require('openmw.core')

local version = '1.0'

I.Settings.registerPage {
    key = 'Scribo',
    l10n = 'Scribo',
    name = 'Scribo',
    description = "settings_description"
}

I.Settings.registerGroup {
    key = 'SettingsPlayerScribo',
    page = 'Scribo',
    l10n = 'Scribo',
    name = 'Settings',
    description = 'scrbSettings',
    permanentStorage = true,
    settings = {
        {
        key = 'scrbKey',
        name = 'srcbKeyName',
        default = "Ctrl",

        argument = {
            l10n = 'Scribo',
            items = {"Shift", "Ctrl", "Alt"}
        },
        renderer = 'select'
    },{
        key = 'scrbDisableEdit',
        name = 'scrbDisableEditName',
        default = false,
        renderer = 'checkbox'
    },{
        key = 'scrbUncontrolEdit',
        name = 'scrbUncontrolEditName',
        default = false,
        renderer = 'checkbox'
    },{
        key = 'scrbEditAsHTML',
        name = 'scrbEditAsHTMLName',
        default = false,
        renderer = 'checkbox'
    },
}

}
