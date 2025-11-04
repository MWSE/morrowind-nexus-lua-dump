local I = require('openmw.interfaces')
local util = require('openmw.util')
local async = require('openmw.async')
local ui = require('openmw.ui')

I.Settings.registerRenderer('text', function(value, set, arg)
        return {
                type = ui.TYPE.TextEdit,
                template = I.MWUI.templates.borders,

                props = {
                        size = util.vector2(350, 200),
                        text = tostring(value),
                        textSize = 14,
                        textColor = util.color.hex('ffffff'),
                        multiline = true,
                        textAlignV = ui.ALIGNMENT.Start,
                        textAlignH = ui.ALIGNMENT.Start,
                },
                events = {
                        textChanged = async:callback(function(s) set(tostring(s)) end),
                },
        }
end)
