local ui = require("openmw.ui")
local vfs = require("openmw.vfs")
local util = require("openmw.util")
local core = require("openmw.core")
local playerRef = require("openmw.self")

local uiUtils = require("scripts.advanced_world_map_tracking.utils.ui")
local stringLib = require("scripts.advanced_world_map_tracking.utils.string")
local tableLib = require("scripts.advanced_world_map_tracking.utils.table")
local dataHandler = require("scripts.advanced_world_map_tracking.data.dataHandler")
local activeObjects = require("scripts.advanced_world_map_tracking.handlers.activeObjects")
local common = require("scripts.advanced_world_map_tracking.common")
local config = require("scripts.advanced_world_map_tracking.config.config")
local tags = require("scripts.advanced_world_map_tracking.utils.tags")
local markerUserdata = require("scripts.advanced_world_map_tracking.handlers.markerUserdata")

local this = {}

---@type table<string, activeMarkers.activeData> by cell id or object id
this.active = {}
---@type AdvancedWorldMap.Interface
this.advWMap = nil

---@type AdvancedWorldMap.Menu.Map
this.activeMenu = nil

this.coroutine = nil
this.lastUpdateTime = 0

this.requestUpdate = false

this.registeredMarkersCount = 0
---@type table<integer, {markerData: advWMap_tracking.markerData, objectHandler: advWMap_tracking.objectHandler?}> by marker id
this.registerMarkerQueue = {}

local markerType = {
    pos = 1,
    object = 2,
}

---@class activeMarkers.activeData
---@field mapWidget AdvancedWorldMap.MapWidget
---@field registered table<string, {type: integer, markers: table<string, AdvancedWorldMap.MapElement>}> by marker id, markers by marker hash or object id
---@field posMarkers table<string, AdvancedWorldMap.MapElement> by marker hash. for pos markers
---@field objectMarkers table<string, AdvancedWorldMap.MapElement> by object id. for object markers
---@field activeMarkers table<string, activeMarkers.markerUserdata> by map marker id
---@field visibleMarkers table<string, activeMarkers.markerUserdata> by map marker id
---@field grid table<string, AdvancedWorldMap.MapElement>
---@field gridOut table<string, AdvancedWorldMap.MapElement>


local function getMarkerPosHash(id, layer, pos)
    return string.format("%s_%s_%d_%d_%d", id or "", layer or "marker",
        math.floor(pos.x / 32), math.floor(pos.y / 32), math.floor((pos.z or 0) / 32))
end


---@param posDt advWMap_tracking.position
local function getGridIds(posDt, layer, gridSize)
    layer = layer or "marker"
    local gridIds = {}
    for x = -1, 1 do
        for y = -1, 1 do
            table.insert(gridIds, string.format("%s_%d_%d",
                layer,
                (posDt.pos.x + gridSize * x) / gridSize,
                (posDt.pos.y + gridSize * y) / gridSize
            ))
        end
    end

    return gridIds
end


function this.addToRegisteredMarkers(cellId, id, type, marker)
    local activeData = this.active[cellId]
    if not activeData then return end

    activeData.registered[id] = activeData.registered[id] or {type = type, markers = {}}
    local userData = marker:getUserData()
    local markerId = userData.objId or userData.posHash
    activeData.registered[id].markers[markerId] = marker
end


function this.removeFromRegisteredMarkers(activeData, id, marker)
    if not activeData then return end
    local regData = activeData.registered[id]
    if not regData then return end

    local markerId = marker:getUserData().objId or marker:getUserData().posHash
    regData.markers[markerId] = nil

    if not next(regData.markers) then
        activeData.registered[id] = nil
    end
end


local function removeRegisteredMarkers(activeData, id)
    if not activeData then return end
    local regData = activeData.registered[id]
    if not regData then return end

    for _, marker in pairs(regData.markers) do
        ---@type activeMarkers.markerUserdata
        local userData = marker:getUserData()
        if not userData then goto continue end

        for i, mkd, mkt in userData:dataIterator() do
            if mkd.id == id then
                if regData.type == markerType.object then
                    activeData.objectMarkers[userData.objId] = nil
                elseif regData.type == markerType.pos then
                    activeData.posMarkers[userData.posHash] = nil
                end
                userData:removeMarkerData(i)
            end
        end

        if not userData:hasData() then
            if activeData then
                if userData.objId then
                    activeData.objectMarkers[userData.objId] = nil
                else
                    activeData.posMarkers[userData.posHash] = nil
                end
            end

            marker:destroy()
        else
            userData:updateMarker()
        end

        ::continue::
    end

    activeData.registered[id] = nil
end


---@param activeData activeMarkers.activeData
---@param markerData advWMap_tracking.markerData
---@param obj advWMap_tracking.objectHandler?
---@param pos Vector3|Vector2?
local function createMarker(activeData, markerData, obj, pos, grid)
    local template = dataHandler.getMarkerTemplate(markerData)
    if not template then return end

    local mapWidget = activeData.mapWidget

    local texturePath = template.path or "white"
    if not vfs.fileExists(texturePath) then texturePath = "white" end

    local texture = ui.texture{ path = texturePath }

    ---@class activeMarkers.markerUserdata
    local userData = {
        type = common.userDataMarkerType,
        ---@type activeMarkers.activeData
        activeData = activeData,
        parent = this,
        ---@type table<string, {[1]: advWMap_tracking.markerData, [2]: advWMap_tracking.markerTemplateData}> by marker or template id
        data = {},
        count = 0,
        topTemplate = template,
        lastPos = pos or obj and obj.position,
        zoomOut = markerData.zoomOut and true or nil,
        grid = grid,
        cellId = mapWidget.cellId or common.worldCellLabel,
        posHash = pos and getMarkerPosHash(markerData.id, template.layer, pos),
        rndTm = config.data.tracking.visibilityUpdateTime * 0.5 + math.random() * config.data.tracking.visibilityUpdateTime,
        visUTm = 0,
        itemUTm = 0,
        itUBTm = config.data.tracking.itemUpdateTime + math.random(),
        objId = obj and obj.id,
        obj = obj,
    }

    ---@class activeMarkers.markerUserdata
    local userDataMeta = setmetatable(userData, markerUserdata)

    local tooltipLib = this.advWMap.uiElements.tooltip
    local eventLib = this.advWMap.events
    local nextTooltipCheck = core.getRealTime()

    local marker
    ---@type AdvancedWorldMap.MapWidget.CreateImageMarkerParams
    local markerParams = {
        layerId = mapWidget.LAYER[template.layer or "marker"],
        pos = pos or obj and obj.position, ---@diagnostic disable-line: assign-type-mismatch
        texture = texture,
        size = template.size or util.vector2(10, 10),
        color = template.color or common.defaultColor,
        visible = false,
        showWhenZoomedIn = not markerData.zoomOut and true or false,
        showWhenZoomedOut = markerData.zoomOut and true or false,
        anchor = template.anchor,
        userData = userDataMeta,
        events = {
            mouseRelease = function (e, layout, beenPressed)
                if beenPressed then
                    userDataMeta:triggerOnClick(e.button)
                end
            end,

            mouseMove = function(e, layout)
                if not tooltipLib.isExists(layout) then
                    if core.getRealTime() < nextTooltipCheck then return end

                    local tooltipContent = ui.content{}
                    local textLists = {}

                    for i, dt in ipairs(userDataMeta:getSortedData()) do
                        if not userDataMeta:isDataVisible(dt) then goto continue end
                        local templ = dt[2]

                        if templ.tText then

                            local function addText(text)
                                local t, listId = tags.replace(text, obj)

                                local tooltipWidth = not listId and math.min(
                                    ---@diagnostic disable-next-line: undefined-field
                                    stringLib.length(t) * config.data.ui.fontSize * config.data.ui.textHeightMul,
                                    uiUtils.getTooltipWidth()
                                ) or uiUtils.getTooltipWidth()

                                if listId and textLists[listId] then
                                    table.insert(textLists[listId].texts, t)
                                    return
                                end

                                local elem = {
                                    type = ui.TYPE.TextEdit,
                                    props = {
                                        text = listId and "@list:"..listId.."@" or t,
                                        textColor = config.data.ui.defaultColor, ---@diagnostic disable-line: undefined-field
                                        textSize = config.data.ui.fontSize, ---@diagnostic disable-line: undefined-field
                                        anchor = util.vector2(0.5, 0.5),
                                        size = util.vector2(tooltipWidth, 0),
                                        multiline = true,
                                        wordWrap = true,
                                        textAlignH = ui.ALIGNMENT.Center,
                                        textAlignV = ui.ALIGNMENT.Center,
                                        readOnly = true,
                                        autoSize = true,
                                    }
                                }

                                if listId then
                                    textLists[listId] = {elem = elem, texts = {t}}
                                end

                                tooltipContent:add(elem)
                            end

                            if type(templ.tText) == "table" then
                                for _, text in ipairs(templ.tText) do ---@diagnostic disable-line: param-type-mismatch
                                    if text ~= "" and (obj or text ~= "@name@") then
                                        addText(text)
                                    end
                                end
                            else
                                addText(templ.tText)
                            end
                        end

                        if templ.tEvent and eventLib.triggerEvent(eventLib.EVENT.onTrackingTooltipShow, {
                                    content = tooltipContent,
                                    markerId = dt[1].id, templateId = templ.id,
                                    markerUserData = dt[1].userData, templateUserData = templ.userData,
                                    object = obj and obj.object or nil
                                }) then
                            return
                        end

                        ::continue::
                    end

                    for _, elemDt in pairs(textLists) do
                        local text = ""
                        local map = {}
                        for _, t in ipairs(elemDt.texts) do
                            if not map[t] then
                                ---@diagnostic disable-next-line: undefined-field
                                text = text..(text ~= "" and "#"..config.data.ui.defaultColor:asHex()..", " or "")..t
                                map[t] = true
                            end
                        end
                        elemDt.elem.props.text = text
                    end

                    local foundTexts = {}
                    if #tooltipContent > 0 then
                        local newTooltipContent = ui.content{}

                        for i = 1, #tooltipContent - 1 do
                            local item = tooltipContent[i]

                            if item.props and item.props.text then
                                if foundTexts[item.props.text] then
                                    goto continue
                                end
                                foundTexts[item.props.text] = true
                            end

                            newTooltipContent:add(item)
                            newTooltipContent:add(this.advWMap.uiElements.interval(0, this.advWMap.getConfig().ui.fontSize / 3))

                            ::continue::
                        end

                        local lastItem = tooltipContent[#tooltipContent]
                        if lastItem.props and lastItem.props.text then
                            if not foundTexts[lastItem.props.text] then
                                newTooltipContent:add(lastItem)
                            end
                        end

                        layout.userData.tooltipContent = newTooltipContent
                        tooltipLib.createOrMove(e, layout, newTooltipContent)
                    else
                        nextTooltipCheck = core.getRealTime() + 2
                        layout.userData.tooltipContent = nil
                    end

                else
                    tooltipLib.createOrMove(e, layout)
                end
            end,
        }
    }

    marker = mapWidget:createImageMarker(markerParams)
    userDataMeta.marker = marker

    userDataMeta:addMarkerData(markerData, template)
    userDataMeta.initialized = true

    this.requestUpdate = true

    return marker
end


---@param marker AdvancedWorldMap.MapElement
---@param markerData advWMap_tracking.markerData
---@param template advWMap_tracking.markerTemplateData
---@return boolean
local function addToMarker(marker, markerData, template)
    ---@type activeMarkers.markerUserdata
    local userData = marker:getUserData()
    if not userData then return false end
    if not userData:addMarkerData(markerData, template) then return false end

    this.requestUpdate = true

    return true
end


---@param markerData advWMap_tracking.markerData
---@param objectHandler advWMap_tracking.objectHandler?
local function register(markerData, objectHandler)
    if markerData.invalid then return end

    ---@type string
    local markerId = markerData.id

    local template = dataHandler.getMarkerTemplate(markerData)
    if not template then return end

    if template.invalid then
        markerData.invalid = true
        return
    end

    if markerData.positions then
        for _, posDt in pairs(markerData.positions) do
            local cellId = posDt.id or common.worldCellLabel

            local data = this.active[cellId]
            local markerHash = getMarkerPosHash(markerData.id, template.layer, posDt.pos)
            if not data or data.posMarkers[markerHash] then goto continue end

            if data.registered[markerId] and data.registered[markerId].type ~= markerType.pos then
                goto continue
            end

            local gridIds
            local gridTb
            if not markerData.single then
                gridIds = getGridIds(posDt, template.layer, markerData.zoomOut and 256 or 32)
                gridTb = markerData.zoomOut and data.gridOut or data.grid
                local gridMarker
                for _, gridId in pairs(gridIds) do
                    if gridTb[gridId] then
                        gridMarker = gridTb[gridId]
                        break
                    end
                end

                if gridMarker then
                    addToMarker(gridMarker, markerData, template)
                    goto continue
                end
            end

            local marker = createMarker(data, markerData, nil, posDt.pos, gridIds)
            if not marker then goto continue end

            if gridIds and gridTb then
                for _, gridId in pairs(gridIds) do
                    gridTb[gridId] = marker
                end
            end

            ::continue::
        end
    end

    if objectHandler then
        if objectHandler and objectHandler.__type ~= "objHandler" then
            local handler = activeObjects.getHandler(objectHandler.recordId)
            if not handler then goto continue end
            objectHandler = handler:get(objectHandler.id)
            if not objectHandler then goto continue end
        end

        -- skip objects that are not in the active cell
        if ((markerData.active or markerData.activeEx and objectHandler.cell and objectHandler.cell.isExterior) or
                (markerData.distance and markerData.distance <= 8192)) and not objectHandler:isActive() then
            goto continue
        end

        local cellId = objectHandler.cell.isExterior and common.worldCellLabel or objectHandler.cell.id
        local objId = objectHandler.id

        if markerData.objValidateFn and not markerData.objValidateFn(markerData, template, objectHandler.object) then
            goto continue
        end

        local data = this.active[cellId]
        if not data then goto continue end

        if data.registered[markerId] and data.registered[markerId].type ~= markerType.object then
            removeRegisteredMarkers(data, markerId)
        end

        local objMarker = data.objectMarkers[objId]
        if objMarker then
            local userData = objMarker:getUserData()
            if not userData then goto continue end

            userData.obj = objectHandler
            addToMarker(objMarker, markerData, template)
        else
            local marker = createMarker(data, markerData, objectHandler)
        end

        ::continue::
    end
end


---@param markerData advWMap_tracking.markerData
---@param objectHandler advWMap_tracking.objectHandler?
function this.register(markerData, objectHandler)
    if this.registeredMarkersCount > config.data.tracking.markersPerFrame then
        table.insert(this.registerMarkerQueue, {markerData = markerData, objectHandler = objectHandler})
        return
    end
    this.registeredMarkersCount = this.registeredMarkersCount + 1

    register(markerData, objectHandler)
end


function this.clearRegisterQueue()
    this.registerMarkerQueue = {}
    this.registeredMarkersCount = 0
end


function this.update()
    for cellId, data in pairs(this.active) do
        for id, dt in pairs(data.posMarkers) do
            ---@type activeMarkers.markerUserdata
            local userData = dt:getUserData() ---@diagnostic disable-line: assign-type-mismatch
            if userData then
                userData:updateMarker()
            end
        end

        for id, dt in pairs(data.objectMarkers) do
            ---@type activeMarkers.markerUserdata
            local userData = dt:getUserData() ---@diagnostic disable-line: assign-type-mismatch
            if userData then
                userData:updateMarker()
            end
        end
    end
end


function this.updateObjMarker(cellId, objId)
    cellId = cellId or common.worldCellLabel
    local data = this.active[cellId]
    if not data then return end

    local marker = data.objectMarkers[objId]
    if not marker then return end

    ---@type activeMarkers.markerUserdata
    local userData = marker:getUserData()
    if not userData then return end

    userData:updateMarker()
end


function this.updateCell(cellId)
    cellId = cellId or common.worldCellLabel
    local data = this.active[cellId]
    if not data then return end

    for id, dt in pairs(data.posMarkers) do
        ---@type activeMarkers.markerUserdata
        local userData = dt:getUserData() ---@diagnostic disable-line: assign-type-mismatch
        if userData then
            userData:updateMarker()
        end
    end

    for id, dt in pairs(data.objectMarkers) do
        ---@type activeMarkers.markerUserdata
        local userData = dt:getUserData() ---@diagnostic disable-line: assign-type-mismatch
        if userData then
            userData:updateMarker()
        end
    end
end


---@param cellId string?
function this.updatePositions(cellId)
    cellId = cellId or common.worldCellLabel
    local data = this.active[cellId]
    if not data then return end

    local res = false
    for mId, userData in pairs(data.visibleMarkers) do
        if userData.obj and userData.obj:isActive() then
            userData:updateMarkerPos()
            res = true
        end
    end

    this.lastUpdateTime = core.getRealTime()

    return res
end


local visibilityKeyCounter = nil
local lastFrameTime = 0
function this.startUpdateVisibilityCoroutine(cellId, realTimer)
    cellId = cellId or common.worldCellLabel
    local data = this.active[cellId]
    if not data then return false end

    visibilityKeyCounter = nil
    local index = 0

    if this.coroutine then
        this.coroutine()
        this.coroutine = nil
    end

    -- use real timer instead of coroutine to avoid errors when calling script functions from different modules/mods
    local function func()
        local tm = core.getRealTime()

        local repeated = visibilityKeyCounter and 0 or 1
        for i = 1, config.data.tracking.visibilityUpdateStepLimit do
            if visibilityKeyCounter and not data.activeMarkers[visibilityKeyCounter] then visibilityKeyCounter = nil end
            local k, markerUserData = next(data.activeMarkers, visibilityKeyCounter)
            visibilityKeyCounter = k
            if not markerUserData then
                repeated = repeated + 1
                if repeated >= 2 then
                    break
                end
                goto continue
            end

            markerUserData:updateMarkerVisibility(tm)

            ::continue::
            index = index + 1

            local rt = core.getRealTime()
            local tDiff = rt - tm

            if tDiff > config.data.tracking.visibilityUpdateTimeLimit then break end
        end

        for i = 1, config.data.tracking.markersPerFrame do
            local k, v = next(this.registerMarkerQueue)
            if not v then break end

            register(v.markerData, v.objectHandler)
            this.registerMarkerQueue[k] = nil ---@diagnostic disable-line: need-check-nil
        end
        this.registeredMarkersCount = 0

        if this.activeMenu and (this.requestUpdate or not core.isWorldPaused()) and tm - this.lastUpdateTime >= 1 then
            this.activeMenu:update()
            this.lastUpdateTime = tm
            this.requestUpdate = false
        end

        lastFrameTime = tm
        this.coroutine = realTimer(0, func)
    end

    func()

    return true
end


function this.destroyUpdateVisibilityCoroutine()
    if this.coroutine then
        this.coroutine()
        this.coroutine = nil
    end
end


---@param region AdvancedWorldMap.MapWidget.Region
function this.removeMarkersOutsideRegion(region)
    local activeData = this.active[common.worldCellLabel]
    if not activeData then return end

    local toRemove = {}

    for id, marker in pairs(activeData.posMarkers) do
        if not common.isPointInRegion(region, marker:getPosition()) then
            table.insert(toRemove, marker)
        end
    end

    for id, marker in pairs(activeData.objectMarkers) do
        if not common.isPointInRegion(region, marker:getPosition()) then
            table.insert(toRemove, marker)
        end
    end

    for _, marker in ipairs(toRemove) do
        ---@type activeMarkers.markerUserdata
        local userData = marker:getUserData()
        if userData then
            userData:remove()
        end
    end

    visibilityKeyCounter = nil
end


function this.removeInvalid()
    for cellId, data in pairs(this.active) do
        if not data.mapWidget:isValid() then
            this.active[cellId] = nil
        end
    end
end


---@param cellId string?
---@param marker AdvancedWorldMap.MapElement
function this.addActiveMarker(cellId, marker)
    cellId = cellId or common.worldCellLabel
    local activeData = this.active[cellId]
    if not activeData then return end

    ---@type activeMarkers.markerUserdata
    local userData = marker:getUserData()
    activeData.activeMarkers[marker._id] = userData
    if marker:getVisibility() then
        activeData.visibleMarkers[marker._id] = userData
    end
end


---@param cellId string?
---@param marker AdvancedWorldMap.MapElement
function this.removeActiveMarker(cellId, marker)
    cellId = cellId or common.worldCellLabel
    local activeData = this.active[cellId]
    if not activeData then return end

    activeData.activeMarkers[marker._id] = nil
    activeData.visibleMarkers[marker._id] = nil
end


---@param mapWidget AdvancedWorldMap.MapWidget
function this.registerMapWidget(mapWidget)
    local cellId = mapWidget.cellId or common.worldCellLabel
    if this.active[cellId] then return end

    this.active[cellId] = {mapWidget = mapWidget, posMarkers = {}, grid = {}, gridOut = {},
        objectMarkers = {}, registered = {}, activeMarkers = {}, visibleMarkers = {}}
end


---@param data activeMarkers.activeData
local function invalidateShortMarkers(data)
    ---@param userData activeMarkers.markerUserdata
    local function checkShortFlags(userData)
        for _, mkd, mkt in userData:dataIterator() do
            if mkd.short then
                mkd.invalid = true
            end
            if mkt.short then
                mkt.invalid = true
            end
        end
    end

    for _, marker in pairs(data.posMarkers) do
        checkShortFlags(marker:getUserData())
    end

    for _, marker in pairs(data.objectMarkers) do
        checkShortFlags(marker:getUserData())
    end
end


---@param mapWidget AdvancedWorldMap.MapWidget
function this.unregisterMapWidget(mapWidget)
    local cellId = mapWidget.cellId or common.worldCellLabel
    local data = this.active[cellId]
    if not data then return end

    invalidateShortMarkers(data)

    this.active[cellId] = nil
end


function this.invalidateShortMarkers(mapWidget)
    local cellId = mapWidget.cellId or common.worldCellLabel
    local data = this.active[cellId]
    if not data then return end

    invalidateShortMarkers(data)
end


function this.registerMenu(menu)
    this.activeMenu = menu
end


function this.unregisterMenu()
    this.activeMenu = nil
end



return this