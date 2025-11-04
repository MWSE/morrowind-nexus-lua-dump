local util = require('openmw.util')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

local debugTextEl

local function setDebugText(text)
        if not debugTextEl then
                debugTextEl = ui.create({
                        layer = 'Notification',
                        template = I.MWUI.templates.textNormal,
                        props = {
                                text = 'testing testing',
                                textSize = 16,
                                textShadow = true,
                                multiline = true,
                                position = util.vector2(10, 10),
                        }
                })
        end

        debugTextEl.layout.props.text = tostring(text)
        debugTextEl:update()
end

return {
        setDebugText = setDebugText,
}
