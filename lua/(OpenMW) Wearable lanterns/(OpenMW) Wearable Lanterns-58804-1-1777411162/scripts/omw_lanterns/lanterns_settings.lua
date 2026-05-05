local I     = require('openmw.interfaces')
local input = require('openmw.input')
local ui = require('openmw.ui')
local async = require('openmw.async')

I.Settings.registerPage({
    key         = 'WEARABLELAMP',
    l10n        = 'wearlanterns',
    name        = 'Wearable lanterns',
    description = 'Settings to toggle and change lanterns',
})

input.registerAction {
    key          = 'wearlamp',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'wearlanterns',
    name         = 'Toggle lantern',
    description  = 'Key to toggle lantern',
    defaultValue = false,
}

input.registerAction {
    key          = 'changelamp',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'wearlanterns',
    name         = 'Change lantern',
    description  = 'Key to select lantern',
    defaultValue = false,
}

I.Settings.registerGroup({
    key              = 'wear_lanterns',   
    page             = 'WEARABLELAMP',             
    l10n             = 'wearlanterns',
    name             = 'lanterns settings',
    permanentStorage = true,
    settings = {
        {
            key         = 'wearlamp',
            renderer    = 'inputBinding',
            name        = 'Toggle lantern',
            description = 'Key to toggle lantern',
            default     = 'A',
            argument    = { type = 'action', key = 'wearlamp' },
        },
        {
            key         = 'changelamp',
            renderer    = 'inputBinding',
            name        = 'Change lantern',
            description = 'Key to select lantern',
            default     = 'B',
            argument    = { type = 'action', key = 'changelamp' },
        },
    },
})

return
