local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local core = require('openmw.core')
local time = require('openmw_aux.time')
local UI = require('openmw.interfaces').UI
local customTemplates = require("scripts.advanced_world_map.ui.templates")
local uiUtils = require("scripts.advanced_world_map.ui.utils")
local realTimer = require("scripts.advanced_world_map.realTimer")

local this = {}

this.lastTooltip = nil
this.suppress = false

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


function this.create(coord, parent, layoutContent, delay, suppressNew)
    if this.suppress then return end
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
            visible = delay == nil and true or false,
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
    parent.userData["suppressNewTooltips"] = suppressNew
    this.suppress = suppressNew or false
    this.lastTooltip = tooltip

    if delay then
        realTimer.newTimer(delay, function ()
            if tooltip.layout then
                tooltip.layout.props.visible = true
                tooltip:update()
            end
        end)
    end

    if core.isWorldPaused() then
        local timer = async:newUnsavableSimulationTimer(0.01, function ()
            if parent and parent.userData then
                parent.userData.tooltip = nil
            end
            if not tooltip.layout then return end
            this.lastTooltip = nil
            this.suppress = false
            tooltip:destroy(true)
        end)
    else
        local timer
        timer = time.runRepeatedly(function ()
            if UI.getMode() == nil then
                timer()
                if parent and parent.userData then
                    parent.userData.tooltip = nil
                end
                if not tooltip.layout then return end
                this.lastTooltip = nil
                this.suppress = false
                tooltip:destroy(true)
            end
        end, 0.1)
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
function this.createOrMove(coord, parent, layoutContent, delay)
    if not parent.userData then parent.userData = {} end

    if not parent.userData.tooltip and this.create(coord, parent, layoutContent, delay) then
        return true
    end

    this.move(coord, parent)
end


function this.destroy(parent, force)
    if not parent.userData or not parent.userData.tooltip then return end
    if not force and parent.userData.suppressNewTooltips then return end
    local tooltipHandler = parent.userData.tooltip
    parent.userData.tooltip = nil
    parent.userData.suppressNewTooltips = nil
    this.suppress = false
    this.lastTooltip = nil
    local co = coroutine.create(function (...)
        tooltipHandler:destroy()
    end)
    coroutine.resume(co)
end


function this.isExists(parent)
    return parent and parent.userData and parent.userData.tooltip and parent.userData.tooltip.layout and true or false
end


function this.get(parent)
    return parent and parent.userData and parent.userData.tooltip
end


function this.destroyLast(force)
    if this.lastTooltip and this.lastTooltip.layout then
        if not this.suppress or force then
            this.lastTooltip:destroy()
        end
    else
        this.lastTooltip = nil
    end
end


return this