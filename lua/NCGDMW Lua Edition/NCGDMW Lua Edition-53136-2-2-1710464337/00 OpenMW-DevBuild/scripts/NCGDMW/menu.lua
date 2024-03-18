local async = require('openmw.async')
local input = require('openmw.input')
local I = require("openmw.interfaces")
-- THANKS:
-- https://gitlab.com/urm-openmw-mods/camerahim/-/blob/1a12e3f8c902291d5629f2d8cc8649eac315533a/Data%20Files/scripts/CameraHIM/settings.lua#L23-35
I.Settings.registerRenderer(
    'NCGDMW_hotkey', function(value, set)
        return {
            template = I.MWUI.templates.textEditLine,
            props = {
                text = value and input.getKeyName(value) or '',
            },
            events = {
                keyPress = async:callback(function(e)
                        set(e.code)
                end)
            }
        }
end)
