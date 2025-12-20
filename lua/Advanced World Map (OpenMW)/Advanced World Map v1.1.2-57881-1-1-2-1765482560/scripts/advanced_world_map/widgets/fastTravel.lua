local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local playerRef = require("openmw.self")
local nearby = require("openmw.nearby")
local async = require('openmw.async')

local commonData = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.configLib")
local discoveredLocs = require("scripts.advanced_world_map.discoveredLocations")
local mapDataHandler = require("scripts.advanced_world_map.mapDataHandler")
local localStorage = require("scripts.advanced_world_map.storage.localStorage")

local uiUtils = require("scripts.advanced_world_map.ui.utils")
local eventSys = require("scripts.advanced_world_map.eventSys")

local borders = require("scripts.advanced_world_map.ui.borders")
local checkBox = require("scripts.advanced_world_map.ui.checkBox")
local button = require("scripts.advanced_world_map.ui.button")
local tooltip = require("scripts.advanced_world_map.ui.tooltip")

local l10n = core.l10n(commonData.l10nKey)


local this = {}

this.followers = {}

this.lastTimestamp = -config.data.fastTravel.cooldown * 120


local fastTravelFunc
local rightBtnMenuFunc


local function fastTravel(menu, cellId, relPos)
    local pos = menu.mapWidget:getWorldPositionByRelativePosition(relPos)

    if eventSys.triggerEvent(eventSys.EVENT.onFastTravel, {position = pos, cellId = cellId}) then
        return
    end

    local timestamp = localStorage.data[commonData.fastTravelTimestampFieldId] or 0
    local realTimestamp = this.lastTimestamp or 0
    local currentGameTime = core.getGameTime()
    local currentRealTime = core.getRealTime()
    if currentGameTime < timestamp + config.data.fastTravel.cooldown * 3600 then
        local remaining = math.ceil(((timestamp + config.data.fastTravel.cooldown * 3600) - currentGameTime) / 3600)
        playerRef:sendEvent("AdvWMap:showMessage", l10n("fastTravelCooldownMessage", {count = remaining}):format(remaining))
        return
    elseif currentRealTime < realTimestamp + config.data.fastTravel.cooldown * 120 then
        local remainingInSec = math.ceil(((realTimestamp + config.data.fastTravel.cooldown * 120) - currentRealTime))
        local remainingInMin = math.ceil(remainingInSec / 60)

        if remainingInSec < 60 then
            playerRef:sendEvent("AdvWMap:showMessage", l10n("fastTravelRealTimeSecCooldownMessage", {count = remainingInSec}):format(remainingInSec))
        else
            playerRef:sendEvent("AdvWMap:showMessage", l10n("fastTravelRealTimeMinCooldownMessage", {count = remainingInMin}):format(remainingInMin))
        end
        return
    end

    if not types.Player.isTeleportingEnabled(playerRef) then
        playerRef:sendEvent("AdvWMap:showMessage", core.getGMST("sTeleportDisabled") or "")
        return
    elseif cellId and not config.data.fastTravel.allowToInterior then
        local dt = mapDataHandler.entrances[cellId]
        local dr = dt and dt[1]
        if dr and not dr.isLEx then
            playerRef:sendEvent("AdvWMap:showMessage", l10n("fastTravelNotAllowedToInterior"))
            return
        end
    end

    this.followers = {}
    for _, actor in pairs(nearby.actors) do
        if actor.recordId ~= "player" then
            actor:sendEvent("AdvWMap:fastTravelFollower", {player = playerRef})
        end
    end

    core.sendGlobalEvent("AdvWMap:fastTravel", {
        pos = pos,
        cellId = cellId,
        availableCells = config.data.fastTravel.onlyDiscovered and discoveredLocs.discovered or nil,
        onlyReachable = config.data.fastTravel.onlyReachable,
    })
end


---@param menu advancedWorldMap.ui.menu.map
local function create(menu)

    local screenSize = uiUtils.getScaledScreenSize()
    local tooltipWidth = math.max(200, screenSize.x / 6)
    local tooltipText = l10n("fastTravelTooltip")

    local tooltipContent = ui.content{
        {
            type = ui.TYPE.TextEdit,
            props = {
                text = tooltipText,
                textColor = config.data.ui.defaultColor,
                textSize = config.data.ui.fontSize,
                anchor = util.vector2(0.5, 0),
                size = util.vector2(tooltipWidth, 0),
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                readOnly = true,
                autoSize = true,
            },
        }
    }

    local iconLayout = {
        type = ui.TYPE.Text,
        props = {
            text = "Ft",
            textSize = config.data.ui.fontSize,
            textColor = config.data.ui.defaultColor,
            anchor = util.vector2(0.5, 0.5),
            size = util.vector2(menu.headerHeight - 2, menu.headerHeight - 2),
        },
        events = {
            focusLoss = async:callback(function(e, layout)
                tooltip.destroy(layout)
            end),

            mouseMove = async:callback(function(e, layout)
                tooltip.move(e, layout)
            end),
        }
    }

    local lastClick = core.getRealTime()
    local clickCount = 0
    local lastPos = menu.mapWidget:getRelativePositionOfCursor()

    if fastTravelFunc then
        eventSys.unregisterHandler(eventSys.EVENT.onMouseRelease, fastTravelFunc)
    end

    fastTravelFunc = function (e)
        if e.button ~= 1 then return end

        local time = core.getRealTime()
        local relPos = menu.mapWidget:getRelativePositionOfCursor()

        if time - lastClick >= 0.6 then
            clickCount = 0
        elseif (lastPos - relPos):length() > 0.002 then
            clickCount = 0
        elseif time - lastClick < 0.6 then
            if clickCount == 2 then
                fastTravel(menu, menu.mapWidget.cellId, relPos)

                time = 0
                clickCount = -1
            end
        end

        lastClick = time
        lastPos = relPos
        clickCount = clickCount + 1
    end
    eventSys.registerHandler(eventSys.EVENT.onMouseRelease, fastTravelFunc)


    if rightBtnMenuFunc then
        eventSys.unregisterHandler(eventSys.EVENT.onRightMouseMenu, rightBtnMenuFunc)
    end
    rightBtnMenuFunc = function (e)
        local content = e.content

        content:add(
            button{
                updateFunc = menu.update,
                text = l10n("FastTravel"),
                event = function (layout)
                    fastTravel(menu, menu.mapWidget.cellId, e.relPos)
                    menu.mapWidget:closeRightMouseMenu()
                end
            }
        )
    end
    eventSys.registerHandler(eventSys.EVENT.onRightMouseMenu, rightBtnMenuFunc)


    menu:addWidget{
        id = "AdvancedWorldMap:FastTravel",
        layout = iconLayout,
        onClick = function (m, e)
            tooltip.create(e, iconLayout, tooltipContent)
        end,
        priority = 100,
    }

end


eventSys.registerHandler(eventSys.EVENT.onMenuOpened, function (e)
    if not config.data.fastTravel.enabled then return end
    create(e.menu)
end, 100)

eventSys.registerHandler(eventSys.EVENT.onMenuClosed, function (e)
    if rightBtnMenuFunc then
        eventSys.unregisterHandler(eventSys.EVENT.onRightMouseMenu, rightBtnMenuFunc)
    end
    if fastTravelFunc then
        eventSys.unregisterHandler(eventSys.EVENT.onMouseRelease, fastTravelFunc)
    end
end)


return this