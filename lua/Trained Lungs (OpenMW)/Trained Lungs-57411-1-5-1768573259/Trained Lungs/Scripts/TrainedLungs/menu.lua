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
    description = "tlung_settings_description"
}

I.Settings.registerGroup {
    key = 'settingsPlayerTrainedLungs',
    page = 'TrainedLungs',
    l10n = 'TrainedLungs',
    name = 'tlung_settings',
    permanentStorage = true,
    settings = {
        {
            key = 'trainedLungsMenuKey',
            name = 'tlung_activation_key',
            --description = 'Key to press to hold your breath',
            default = input.KEY.H,
            renderer = 'TrainedLungs/inputKeySelection',                 
        },
        {
            key = 'trainedLungsMode',
            name = 'tlung_mode',
            default = "tlung_expert",
	        description = 'tlung_mode_description',
            argument = {
                l10n = 'TrainedLungs',
                items = {"tlung_adept", "tlung_expert"}
            },
            renderer = 'select'
        },      
        {
            key = 'trainedLungsFatigueMode',
            name = 'tlung_fatigue_mode',
            default = "tlung_hardcore",
	        description = 'tlung_fatigue_mode_description',
            argument = {
                l10n = 'TrainedLungs',
                items = {"tlung_standard", "tlung_hardcore"}
            },
            renderer = 'select'
        },       
        {
            key = 'trainedLungsEnableSound',
            name = 'tlung_enable_snd',
            --description = 'Enable sound',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'trainedLungsEnableTimer',
            name = 'tlung_enable_tmr',
            default = false,
            renderer = 'checkbox',
	},
        {
	    key = 'trainedLungsEnableForArgonians',
            name = 'tlung_enable_args',
            default = false,
            renderer = 'checkbox',
        },    }
}