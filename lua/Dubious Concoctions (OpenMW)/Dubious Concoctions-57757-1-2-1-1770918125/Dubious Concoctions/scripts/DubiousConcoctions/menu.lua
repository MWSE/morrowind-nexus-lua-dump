local I = require('openmw.interfaces')
local async = require('openmw.async')
local input = require('openmw.input')
local ui = require('openmw.ui')
local core = require('openmw.core')

local version = '1.1'

I.Settings.registerPage {
    key = 'DubiousConcoctions',
    l10n = 'DubiousConcoctions',
    name = 'DubiousConcoctions',
    description = "settings_description"
}

I.Settings.registerGroup {
    key = 'SettingsPlayerDubiousConcoctions',
    page = 'DubiousConcoctions',
    l10n = 'DubiousConcoctions',
    name = 'DubiousConcoctionsName',
    description = '',
    permanentStorage = true,
    settings = { {
        key = 'dcDialog',
        name = 'dcDialogName',
        description = '',
        default = true,
        renderer = 'checkbox'
    }, }
}
