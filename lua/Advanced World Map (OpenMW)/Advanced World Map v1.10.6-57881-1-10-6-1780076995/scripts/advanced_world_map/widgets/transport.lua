local ui = require("openmw.ui")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local core = require("openmw.core")

local mapDataHandler = require("scripts.advanced_world_map.mapDataHandler")
local eventSys = require("scripts.advanced_world_map.eventSys")
local config = require("scripts.advanced_world_map.config.configLib")
local commonData = require("scripts.advanced_world_map.common")
local localStorage = require("scripts.advanced_world_map.storage.localStorage")
local cellLib = require("scripts.advanced_world_map.utils.cell")
local discoveredLocs = require("scripts.advanced_world_map.discoveredLocations")
local menuHandler = require("scripts.advanced_world_map.menuHandler")
local menuMode = require("scripts.advanced_world_map.ui.menuMode")
local uiUtils = require("scripts.advanced_world_map.ui.utils")
local realTimer = require("scripts.advanced_world_map.realTimer")
local keys = require("scripts.advanced_world_map.input.keys")
local disabledActors = require("scripts.advanced_world_map.disabledActors")
local tableLib = require("scripts.advanced_world_map.utils.table")

local tooltip = require("scripts.advanced_world_map.ui.tooltip")

local map = require("scripts.advanced_world_map.ui.menu.map")

local l10n = core.l10n(commonData.l10nKey)

local this = {}


this.arrowTextures = {}
this.lineTextures = {}

for i = 0, 180 do
    this.arrowTextures[i] = ui.texture{ path = "textures/icons/advanced_world_map/arrows/"..tostring(i)..".png" }
end
for i = 0, 90 do
    this.lineTextures[i] = ui.texture{ path = "textures/icons/advanced_world_map/lines/"..tostring(i)..".png" }
end

---@type advancedWorldMap.ui.mapElementMeta[]
this.markers = {}
---@type table<string, any>
this.trackedCells = {}


---@param angleOffset number?
function this.getTexture(angleOffset, yaw)
    local offset = angleOffset or 0
    local angle = util.normalizeAngle(yaw - offset - math.pi * 1 / 360)
    local index = (util.round((angle / (2 * math.pi)) * 180) + 180) % 180

    index = (180 - index) % 180
    local lineIndex = index % 90

    return this.arrowTextures[index] or this.arrowTextures[0], this.lineTextures[lineIndex] or this.lineTextures[0]
end


local function drawLine(mapWidget, markerType, texture, startPos, endPos, size, step, zoomIn, color, hide)
    local dx = endPos.x - startPos.x
    local dy = endPos.y - startPos.y
    local length = math.sqrt(dx * dx + dy * dy)
    if length < step * 2 then return end

    local count = math.floor(length / step) - 2
    local offset = (length - count * step) / 2

    for i = 0, count do
        local t = (offset + i * step) / length
        local x = startPos.x + dx * t
        local y = startPos.y + dy * t

        local mrk = mapWidget:createImageMarker{
            texture = texture,
            layerId = mapWidget.LAYER.transport,
            scaleFunc = mapWidget.SCALE_FUNCTION.linear,
            size = size or util.vector2(44, 44),
            pos = util.vector2(x, y),
            showWhenZoomedOut = not zoomIn,
            showWhenZoomedIn = zoomIn or false,
            anchor = util.vector2(0.5, 0.5),
            color = color or util.color.rgb(1, 1, 1),
            alpha = config.data.legend.alpha.transport / 100,
            visible = not hide,
            userData = {
                type = commonData.travelLineMarkerType,
            }
        }

        if mrk then
            this.markers[markerType] = this.markers[markerType] or {}
            table.insert(this.markers[markerType], mrk)
        end
    end
end

local function getPosHash(pos)
    return string.format("%d_%d", pos.x / 8192, pos.y / 8192)
end

---@param mapWidget advancedWorldMap.ui.mapWidgetMeta
local function drawMarkers(mapWidget, markerType, color, skipWorld, skipLocal)
    local nodeList = mapDataHandler.transport.data[markerType]
    if not nodeList then return end

    local connectedNodesZOut = {}
    local connectedNodesZIn = {}

    local bitMask = markerType == -1 and 4 or markerType
    bitMask = 2 ^ (bitMask - 1)

    for _, nodeId in ipairs(nodeList) do
        local nodeData = mapDataHandler.transport.nodes[nodeId]
        if not nodeData then goto continue end

        local linkedNodes
        if nodeData.ars then
            local shouldRebuild = false
            for _, recId in pairs(nodeData.ars) do
                if disabledActors.contains(recId) then
                    shouldRebuild = true
                    break
                end
            end

            if shouldRebuild then
                linkedNodes = {}
                for _, recId in pairs(nodeData.ars) do
                    if disabledActors.contains(recId) then goto continue end
                    local actorData = mapDataHandler.transport.actors[recId]
                    if not actorData then goto continue end

                    for _, nId in pairs(actorData.ns or {}) do
                        linkedNodes[nId] = true
                    end

                    ::continue::
                end

                if not next(linkedNodes) then goto continue end
                linkedNodes = tableLib.keys(linkedNodes)
            else
                linkedNodes = nodeData.ls
            end
        else
            linkedNodes = nodeData.ls
        end

        local pos = nodeData.p
        local posHash = getPosHash(pos)
        local nodeCellId = cellLib.getCellIdByPos(pos)
        local isNodeDiscovered = not config.data.legend.transportOnlyDiscovered or discoveredLocs.isDiscovered(nodeCellId)

        for _, linkedNodeId in pairs(linkedNodes) do
            local linkedNodeData = mapDataHandler.transport.nodes[linkedNodeId]
            if not linkedNodeData then goto continue end

            local linkedPos = linkedNodeData.p
            local distance = commonData.distance2D(pos, linkedPos)
            local angle = math.atan2(linkedPos.y - pos.y, linkedPos.x - pos.x) ---@diagnostic disable-line: deprecated
            local texture, lineTexture = this.getTexture(math.pi / 2, angle)

            local isClose = distance < 25000

            local linkedCellId = cellLib.getCellIdByPos(linkedPos)
            local isDiscovered = not config.data.legend.transportOnlyDiscovered or discoveredLocs.isDiscovered(linkedCellId)
            local hide = not isNodeDiscovered and not isDiscovered

            if hide then
                this.trackedCells[linkedCellId] = util.bitOr(this.trackedCells[linkedCellId] or 0, bitMask)
                this.trackedCells[nodeCellId] = util.bitOr(this.trackedCells[nodeCellId] or 0, bitMask)
            end

            local function createMarkers(zoomIn)
                local size = zoomIn and util.vector2(12, 12) or isClose and util.vector2(40, 40) or util.vector2(60, 60)

                local mrk = mapWidget:createImageMarker{
                    texture = texture,
                    layerId = mapWidget.LAYER.transport,
                    scaleFunc = mapWidget.SCALE_FUNCTION.linear,
                    size = size,
                    pos = pos,
                    showWhenZoomedOut = not zoomIn,
                    showWhenZoomedIn = zoomIn or false,
                    anchor = util.vector2(0.5, 0.5),
                    color = color or util.color.rgb(1, 1, 1),
                    alpha = config.data.legend.alpha.transport / 100,
                    visible = not hide,
                    userData = {
                        type = commonData.travelDirectionMarkerType,
                    }
                }

                if mrk then
                    this.markers[markerType] = this.markers[markerType] or {}
                    table.insert(this.markers[markerType], mrk)
                end

                local arr = zoomIn and connectedNodesZIn or connectedNodesZOut

                local linkedPosHash = getPosHash(linkedPos)
                if zoomIn or (not arr[posHash] or not arr[posHash][linkedPosHash]) then
                    arr[posHash] = arr[posHash] or {}
                    arr[posHash][linkedPosHash] = true
                    arr[linkedPosHash] = arr[linkedPosHash] or {}
                    arr[linkedPosHash][posHash] = true

                    drawLine(mapWidget, markerType, lineTexture, pos, linkedPos,
                        zoomIn and util.vector2(8, 8) or nil, zoomIn and 4000 or 16000, zoomIn, color, hide)
                end
            end

            if not skipWorld then
                createMarkers()
            end

            if isClose and not skipLocal then
                createMarkers(true)
            end

            ::continue::
        end

        ::continue::
    end
end


local function removeAllMarkers(tp)
    if tp then
        local dt = this.markers[tp]
        if dt then
            for _, mrk in pairs(dt) do
                mrk:destroy()
            end
            this.markers[tp] = nil
        end

        local bitMask = tp == -1 and 4 or tp
        bitMask = util.bitNot(2 ^ (bitMask - 1))
        for clId, val in pairs(this.trackedCells) do
            local newVal = util.bitAnd(val, bitMask)
            newVal = newVal ~= 0 and newVal or nil
            this.trackedCells[clId] = newVal
        end

        return
    end

    for _, group in pairs(this.markers) do
        for _, mrk in pairs(group) do
            mrk:destroy()
        end
    end
    this.markers = {}
    this.trackedCells = {}
end



eventSys.registerHandler(eventSys.EVENT.onMapInitialized, function (e)
    if e.cellId or not mapDataHandler.isInitialized() then return end


    local function createMarkers(tp)
        removeAllMarkers(tp)

        local skipLocal = localStorage.data[commonData.transportLocalFieldId] == false
        local caravaners = localStorage.data[commonData.transportCaravanersFieldId] ~= false
        local shipmasters = localStorage.data[commonData.transportShipmastersFieldId] ~= false
        local guildGuides = localStorage.data[commonData.transportGuildGuidesFieldId] ~= false
        local other = localStorage.data[commonData.transportOtherFieldId] == true

        if (not tp or tp == 1) and (not skipLocal or caravaners) then
            drawMarkers(e.mapWidget, 1, config.data.ui.travelCaravanerColor, not caravaners, skipLocal)
        end
        if (not tp or tp == 2) and (not skipLocal or shipmasters) then
            drawMarkers(e.mapWidget, 2, config.data.ui.travelShipmasterColor, not shipmasters, skipLocal)
        end
        if (not tp or tp == 3) and (not skipLocal or guildGuides) then
            drawMarkers(e.mapWidget, 3, config.data.ui.travelGuildGuideColor, not guildGuides, skipLocal)
        end
        if (not tp or tp == 4 or tp == -1) and (not skipLocal or other) then
            drawMarkers(e.mapWidget, 4, config.data.ui.travelOtherColor, not other, skipLocal)
            drawMarkers(e.mapWidget, -1, config.data.ui.travelOtherColor, not other, skipLocal)
        end
    end

    createMarkers()

    e.mapWidget.userData["updateTravelMarkers"] = createMarkers
end)


eventSys.registerHandler(eventSys.EVENT.onMapDestroyed, function (e)
    if e.mapWidget.cellId ~= nil or not mapDataHandler.isInitialized() then return end
    removeAllMarkers()
end)


eventSys.registerHandler(eventSys.EVENT.onDiscover, function (e)
    local updateMarkers = false
    local markerTypesToUpdate = {}

    for cId, _ in pairs(e.discoveredMap) do
        local val = this.trackedCells[cId]
        if val then
            updateMarkers = true
            local newVal = val

            for i = 1, 4 do
                local mask = 2 ^ (i - 1)
                if util.bitAnd(val, mask) ~= 0 then
                    markerTypesToUpdate[i] = true
                    newVal = util.bitAnd(newVal, util.bitNot(mask))
                end
            end

            newVal = newVal ~= 0 and newVal or nil
            this.trackedCells[cId] = newVal
        end
    end

    if updateMarkers then
        local mapWidget = map.cachedMapWidgetMetatable[commonData.exteriorMapId]
        if mapWidget and mapWidget.userData.updateTravelMarkers then
            for tp, _ in pairs(markerTypesToUpdate) do
                mapWidget.userData.updateTravelMarkers(tp)
            end
        end
    end
end)


eventSys.registerHandler(eventSys.EVENT.onMapInitialized, function (e)
    if e.cellId ~= nil or config.data.message.transportFeatureInfoShown ~= 0 then return end

    local menuProps = e.menu.layout.props
    if not menuProps then return end

    local parent = {userData = {}}

    local function create()
        local menuPos = menuProps.relativePosition:emul(uiUtils.getScaledScreenSize())
        tooltip.create(
            {position = menuPos + util.vector2(32, e.menu.headerFullHeight + 4)},
            parent,
            ui.content{
                {
                    type = ui.TYPE.TextEdit,
                    props = {
                        text = l10n("TransportFeatureInfo", {
                            toggleTransportKey = keys.keyCombinationToString(config.data.input.toggleTransportHotkey) or l10n("Undefined"),
                            cycleTransportKey = keys.keyCombinationToString(config.data.input.cycleTransportHotkey) or l10n("Undefined")
                        }),
                        textColor = config.data.ui.defaultColor,
                        textSize = math.floor(config.data.ui.fontSize * 1.2),
                        anchor = util.vector2(0.5, 0),
                        size = util.vector2(uiUtils.getScaledScreenSize().x / 4, 0),
                        multiline = true,
                        wordWrap = true,
                        textAlignH = ui.ALIGNMENT.Center,
                        textAlignV = ui.ALIGNMENT.Center,
                        readOnly = true,
                        autoSize = true,
                    }
                }
            },
            nil,
            true
        )
    end
    create()

    local function timerCallback()
        if not parent.userData.tooltip then return end
        if config.data.message.transportFeatureInfoShown ~= 0 then
            tooltip.destroy(parent, true)
            return
        end

        local menuPos = menuProps.relativePosition:emul(uiUtils.getScaledScreenSize())
        tooltip.move({position = menuPos + util.vector2(32, e.menu.headerFullHeight + 4)}, parent)
        realTimer.newTimer(0.05, timerCallback)
    end
    realTimer.newTimer(0.05, timerCallback)
end)


I.DijectKeyBindings.action.register(commonData.cycleTransportKeyId, function ()
    ---@type advancedWorldMap.ui.menu.map?
    local menu = menuHandler.getMenu(commonData.mapMenuId)
    if not menu or not menuMode.isActive() or menu.mapWidget.cellId then return end

    if config.data.message.transportFeatureInfoShown == 0 then
        config.setValue("message.transportFeatureInfoShown", 1)
    end

    local visible = config.data.legend.visibility.transport
    if not visible then
        config.setValue("legend.visibility.transport", true)
        menu.mapWidget:setLayerVisibility(menu.mapWidget.LAYER.transport, true)
    end

    local transportTypes = {
        [1] = commonData.transportCaravanersFieldId,
        [2] = commonData.transportShipmastersFieldId,
        [3] = commonData.transportGuildGuidesFieldId,
        [4] = commonData.transportOtherFieldId,
    }

    local list = {
        {[1] = true},
        {[2] = true},
        {[3] = true},
        {[4] = true},
        {[1] = true, [2] = true, [3] = true},
        {[1] = true, [2] = true, [3] = true, [4] = true},
        {},
    }

    for i, varLabels in pairs(list) do
        local current = true
        for j = 1, 4 do
            current = ((varLabels[j] or false) == (localStorage.data[transportTypes[j]] ~= false))
            if not current then break end
        end

        if current then
            local nextIndex = (i % #list) + 1
            local nextLabels = list[nextIndex]
            for j = 1, 4 do
                local val = nextLabels[j] or false
                localStorage.data[transportTypes[j]] = val
            end
            break
        end
    end

    if menu.mapWidget.userData.updateTravelMarkers then
        menu.mapWidget.userData.updateTravelMarkers()
        menu:update()
    end

    if menu:isWidgetActive("AdvancedWorldMap:Legend") then
        menu:closeActiveWidget()
        menu:openWidget("AdvancedWorldMap:Legend")
    end
end)


I.DijectKeyBindings.action.register(commonData.toggleTransportKeyId, function ()
    ---@type advancedWorldMap.ui.menu.map?
    local menu = menuHandler.getMenu(commonData.mapMenuId)
    if not menu or not menuMode.isActive() or menu.mapWidget.cellId then return end

    if config.data.message.transportFeatureInfoShown == 0 then
        config.setValue("message.transportFeatureInfoShown", 1)
    end

    local val = not config.data.legend.visibility.transport
    config.setValue("legend.visibility.transport", val)
    menu.mapWidget:setLayerVisibility(menu.mapWidget.LAYER.transport, val)

    if menu:isWidgetActive("AdvancedWorldMap:Legend") then
        menu:closeActiveWidget()
        menu:openWidget("AdvancedWorldMap:Legend")
    end

    menu:update()
end)