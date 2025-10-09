local I = require('openmw.interfaces')
local async = require('openmw.async')
local input = require('openmw.input')
local ui = require('openmw.ui')
local core = require('openmw.core')

local version = '1.1'

I.Settings.registerRenderer(
'TrainedLungs/inputKeySelection',
function(value, set)
    local name = 'No Key Set'
    if value then
        name = input.getKeyName(value)
    end
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textEditLine,
                        props = {
                            text = name,
                        },
                        events = {
                            keyPress = async:callback(function(e)
                                if e.code == input.KEY.Escape then return end
                                set(e.code)
                            end),
                        },
                    },
                },
            },
        },
    }
end
)


I.Settings.registerPage {
    key = 'TrainedLungs',
    l10n = 'TrainedLungs',
    name = 'TrainedLungs',
    description = "settings_description"
}

I.Settings.registerGroup {
    key = 'SettingsPlayerTrainedLungs',
    page = 'TrainedLungs',
    l10n = 'TrainedLungs',
    name = 'Settings',
    description = 'settings_tl',
    permanentStorage = true,
    settings = {
        {
            key = 'trainedLungsMenuKey',
            name = 'activation_key',
            --description = 'Key to press to hold your breath',
            default = input.KEY.H,
            renderer = 'TrainedLungs/inputKeySelection',
        },
        {
            key = 'trainedLungsEnableForArgonians',
            name = 'enable_args',
            --description = 'Enable for argonians',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'trainedLungsEnableSound',
            name = 'enable_snd',
            --description = 'Enable sound',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'trainedLungsEnableTimer',
            name = 'enable_tmr',
            --description = 'Enable sound',
            default = false,
            renderer = 'checkbox',
        },    }
}