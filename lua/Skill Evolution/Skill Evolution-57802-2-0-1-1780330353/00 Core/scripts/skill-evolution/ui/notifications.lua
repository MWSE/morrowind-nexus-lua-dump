local core = require('openmw.core')
local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local util = require('openmw.util')

local hudLayerSize = ui.layers[ui.layers.indexOf("HUD")].size
local notifs = {}
local notifCount = 0
local lastFrameTime = core.getRealTime()

local module = {}

local function padding(horizontal, vertical)
    return { props = { size = util.vector2(horizontal, vertical) } }
end

module.notify = function(message)
    notifCount = notifCount + 1
    local center = hudLayerSize / 2
    center = util.vector2(center.x, center.y + 40 * (notifCount % 10 - 5))
    local notif = {
        layer = "Notification",
        template = I.MWUI.templates.boxTransparent,
        props = {
            position = center,
            anchor = util.vector2(1, 1)
        },
        content = ui.content {
            padding(0, 20),
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                content = ui.content {
                    padding(10, 0),
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = { text = message, multiline = true, textSize = 16, textAlignH = ui.ALIGNMENT.Center },
                    },
                    padding(10, 0),
                }
            },
            padding(0, 20),
        }
    }
    local notifUi = ui.create(notif)
    table.insert(notifs, { time = 0, pos = notifUi.layout.props.position, ui = notifUi })
end

module.onFrame = function()
    local frameTime = core.getRealTime()
    local deltaTime = frameTime - lastFrameTime
    lastFrameTime = frameTime
    local i = 1
    while i <= #notifs do
        local notif = notifs[i]
        notif.time = notif.time + deltaTime
        notif.ui.layout.props.position = util.vector2(notif.pos.x - (100 * notif.time), notif.ui.layout.props.position.y)
        notif.ui:update()
        if notif.ui.layout.props.position.x < 0 then
            table.remove(notifs, i)
            notif.ui:destroy()
        else
            i = i + 1
        end
    end
end

return module
