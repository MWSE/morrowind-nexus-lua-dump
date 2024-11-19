local I = require('openmw.interfaces')
local async = require('openmw.async')
local input = require('openmw.input')
local ui = require('openmw.ui')

local version = '1.1'

-- Shamelessly stolen from https://modding-openmw.gitlab.io/light-hotkey/
I.Settings.registerRenderer(
'Transmog/inputKeySelection',
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
    key = 'Transmog',
    l10n = 'Transmog',
    name = 'Transmog - Glamour - Outfits',
    description = ('Make one weapon or armor/clothing piece look like another. Version: %s'):format(version),
}
I.Settings.registerGroup {
    key = 'SettingsPlayerTransmog',
    page = 'Transmog',
    l10n = 'Transmog',
    name = 'Keybindings',
    description = 'Keybindings for Transmog - Glamour - Outfits',
    permanentStorage = true,
    settings = {
        {
            key = 'transmogMenuKey',
            name = 'Activation Key',
            description = 'Key to press to activate item selection',
            default = input.KEY.G,
            renderer = 'Transmog/inputKeySelection',
        }
    }
}
