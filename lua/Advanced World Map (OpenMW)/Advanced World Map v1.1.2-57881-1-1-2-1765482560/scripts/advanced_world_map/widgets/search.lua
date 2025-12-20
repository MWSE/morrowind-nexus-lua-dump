local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local input = require('openmw.input')
local playerRef = require("openmw.self")

local commonData = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.configLib")

local uiUtils = require("scripts.advanced_world_map.ui.utils")
local stringLib = require("scripts.advanced_world_map.utils.string")
local tableLib = require("scripts.advanced_world_map.utils.table")
local cellLib = require("scripts.advanced_world_map.utils.cell")

local localStorage = require("scripts.advanced_world_map.storage.localStorage")
local mapDataHandler = require("scripts.advanced_world_map.mapDataHandler")
local playerPos = require("scripts.advanced_world_map.playerPosition")
local discoveredLocations = require("scripts.advanced_world_map.discoveredLocations")

local eventSys = require("scripts.advanced_world_map.eventSys")

local scrollBox = require("scripts.advanced_world_map.ui.scrollBox")
local borders = require("scripts.advanced_world_map.ui.borders")
local button = require("scripts.advanced_world_map.ui.button")
local interval = require('scripts.advanced_world_map.ui.interval')
local checkBox = require("scripts.advanced_world_map.ui.checkBox")

local l10n = core.l10n(commonData.l10nKey)

local defaultColor = util.color.rgb(0, 0, 0)

local searchIcoTexture = ui.texture{ path = commonData.searchWidgetIcon }

local worldMarkerTexture = ui.texture{ path = commonData.searchWorldMarkerPath }


---@type table<string, advancedWorldMap.ui.mapElementMeta>
local visibleMarkers = {}
---@type table<string, advancedWorldMap.ui.mapElementMeta>
local modifiedMarkers = {}
---@type table<any, advancedWorldMap.ui.mapElementMeta>
local temporaryMarkers = {}
---@type table<string, any[]> by pos hash
local searchData = {}
---@type table<string, boolean>
local targetCells = {}


---@param handler advancedWorldMap.ui.mapElementMeta
local function getMarkerId(handler)
    return tostring(handler._parent.cellId).."_"..handler:getId()
end


---@return string
local function getPosHash(cellId, pos)
    return string.format("pos_%s_%d_%d", tostring(cellId), pos.x, pos.y)
end


---@param menu advancedWorldMap.ui.menu.map
local function createTemporaryMarker(id, menu, dt, pos, color, text, showZoomIn)
    local mapWidget = menu.mapWidget
    if temporaryMarkers[id] then return end

    local tooltipText = text or ""
    local cellName = mapDataHandler.cellNameById[mapWidget.cellId or cellLib.getCellIdByPos(pos) or ""]
    if cellName then
        tooltipText = tooltipText..string.format("\n\n%s\n(%d, %d)", cellName, math.floor(pos.x), math.floor(pos.y))
    end

    local h = mapWidget:createImageMarker{
        layerId = mapWidget.LAYER.marker,
        pos = pos,
        color = color or config.data.ui.foundMarkerColor,
        texture = worldMarkerTexture,
        anchor = util.vector2(0.5, 1),
        size = util.vector2(config.data.legend.markerSize * 2.5, config.data.legend.markerSize * 5),
        showWhenZoomedOut = true,
        showWhenZoomedIn = showZoomIn,
        tooltipContent = text and ui.content{
            {
                type = ui.TYPE.TextEdit,
                props = {
                    text = tooltipText,
                    textSize = config.data.ui.fontSize,
                    textColor = config.data.ui.defaultColor,
                    autoSize = true,
                    multiline = true,
                    wordWrap = true,
                    readOnly = true,
                    size = util.vector2(
                        util.clamp(
                            stringLib.length(text) * config.data.ui.fontSize * config.data.ui.textHeightMul,
                            300,
                            uiUtils.getScaledScreenSize().x / 5
                        ),
                        0
                    ),
                    textAlignH = ui.ALIGNMENT.Center,
                }
            }
        } or nil,
        events = {
            mouseRelease = function(e, layout, pressed)
                if e.button ~= 1 or not pressed then return end

                if menu.mapWidget.cellId ~= dt.cellId then
                    menu:updateMapWidgetCell(dt.cellId)
                end
                menu.mapWidget:focusOnWorldPosition(dt.pos)
                menu.mapWidget:updateMarkers()

                menu:update()
            end,
        }
    }
    temporaryMarkers[id] = h
end


local function removeTemporaryWorldMarkers()
    for i, handler in pairs(temporaryMarkers) do
        handler:destroy()
        temporaryMarkers[i] = nil
    end
end


---@param handler advancedWorldMap.ui.mapElementMeta
local function setMarkerVisibility(handler, val)
    if val == nil then
        handler:updateLayout{ ---@diagnostic disable-line: missing-fields
            visible = (handler._params.visible == true or handler._params.visible == nil) and true or false,
        }
        visibleMarkers[getMarkerId(handler)] = nil
    elseif val then
        handler:updateLayout{visible = val} ---@diagnostic disable-line: missing-fields
        visibleMarkers[getMarkerId(handler)] = handler
    end
end

local function resetMarkersVisibility()
    for i, handler in pairs(visibleMarkers) do
        setMarkerVisibility(handler)
        visibleMarkers[i] = nil
    end
end

---@param handler advancedWorldMap.ui.mapElementMeta
local function setMarkerColor(handler, color, reset)
    if not color and not reset then return end

    if reset then
        handler:updateLayout{ ---@diagnostic disable-line: missing-fields
            color = handler._params.color or defaultColor,
            alpha = handler._params.alpha or 1,
        }
        modifiedMarkers[getMarkerId(handler)] = nil
    else
        handler:updateLayout{ ---@diagnostic disable-line: missing-fields
            color = color,
            alpha = 1,
        }
        modifiedMarkers[getMarkerId(handler)] = handler
    end
end

local function resetMarkersColor()
    for i, handler in pairs(modifiedMarkers) do
        setMarkerColor(handler, nil, true)
        modifiedMarkers[i] = nil
    end
end

---@param handler advancedWorldMap.ui.mapElementMeta
---@param textFilter string
local function updateLayoutForMarker(handler, textFilter, color)
    local userData = handler:getUserData()
    if not userData then return end

    local changeVisibility = false

    if userData.allowSearchFilter then
        local posHash = getPosHash(handler._parent.cellId, handler._params.pos)
        local data = searchData[posHash]

        if data and next(data) then
            local params = data[1]
            setMarkerColor(handler, params.color)
        elseif userData.searchText and userData.searchText:find(textFilter) then
            setMarkerColor(handler, color or config.data.ui.foundMarkerColor)
        end
    end
end

---@param mapWidget advancedWorldMap.ui.mapWidgetMeta
local function updateVisibilityForActiveMarkers(mapWidget, textFilter)
    local markers = mapWidget:getActiveMarkers()

    for _, handler in pairs(markers or {}) do
        updateLayoutForMarker(handler, textFilter)
    end
end


---@return table<string, string> res by cell id - cell name
local function getAvailableInteriorNamesFromInterior(cellId, checked, res)
    checked = checked or {}
    res = res or {}

    if checked[cellId] then return res end
    checked[cellId] = true

    for _, destDt in pairs(mapDataHandler.entrances[cellId] or {}) do
        if not checked[destDt.dCId] then
            if not destDt.isDEx then
                res[destDt.dCId] = destDt.name
                getAvailableInteriorNamesFromInterior(destDt.dCId, checked, res)
            end
        end
    end

    return res
end


---@return table<string, table<string, string>> res by destination cell id - by cell id - cell name
local function getAvailableExteriorNamesFromInterior(cellId, checked, res)
    checked = checked or {}
    res = res or {}

    if checked[cellId] then return res end
    checked[cellId] = true

    for _, destDt in pairs(mapDataHandler.entrances[cellId] or {}) do
        if not checked[destDt.dCId] then
            if destDt.isDEx then
                res[destDt.dCId] = res[destDt.dCId] or {}
                res[destDt.dCId][cellId] = destDt.name
            else
                getAvailableExteriorNamesFromInterior(destDt.dCId, checked, res)
            end
        end
    end

    return res
end


---@param cellId string
---@return table<string, advancedWorldMap.dynamicDataHandler.entranceData> res by pos hash
local function getWorldEntrancesForCell(cellId)
    local res = {}

    local exteriorCells = getAvailableExteriorNamesFromInterior(cellId)
    for exCellId, from in pairs(exteriorCells) do
        for _, dt in pairs(mapDataHandler.entrances[exCellId] or {}) do
            if from[dt.dCId] then
                res[getPosHash(nil, dt.pos)] = dt
            end
        end
    end

    return res
end


---@param menu advancedWorldMap.ui.menu.map
---@return {cellId : string?, pos : {x : number, y : number}, text : string, color : any, dist : number?, priority : number?}[]
local function getResults(menu, str, showUnrevealed, searchAllLocations)
    local res = {}

    local mapWidget = menu.mapWidget

    local entrances = mapDataHandler.entrances or {}

    local checked = {}
    local function processCell(cellId, isExterior, inInteriors)
        if checked[cellId] then return end
        checked[cellId] = true

        if isExterior == nil then isExterior = cellId:find(commonData.exteriorCellLabel) and true or false end

        local name = mapDataHandler.cellNameById[cellId] or string.format("%s: \"%s\"", l10n("CellId"), cellId)
        local nameLower = stringLib.utf8_lower(name)

        if not isExterior and nameLower:find(str) and (showUnrevealed or discoveredLocations.isDiscovered(cellId)) then
            local doors = mapDataHandler.entrances[cellId]
            local pos = {x = 0, y = 0}
            if doors then
                local cnt = #doors
                for _, d in pairs(doors) do
                    pos.x = pos.x + d.pos.x
                    pos.y = pos.y + d.pos.y
                end
                pos.x = pos.x / cnt
                pos.y = pos.y / cnt
            end

            table.insert(res, {
                text = name,
                cellId = cellId,
                pos = pos,
                priority = 0,
                color = config.data.ui.foundMarkerColor
            })
        end

        if inInteriors then
            if isExterior then
                for _, dt in pairs(mapDataHandler.entrances[cellId] or {}) do
                    if checked[dt.dCId] then goto continue end
                    checked[dt.dCId] = true

                    local destNameLower = stringLib.utf8_lower(dt.name)
                    if destNameLower:find(str) and (showUnrevealed or discoveredLocations.isDiscovered(dt.dCId)) then
                        table.insert(res, {
                            text = dt.fName,
                            cellId = not dt.isEx and dt.cId or nil,
                            pos = dt.pos,
                            priority = 0,
                            color = config.data.ui.foundMarkerColor
                        })
                        targetCells[dt.dCId] = true
                    end

                    ::continue::
                end
            end

            for cId, cellName in pairs(getAvailableInteriorNamesFromInterior(cellId)) do
                processCell(cId, false, false)
            end
        end
    end


    if not searchAllLocations then
        if mapWidget.cellId then
            processCell(mapWidget.cellId, false, true)
        else
            for cellId, list in pairs(entrances) do
                if not cellId:find(commonData.exteriorCellLabel) then
                    goto continue
                end

                processCell(cellId, true, true)

                ::continue::
            end

            local names = mapDataHandler.cellNameData
            for name, dt in pairs(names) do
                if stringLib.utf8_lower(name):find(str) and (showUnrevealed or discoveredLocations.isDiscovered(name)) then
                    table.insert(res, {
                        text = dt.name,
                        cellId = nil,
                        pos = util.vector2(dt.posX, dt.posY),
                        priority = 100,
                        color = config.data.ui.foundMarkerColor
                    })
                end
            end
        end
    else
        local interiors = {}
        for cellId, list in pairs(entrances) do
            if not cellId:find(commonData.exteriorCellLabel) then
                table.insert(interiors, cellId)
                goto continue
            end

            processCell(cellId, true, true)

            ::continue::
        end

        for _, cellId in pairs(interiors) do
            processCell(cellId, false, true)
        end

        local names = mapDataHandler.cellNameData
        for name, dt in pairs(names) do
            if stringLib.utf8_lower(name):find(str) and (showUnrevealed or discoveredLocations.isDiscovered(name)) then
                table.insert(res, {
                    text = dt.name,
                    cellId = nil,
                    pos = util.vector2(dt.posX, dt.posY),
                    priority = 1,
                    color = config.data.ui.foundMarkerColor
                })
            end
        end
    end

    return res
end


---@param menu advancedWorldMap.ui.menu.map
local function create(menu)

    local textFilter = ""

    local showUnrevealed
    if localStorage.data[commonData.showUnrevealedFieldId] ~= nil then
        showUnrevealed = localStorage.data[commonData.showUnrevealedFieldId]
    else
        showUnrevealed = not config.data.legend.onlyDiscovered
    end

    local searchAllLocations = false
    if localStorage.data[commonData.searchAllLocationsFieldId] ~= nil then
        searchAllLocations = localStorage.data[commonData.searchAllLocationsFieldId]
    else
        searchAllLocations = true
    end


    local onMapElementCreatedCallback = function (e)
        if textFilter == "" then return end

        updateLayoutForMarker(e.marker, textFilter)

        if not showUnrevealed then return end
        local handler = e.marker
        local userData = handler:getUserData()
        if not (userData and (userData.type == commonData.doorMarkerType or userData.type == commonData.doorDescrMarkerType)) then
            return
        end

        local cellId = e.mapWidget.cellId
        if cellId == nil and not targetCells[userData.cellId or " "] then return end

        setMarkerVisibility(handler, true)
    end

    local worldMarkersData
    local mapInitCallbackFunc = function (e)
        if not worldMarkersData or e.cellId ~= nil then return end

        for _, dt in pairs(worldMarkersData) do
            createTemporaryMarker(dt.posHash, e.menu, dt.dt, dt.pos, dt.color, dt.text, dt.showZoomIn)
        end
        e.menu:update()
    end


    local onMapClosedCallback = function (e)
        resetMarkersVisibility()
    end


    local iconLayout = {
        type = ui.TYPE.Image,
        props = {
            resource = searchIcoTexture,
            anchor = util.vector2(0.5, 0.5),
            size = util.vector2(menu.headerHeight - 2, menu.headerHeight - 2),
            color = config.data.ui.defaultColor,
        }
    }

    local function onOpen(menu, content)
        local mapWidgetSize = menu.mapWidget:getSize()

        eventSys.registerHandler(eventSys.EVENT.onMapElementCreated, onMapElementCreatedCallback)
        eventSys.registerHandler(eventSys.EVENT.onMapClosed, onMapClosedCallback)

        local size = util.vector2(
            math.max(mapWidgetSize.x / 3, 250),
            mapWidgetSize.y
        )

        local scrollBoxContent = ui.content{}

        local scrollBoxSize = util.vector2(size.x, size.y - (config.data.ui.fontSize * 5))

        local scrollBoxLayout = scrollBox{
            updateFunc = menu.update,
            contentHeight = 0,
            leftOffset = 2,
            size = scrollBoxSize,
            position = util.vector2(0, config.data.ui.fontSize * 5),
            scrollAmount = config.data.ui.fontSize * 2,
            content = scrollBoxContent,
        }

        ---@type advancedWorldMap.ui.scrollBox
        local scrollBoxMeta = scrollBoxLayout.userData.scrollBoxMeta ---@diagnostic disable-line: need-check-nil

        local function fill(showUnrevealed, searchAllLocations)
            resetMarkersColor()
            removeTemporaryWorldMarkers()
            searchData = {}
            worldMarkersData = {}
            targetCells = {}
            uiUtils.clearContent(scrollBoxContent)

            if textFilter == "" then return end

            updateVisibilityForActiveMarkers(menu.mapWidget, textFilter)

            local results = getResults(menu, textFilter, showUnrevealed, searchAllLocations)

            eventSys.triggerEvent(eventSys.EVENT.onSearch, {results = results, filter = textFilter,
                params = {showUnrevealed = showUnrevealed, searchAllLocations = searchAllLocations}})

            for _, res in pairs(results) do
                local dist
                if menu.mapWidget.cellId then
                    if res.cellId == menu.mapWidget.cellId then
                        dist = commonData.distance2D(res.pos, playerRef.position)
                    end
                else
                    dist = commonData.distance2D(res.pos, playerPos.gexExteriorPos())
                end
                res.dist = dist or 0
                res.priority = res.priority or 0
            end

            table.sort(results, function (a, b)
                if a.priority ~= b.priority then
                    return a.priority > b.priority
                else
                    return a.dist < b.dist
                end
            end)

            local height = 0

            for _, dt in ipairs(results) do
                local text = dt.text or ""

                if dt.cellId then
                    targetCells[dt.cellId] = true
                end

                local posHash = getPosHash(dt.cellId, dt.pos)

                searchData[posHash] = searchData[posHash] or {}
                table.insert(searchData[posHash], dt)

                local function addWorldMarkerData(pHash, pos, color, tx, showZoomIn)
                    if not worldMarkersData[pHash] then
                        worldMarkersData[pHash] = {
                            posHash = pHash,
                            pos = pos,
                            color = color,
                            text = tx,
                            showZoomIn = showZoomIn,
                            dt = dt,
                        }
                    elseif worldMarkersData[pHash].color ~= color then
                        worldMarkersData[pHash].color = config.data.ui.foundMarkerColor
                    end
                end

                if dt.cellId == nil then
                    addWorldMarkerData(posHash, dt.pos, config.data.ui.foundMarkerColor, text)
                else
                    local entrances = getWorldEntrancesForCell(dt.cellId)
                    for pHash, entranceDt in pairs(entrances) do
                        addWorldMarkerData(pHash, entranceDt.pos, config.data.ui.foundMarkerLightColor, text, true)
                        targetCells[entranceDt.dCId] = true
                    end
                end

                local textHeight = uiUtils.getTextHeight(text, config.data.ui.fontSize, size.x, config.data.ui.textHeightMul)

                local textLay
                textLay = {
                    type = ui.TYPE.Text,
                    props = {
                        text = text,
                        textSize = config.data.ui.fontSize,
                        textColor = config.data.ui.defaultColor,
                        autoSize = false,
                        size = util.vector2(size.x, textHeight),
                        multiline = true,
                        wordWrap = true,
                        textShadow = true,
                        propagateEvents = false,
                    },
                    userData = {

                    },
                    events = {
                        mousePress = async:callback(function(e, layout)
                            scrollBoxMeta:mousePress(e)
                        end),

                        focusLoss = async:callback(function(e, layout)
                            scrollBoxMeta:focusLoss(e)

                            if layout.props.textShadowColor then
                                layout.props.textShadowColor = nil
                                menu:update()
                            end
                        end),

                        mouseMove = async:callback(function(e, layout)
                            scrollBoxMeta:mouseMove(e)

                            if layout.props.textShadowColor ~= config.data.ui.textShadowColor then
                                layout.props.textShadowColor = config.data.ui.textShadowColor
                                menu:update()
                            end
                        end),

                        mouseRelease = async:callback(function(e, layout)
                            if e.button ~= 1 then return end

                            scrollBoxMeta:mouseRelease(e)

                            if scrollBoxMeta.lastMovedDistance < 20 then
                                if menu.mapWidget.cellId ~= dt.cellId then
                                    menu:updateMapWidgetCell(dt.cellId)
                                end
                                menu.mapWidget:focusOnWorldPosition(dt.pos)
                                menu.mapWidget:updateMarkers()

                                menu:update()
                            end
                        end),
                    },
                }

                scrollBoxContent:add(textLay)
                scrollBoxContent:add(interval(0, config.data.ui.fontSize))

                height = height + config.data.ui.fontSize + textHeight
            end

            local worldMapWidget = menu:getCachedMapWidget()
            if worldMapWidget then
                for posHash, dt in pairs(worldMarkersData) do
                    createTemporaryMarker(posHash, menu, dt.dt, dt.pos, dt.color, dt.text, dt.showZoomIn)
                end
            else
                eventSys.registerHandler(eventSys.EVENT.onMapInitialized, mapInitCallbackFunc)
            end

            scrollBoxMeta:setScrollPosition(0)
            scrollBoxMeta:setContentHeight(height)
        end


        local showUnrevealedCBLayout = checkBox{
            updateFunc = menu.update,
            text = l10n("searchShowUnrevealed"),
            textSize = config.data.ui.fontSize * 0.9,
            position = util.vector2(2, config.data.ui.fontSize * 1.8),
            checked = showUnrevealed,
            event = function (checked, layout)
                showUnrevealed = checked
                localStorage.data[commonData.showUnrevealedFieldId] = checked
                fill(showUnrevealed, searchAllLocations)
                menu.mapWidget:updateMarkers()
                menu:update()
            end,
            tooltipContent = ui.content {
                {
                    type = ui.TYPE.TextEdit,
                    props = {
                        text = l10n("SearchShowUnrevealedTooltip"),
                        textSize = config.data.ui.fontSize,
                        textColor = config.data.ui.defaultColor,
                        autoSize = true,
                        multiline = true,
                        wordWrap = true,
                        readOnly = true,
                        size = util.vector2(math.max(300, uiUtils.getScaledScreenSize().x / 4), 0),
                    }
                }
            },
        }

        local searchAllLocationsCBLayout = checkBox{
            updateFunc = menu.update,
            text = l10n("searchAllLocationsCheckbox"),
            textSize = config.data.ui.fontSize * 0.9,
            position = util.vector2(2, config.data.ui.fontSize * 3.3),
            checked = searchAllLocations,
            event = function (checked, layout)
                searchAllLocations = checked
                localStorage.data[commonData.searchAllLocationsFieldId] = checked
                fill(showUnrevealed, searchAllLocations)
                menu.mapWidget:updateMarkers()
                menu:update()
            end,
            tooltipContent = ui.content {
                {
                    type = ui.TYPE.TextEdit,
                    props = {
                        text = l10n("SearchAllLocationsTooltip"),
                        textSize = config.data.ui.fontSize,
                        textColor = config.data.ui.defaultColor,
                        autoSize = true,
                        multiline = true,
                        wordWrap = true,
                        readOnly = true,
                        size = util.vector2(math.max(300, uiUtils.getScaledScreenSize().x / 4), 0),
                    }
                }
            },
        }

        local searchBarLayout
        searchBarLayout = {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(size.x, config.data.ui.fontSize * 1.3 + 4),
            },
            content = ui.content {
                {
                    type = ui.TYPE.TextEdit,
                    props = {
                        text = "",
                        anchor = util.vector2(0, 0.5),
                        size = util.vector2(size.x - 114, config.data.ui.fontSize * 1.3),
                        textAlignV = ui.ALIGNMENT.Center,
                        textSize = config.data.ui.fontSize,
                        position = util.vector2(2, config.data.ui.fontSize * 1.3 / 2 + 2),
                        textColor = config.data.ui.defaultColor,
                    },
                    events = {
                        textChanged = async:callback(function(text, layout)
                            textFilter = stringLib.utf8_lower(text)
                        end),
                        keyRelease = async:callback(function(e, layout)
                            if e.code == input.KEY.Enter then
                                searchBarLayout.content[1].props.text = textFilter
                                fill(showUnrevealed, searchAllLocations)
                                menu.mapWidget:updateMarkers()
                                menu:update()
                            end
                        end),
                        focusLoss = async:callback(function(layout)
                            searchBarLayout.content[1].props.text = textFilter
                        end),
                    }
                },
                button{
                    updateFunc = menu.update,
                    text = l10n("Search"),
                    size = util.vector2(100, config.data.ui.fontSize * 0.9),
                    textSize = config.data.ui.fontSize * 0.9,
                    anchor = util.vector2(1, 0.5),
                    position = util.vector2(size.x - 2, config.data.ui.fontSize * 1.3 / 2 + 2),
                    event = function (layout)
                        fill(showUnrevealed, searchAllLocations)
                        menu.mapWidget:updateMarkers()
                        menu:update()
                    end
                },
                borders()
            }
        }


        local windowLayout = {
            type = ui.TYPE.Widget,
            props = {
                size = size,
                color = config.data.ui.defaultColor,
            },
            userData = {

            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    props = {
                        relativeSize = util.vector2(1, 1),
                        color = config.data.ui.backgroundColor,
                        resource = uiUtils.whiteTexture,
                    },
                },
                searchBarLayout,
                showUnrevealedCBLayout,
                searchAllLocationsCBLayout,
                scrollBoxLayout,
                borders()
            }
        }


        iconLayout.props.color = config.data.ui.whiteColor

        content:add(windowLayout)
    end

    local function onClose()
        iconLayout.props.color = config.data.ui.defaultColor
        resetMarkersVisibility()
        resetMarkersColor()
        removeTemporaryWorldMarkers()
        searchData = {}
        worldMarkersData = {}
        targetCells = {}
        eventSys.unregisterHandler(eventSys.EVENT.onMapElementCreated, onMapElementCreatedCallback)
        eventSys.unregisterHandler(eventSys.EVENT.onMapClosed, onMapClosedCallback)
        eventSys.unregisterHandler(eventSys.EVENT.onMapInitialized, mapInitCallbackFunc)
    end

    menu:addWidget{
        id = "AdvancedWorldMap:Search",
        layout = iconLayout,
        priority = 9800,
        onOpen = onOpen,
        onClose = onClose,
    }
end


eventSys.registerHandler(eventSys.EVENT["onMenuOpened"], function (e)
    create(e.menu)
end, 9800)
