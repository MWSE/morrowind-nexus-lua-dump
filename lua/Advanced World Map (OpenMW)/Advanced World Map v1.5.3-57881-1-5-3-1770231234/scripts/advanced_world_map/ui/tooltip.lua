local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local core = require('openmw.core')
local time = require('openmw_aux.time')
local UI = require('openmw.interfaces').UI
local customTemplates = require("scripts.advanced_world_map.ui.templates")
local uiUtils = require("scripts.advanced_world_map.ui.utils")

local this = {}

this.lastTooltip = nil

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


function this.create(coord, parent, layoutContent)
    local position, anchor = this.calcTooltipPosAnchor(coord.position)

    this.destroyLast()
    if not layoutContent or #layoutContent == 0 then return end

    local tooltipLayout = {
        template = customTemplates.boxSolid,
        layer = "Notification",
        name = "AdvWMap:tooltip",
        props = {
            position = position,
            anchor = anchor,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = layoutContent,
            }
        }
    }

    local tooltip = ui.create(tooltipLayout)
    parent.userData["tooltip"] = tooltip
    this.lastTooltip = tooltip

    if core.isWorldPaused() then
        local timer = async:newUnsavableSimulationTimer(0.1, function ()
            if not parent.userData.tooltip then return end
            local tooltipHandler = parent.userData.tooltip
            parent.userData.tooltip = nil
            this.lastTooltip = nil
            tooltipHandler:destroy()
        end)
    else
        local timer
        timer = time.runRepeatedly(function ()
            if UI.getMode() == nil then
                timer()
                if not parent.userData.tooltip then return end
                local tooltipHandler = parent.userData.tooltip
                parent.userData.tooltip = nil
                this.lastTooltip = nil
                tooltipHandler:destroy()
            end
        end, 0.2)
    end

    return true
end


function this.move(coord, parent)
    if not parent.userData then parent.userData = {} end

    if not parent.userData.tooltip or not parent.userData.tooltip.layout then
        parent.userData.tooltip = nil
        return
    end

    local position, anchor = this.calcTooltipPosAnchor(coord.position)

    local props = parent.userData.tooltip.layout.props

    props.position, props.anchor = position, anchor

    parent.userData.tooltip:update()
end


---@return boolean? new
function this.createOrMove(coord, parent, layoutContent)
    if not parent.userData then parent.userData = {} end

    if not parent.userData.tooltip and this.create(coord, parent, layoutContent) then
        return true
    end

    this.move(coord, parent)
end


function this.destroy(parent)
    if not parent.userData or not parent.userData.tooltip then return end
    local tooltipHandler = parent.userData.tooltip
    parent.userData.tooltip = nil
    tooltipHandler:destroy()
end


function this.isExists(parent)
    return parent and parent.userData and parent.userData.tooltip and parent.userData.tooltip.layout and true or false
end


function this.get(parent)
    return parent and parent.userData and parent.userData.tooltip
end


function this.destroyLast()
    if this.lastTooltip and this.lastTooltip.layout then
        this.lastTooltip:destroy()
    end
    this.lastTooltip = nil
end


return this