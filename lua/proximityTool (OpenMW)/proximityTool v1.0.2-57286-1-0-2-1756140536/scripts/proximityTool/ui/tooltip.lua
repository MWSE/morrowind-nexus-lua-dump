local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')

local safeContainers = require("scripts.proximityTool.ui.safeContainer")
local uiUtils = require("scripts.proximityTool.ui.utils")

local this = {}

function this.calcTooltipPosAnchor(cursorPos)
    local screenSize = uiUtils.getScaledScreenSize()

    local halfWidth = screenSize.x / 2
    local halfHeight = screenSize.y / 2

    local anchorX = cursorPos.x > halfWidth and 1 or 0
    local anchorY = cursorPos.y > halfHeight and 1 or 0
    local anchor = util.vector2 (anchorX, anchorY)

    local posX = cursorPos.x
    if anchorX <= 0 and anchorY <= 0 then
        posX = posX + 30
    end
    local tooltipPos = util.vector2(posX, cursorPos.y)

    return tooltipPos, anchor
end

function this.createOrMove(coord, parent, layoutContent)
    if not parent.userData then parent.userData = {} end

    local position, anchor = this.calcTooltipPosAnchor(coord.position)

    if not parent.userData.tooltip or not parent.userData.tooltip.valid then
        if not layoutContent then return end
        local tooltipHandler = safeContainers.new("tooltip")

        parent.userData["tooltip"] = tooltipHandler

        local tooltipLayout = {
            template = I.MWUI.templates.boxSolid,
            layer = "Notification",
            name = "proximityTool:tooltip",
            props = {
                position = position,
                anchor = anchor,
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = false,
                    },
                    content = layoutContent,
                }
            }
        }

        tooltipHandler:create(tooltipLayout)
        async:newUnsavableSimulationTimer(0.1, function ()
            tooltipHandler:destroy()
        end)

        return
    end


    if not parent.userData.tooltip then return end
    local tooltipHandler = parent.userData.tooltip
    if not tooltipHandler.element then return end

    local props = tooltipHandler.element.layout.props

    props.position, props.anchor = position, anchor

    tooltipHandler:update()
end


function this.destroy(parent)
    if not parent.userData or not parent.userData.tooltip then return end
    local tooltipHandler = parent.userData.tooltip
    parent.userData.tooltip = nil
    tooltipHandler:destroy()
end


function this.isExists(parent)
    return parent and parent.userData and parent.userData.tooltip and parent.userData.tooltip.valid
end


return this