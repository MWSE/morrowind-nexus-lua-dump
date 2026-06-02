local I     = require('openmw.interfaces')
local input = require('openmw.input')

I.Settings.registerPage({
    key         = 'PARKOURY',
    l10n        = 'parkour',
    name        = 'Parkour and acrobatics',
    description = 'Settings to adjust parkour and acrobatics',
})

input.registerAction {
    key          = 'enparkour',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'parkour',
    name         = 'Toggle parkour mode',
    description  = 'Key for parkour mode',
    defaultValue = false,
}

I.Settings.registerGroup({
    key              = 'Settings_tt_parkour',
    page             = 'PARKOURY',
    l10n             = 'parkour',
    name             = 'Parkour and acrobatics',
    permanentStorage = true,
    settings = {
        {
            key         = 'enparkour',
            renderer    = 'inputBinding',
            name        = 'Toggle parkour mode',
            description = 'Hold to enable parkour mode (vault over obstacles instead of stopping)',
            default     = 'Alt',
            argument    = { type = 'action', key = 'enparkour' },
        },
    },
})

return {}
