local core = require('openmw.core')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local async = require('openmw.async')


local capOptionGroup = 'SettingsAttributeCapOption'

I.Settings.registerPage{
    key = 'myLion',
    l10n = 'myLion',
    name = 'SettingTitle',
    description = 'PageDescription',
}


I.Settings.registerGroup{
    key = capOptionGroup,
    page = 'myLion',
    l10n = 'myLion',
    name = 'Settings',
    description = 'GroupDescription',
    permanentStorage = false,
    settings = {
        {
            key = 'isLiteralCap',
            renderer = 'checkbox',
            name = 'BoxName',
            description = 'BoxDescription',
            default = false,
        },
        {
            key = 'attCap',
            renderer = 'number',
            name = 'AttCapName',
            default = 50,
        },
        {
            key = 'speedAttCap',
            renderer = 'number',
            name = 'SpeedAttCapName',
            default = 200,
        },
    },
}




local capSetting = storage.playerSection(capOptionGroup)
