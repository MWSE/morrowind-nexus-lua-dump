local core = require("openmw.core")
local util = require("openmw.util")
local ui = require("openmw.ui")
local types = require("openmw.types")
local playerRef = require("openmw.self")

local pDoor = require("scripts.advanced_world_map.helpers.protectedDoor")

local eventSys = require("scripts.advanced_world_map.eventSys")

local uiUtils = require("scripts.advanced_world_map.ui.utils")
local stringLib = require("scripts.advanced_world_map.utils.string")
local tableLib = require("scripts.advanced_world_map.utils.table")
local cellLib = require("scripts.advanced_world_map.utils.cell")
local dateLib = require("scripts.advanced_world_map.utils.date")

local commonData = require("scripts.advanced_world_map.common")
local mapDataHandler = require("scripts.advanced_world_map.mapDataHandler")
local mapTextureHandler = require("scripts.advanced_world_map.mapTextureHandler")
local discoveredLocs = require("scripts.advanced_world_map.discoveredLocations")
local disabledDoors = require("scripts.advanced_world_map.disabledDoors")

local config = require("scripts.advanced_world_map.config.configLib")

local tooltip = require("scripts.advanced_world_map.ui.tooltip")
local interval = require("scripts.advanced_world_map.ui.interval")

local l10n = core.l10n(commonData.l10nKey)

local mapMarkerTexture = ui.texture{ path = commonData.mapMarkerPath }
local mapMarker45Texture = ui.texture{ path = commonData.mapMarkerForExPath }


local this = {}


---@type advancedWorldMap.ui.menu.map?
this.activeMenuMeta = nil

---@type table<string, advancedWorldMap.ui.mapElementMeta[]>
this.markersByName = {}

---@type table<string, advancedWorldMap.ui.mapElementMeta[]>
this.entranceMarkersByDestCellId = {}

---@type table<string, advancedWorldMap.ui.mapElementMeta[]>
this.markersByDoorHash = {}

---@type table<string, advancedWorldMap.ui.mapElementMeta>
this.markerById = {}



---@param newDiscovered string[]
function this.updateDiscovered(newDiscovered)
    if not this.markersByName or not this.entranceMarkersByDestCellId then return end

    local function updateVisibility(handler)
        local userData = handler:getUserData()
        if not userData then return end
        userData.discovered = true
        if not userData.disabled and not userData.filtered then
            handler:setVisibility(true)
        else
            handler:updateParams{visible = true} ---@diagnostic disable-line: missing-fields
        end
    end

    for _, name in pairs(newDiscovered or {}) do
        for _, handler in pairs(this.entranceMarkersByDestCellId[name] or {}) do
            updateVisibility(handler)
            local userData = handler:getUserData()
            if userData and userData.cellId then
                if discoveredLocs.isVisited(userData.cellId) then
                    if userData.type == commonData.cityMarkerType then
                        handler:setColor(config.data.ui.worldDefaultLightColor)
                    else
                        handler:setColor(userData.useWorldColor and config.data.ui.worldDefaultLightColor or
                            config.data.ui.defaultLightColor)
                    end
                elseif discoveredLocs.isDiscovered(userData.cellId) then
                    if userData.type == commonData.cityMarkerType then
                        handler:setColor(config.data.ui.worldDefaultColor)
                    else
                        handler:setColor(userData.useWorldColor and config.data.ui.worldDefaultColor or
                            config.data.ui.markerDefaultColor)
                    end
                end
            end
        end

        for _, handler in pairs(this.markersByName[name] or {}) do
            local userData = handler:getUserData()
            if userData and userData.type == commonData.cityRegionMarkerType then
                updateVisibility(handler)
                handler:setColor(config.data.ui.worldDefaultLightColor)
            end
        end
    end
end


---@param marker advancedWorldMap.ui.mapElementMeta
local function updateDoorMarkerVisibility(marker, visible)
    local userData = marker:getUserData()
    if not userData then return end

    if userData.type == commonData.doorDescrMarkerType then
        if not userData.filtered then
            marker:setVisibility(visible)
        else
            marker:updateParams{visible = visible} ---@diagnostic disable-line: missing-fields
        end
        userData.disabled = not visible
    elseif userData.type == commonData.doorMarkerType then
        marker:setAlpha(visible and (config.data.legend.alpha.entrance * 0.01) or (config.data.legend.alpha.entrance * 0.01 / 3))
    end
end


function this.updateDoorMarkerVisibility(doorRef)
    local destCell = pDoor.destCell(doorRef)
    if not destCell then return end

    local doorHash = commonData.doorHash(doorRef, destCell.id)
    local visible = not disabledDoors.contains(doorRef)

    local markers = this.markersByDoorHash[doorHash]
    if not markers then return end

    for _, marker in pairs(markers) do
        updateDoorMarkerVisibility(marker, visible)
    end
end


---@return advancedWorldMap.ui.mapElementMeta?
function this.getMarkerById(id)
    return this.markerById[id]
end


---@param cellId string?
---@param x number
---@param y number
---@param label string?
---@return string
function this.getMarkerId(cellId, x, y, label)
    return string.format("%s_%s_%d_%d", label, cellId, x, y)
end


---@param widget advancedWorldMap.ui.mapWidgetMeta
local function createMarkers(widget, cellId)
    if eventSys.triggerEvent(eventSys.EVENT.onCellMarkersCreate, {mapWidget = widget, cellId = cellId}) then
        return
    end
    local entrances = mapDataHandler.entrances or {}

    local lineHeight = 10 * config.data.legend.markerSize * (widget.cellId and 0.5 or 1)
    local charHeight = 30 * config.data.legend.markerSize * (widget.cellId and 0.5 or 1)
    local mergeDist = 512 * 512

    local entrancesData = {}

    if cellId == nil then
        for cId, list in pairs(entrances) do
            if cId:find(commonData.exteriorCellLabel) then
                for _, dt in pairs(list) do
                    table.insert(entrancesData, dt)
                end
            end
        end
    else
        local entranceData = entrances[cellId]
        if not entranceData then return end

        for _, dt in pairs(entranceData) do
            table.insert(entrancesData, dt)
        end
    end

    local nameGroups = {}
    for _, dt in ipairs(entrancesData) do
        nameGroups[dt.name] = nameGroups[dt.name] or {}
        table.insert(nameGroups[dt.name], dt)
    end

    ---@type table<any, {dt: any, entries: any[], textMarker: advancedWorldMap.ui.mapElementMeta?}>
    local dataForTextMarkers = {}
    local allData = {}

    for _, entries in pairs(nameGroups) do
        local used = {}
        local entryCount = #entries
        for i = 1, entryCount do
            if not used[i] then
                used[i] = true

                local cluster = { entries[i] }
                local expanded = true
                for k = 1, 10 do
                    expanded = false
                    for j = 1, entryCount do
                        if not used[j] then
                            local ej = entries[j]
                            for _, cm in ipairs(cluster) do
                                local dx = cm.pos.x - ej.pos.x
                                local dy = cm.pos.y - ej.pos.y
                                if dx * dx + dy * dy <= mergeDist then
                                    used[j] = true
                                    table.insert(cluster, ej)
                                    expanded = true
                                    break
                                end
                            end
                        end
                    end

                    if not expanded then break end
                end

                local cx, cy = 0, 0
                for _, e in ipairs(cluster) do
                    cx = cx + e.pos.x
                    cy = cy + e.pos.y
                end
                local clusterSize = #cluster
                cx = cx / clusterSize
                cy = cy / clusterSize

                local bestEntry = cluster[1]
                local bestDist = math.huge
                for _, e in ipairs(cluster) do
                    local dx = e.pos.x - cx
                    local dy = e.pos.y - cy
                    local dsq = dx * dx + dy * dy
                    if dsq < bestDist then
                        bestDist = dsq
                        bestEntry = e
                    end
                end

                local repDt = bestEntry

                local dt = {
                    dt = repDt,
                    entries = cluster,
                    textMarker = nil,
                }
                table.insert(allData, dt)

                for _, e in ipairs(cluster) do
                    dataForTextMarkers[e] = dt
                end
            end
        end
    end

    ---@type table<integer, {dt: any, mInfo: any}[]>
    local entranceByLine = {}
    local maxLine, minLine

    for _, mInfo in ipairs(allData) do
        local dt = mInfo.dt
        local line = math.floor(dt.pos.y / lineHeight)
        entranceByLine[line] = entranceByLine[line] or {}
        table.insert(entranceByLine[line], { dt = dt, mInfo = mInfo })
        maxLine = math.max(maxLine or line, line)
        minLine = math.min(minLine or line, line)
    end

    for _, line in pairs(entranceByLine) do
        table.sort(line, function (a, b)
            return a.dt.pos.x < b.dt.pos.x
        end)
    end

    if minLine and maxLine then

        ---@type {[1] : number, [2] : number}[][]
        local textLines = {}
        for i = minLine - 1, maxLine + 1 do
            textLines[i] = {}
        end

        local anchors = {
            util.vector2(0, 0.5),
            util.vector2(1, 0.5),
            util.vector2(0.5, 1.5),
            util.vector2(0.5, -0.5),
            util.vector2(0.25, 1.5),
            util.vector2(0.75, 1.5),
            util.vector2(0.25, -0.5),
            util.vector2(0.75, -0.5),
        }

        for _, dt in ipairs(entrancesData) do
            local imgLine = math.floor(dt.pos.y / lineHeight)
            local imgS = dt.pos.x - charHeight / 2
            local imgE = dt.pos.x + charHeight / 2
            for k = -1, 1 do
                local lin = textLines[imgLine + k]
                if lin then
                    table.insert(lin, {imgS, imgE})
                end
            end
        end

        local function calcOverlap(s, e, intervals)
            local total = 0
            for _, interv in ipairs(intervals) do
                local os = math.max(s, interv[1])
                local oe = math.min(e, interv[2])
                if os < oe then
                    total = total + (oe - os)
                end
            end
            return total
        end

        for j, line in pairs(entranceByLine) do
            for i = #line, 1, -1 do
                local data = line[i]
                local dt = data.dt
                local mInfo = data.mInfo

                local textAnchor = anchors[4]
                local text = "  "..dt.name.."  "
                local textWidth = charHeight * stringLib.length(dt.name) * 0.5

                local currentLines = {}
                for k = -1, 1 do
                    if textLines[j + k] then
                        table.insert(currentLines, textLines[j + k])
                    end
                end
                local currentLine = textLines[j]

                do
                    local upperLine = textLines[j + 1]
                    local upperLines = {}
                    for k = 2, 4 do
                        if textLines[j + k] then
                            table.insert(upperLines, textLines[j + k])
                        end
                    end

                    local lowerLine = textLines[j - 1]
                    local lowerLines = {}
                    for k = -4, -2 do
                        if textLines[j + k] then
                            table.insert(lowerLines, textLines[j + k])
                        end
                    end

                    local funcs = {}

                    local function tryAnchor(arr, s, e, anchor)
                        local totalOverlap = 0
                        for _, lin in pairs(arr) do
                            totalOverlap = totalOverlap + calcOverlap(s, e, lin)
                        end

                        local func = function()
                            textAnchor = anchor
                            for _, lin in pairs(arr) do
                                table.insert(lin, {s, e})
                            end
                        end

                        if totalOverlap == 0 then
                            func()
                            return true
                        else
                            table.insert(funcs, { totalOverlap, func })
                        end
                    end

                    if lowerLine then
                        local s, e = dt.pos.x - textWidth / 2, dt.pos.x + textWidth / 2
                        if tryAnchor(lowerLines, s, e, anchors[4]) then
                            goto next
                        end
                    end

                    if currentLine then
                        local s, e = dt.pos.x + charHeight, dt.pos.x + textWidth
                        if tryAnchor(currentLines, s, e, anchors[1]) then
                            goto next
                        end

                        s, e = dt.pos.x - textWidth, dt.pos.x - charHeight
                        if tryAnchor(currentLines, s, e, anchors[2]) then
                            goto next
                        end
                    end

                    if lowerLine then
                        local s, e = dt.pos.x - textWidth * 0.25, dt.pos.x + textWidth * 0.75
                        if tryAnchor(lowerLines, s, e, anchors[7]) then
                            goto next
                        end
                        s, e = dt.pos.x - textWidth * 0.75, dt.pos.x + textWidth * 0.25
                        if tryAnchor(lowerLines, s, e, anchors[8]) then
                            goto next
                        end
                    end

                    if upperLine then
                        local s, e = dt.pos.x - textWidth / 2, dt.pos.x + textWidth / 2
                        if tryAnchor(upperLines, s, e, anchors[3]) then
                            goto next
                        end
                    end

                    if upperLine then
                        local s, e = dt.pos.x - textWidth * 0.25, dt.pos.x + textWidth * 0.75
                        if tryAnchor(upperLines, s, e, anchors[5]) then
                            goto next
                        end
                        s, e = dt.pos.x - textWidth * 0.75, dt.pos.x + textWidth * 0.25
                        if tryAnchor(upperLines, s, e, anchors[6]) then
                            goto next
                        end
                    end

                    table.sort(funcs, function(a, b)
                        return a[1] < b[1]
                    end)

                    if #funcs > 0 then
                        funcs[1][2]()
                    end

                end

                ::next::

                local textId = this.getMarkerId(cellId, dt.pos.x, dt.pos.y, "markerText")

                local cId = dt.dCId
                this.markersByName[dt.name] = this.markersByName[dt.name] or {}

                local isCellDiscovered = not config.data.legend.onlyDiscovered or discoveredLocs.isDiscovered(cId)

                local color
                if discoveredLocs.isDiscovered(dt.dCId) then
                    if discoveredLocs.isVisited(dt.dCId) then
                        color = config.data.ui.defaultLightColor
                    else
                        color = config.data.ui.markerDefaultColor
                    end
                else
                    color = config.data.ui.defaultDarkColor
                end

                local textMarkerHandler = widget:createTextMarker{
                    id = textId,
                    useCache = true,
                    layerId = widget.LAYER.nonInteractive,
                    text = text,
                    alpha = config.data.legend.alpha.entrance * 0.01,
                    anchor = textAnchor,
                    fontSize = config.data.legend.markerSize,
                    pos = dt.pos,
                    color = color,
                    showWhenZoomedIn = true,
                    visible = isCellDiscovered,
                    userData = {
                        type = commonData.doorDescrMarkerType,
                        cellId = dt.dCId,
                        hash = dt.dHash,
                        searchText = stringLib.utf8_lower(dt.name),
                        fullName = dt.fName,
                        allowSearchFilter = true,
                        imageMarker = nil,
                        anchor = textAnchor,
                    },
                }

                if textMarkerHandler then
                    local registeredCIds = {}
                    for _, clusterEntry in ipairs(mInfo.entries) do
                        local entryCId = clusterEntry.dCId
                        if not registeredCIds[entryCId] then
                            registeredCIds[entryCId] = true
                            this.entranceMarkersByDestCellId[entryCId] = this.entranceMarkersByDestCellId[entryCId] or {}
                            table.insert(this.entranceMarkersByDestCellId[entryCId], textMarkerHandler)
                        end
                    end

                    table.insert(this.markersByName[dt.name], textMarkerHandler)
                    this.markersByDoorHash[dt.dHash] = this.markersByDoorHash[dt.dHash] or {}
                    table.insert(this.markersByDoorHash[dt.dHash], textMarkerHandler)
                    if disabledDoors.contains(dt.dHash) then
                        updateDoorMarkerVisibility(textMarkerHandler, false)
                    end
                    this.markerById[textId] = textMarkerHandler
                    mInfo.textMarker = textMarkerHandler
                end
            end
        end

    end

    for _, dt in ipairs(entrancesData) do
        local mInfo = dataForTextMarkers[dt]
        local textMarkerHandler = mInfo and mInfo.textMarker or nil

        local imId = this.getMarkerId(cellId, dt.pos.x, dt.pos.y, "marker")

        local cId = dt.dCId
        this.entranceMarkersByDestCellId[cId] = this.entranceMarkersByDestCellId[cId] or {}
        this.markersByName[dt.name] = this.markersByName[dt.name] or {}
        this.markersByDoorHash[dt.dHash] = this.markersByDoorHash[dt.dHash] or {}

        local isCellDiscovered = not config.data.legend.onlyDiscovered or discoveredLocs.isDiscovered(cId)

        local color
        if discoveredLocs.isDiscovered(dt.dCId) then
            if discoveredLocs.isVisited(dt.dCId) then
                color = config.data.ui.defaultLightColor
            else
                color = config.data.ui.markerDefaultColor
            end
        else
            color = config.data.ui.defaultDarkColor
        end

        local imageMarkerHandler
        imageMarkerHandler = widget:createImageMarker{
            id = imId,
            texture = dt.isDLEx and mapMarker45Texture or mapMarkerTexture,
            color = color,
            useCache = true,
            layerId = widget.LAYER.marker,
            alpha = config.data.legend.alpha.entrance * 0.01,
            anchor = util.vector2(0.5, 0.5),
            size = util.vector2(config.data.legend.markerSize, config.data.legend.markerSize),
            pos = dt.pos,
            showWhenZoomedIn = true,
            visible = isCellDiscovered,
            userData = {
                type = commonData.doorMarkerType,
                cellId = dt.dCId,
                hash = dt.dHash,
                searchText = stringLib.utf8_lower(dt.name),
                allowSearchFilter = true,
                textMarker = textMarkerHandler,
                name = dt.name,
                fullName = dt.fName,
            },
            events = {
                mouseRelease = function (e, layout, pressed)
                    if e.button ~= 1 or not pressed or not this.activeMenuMeta then return end
                    if eventSys.triggerEvent(eventSys.EVENT.onMarkerClick, {marker = imageMarkerHandler}) then
                        return
                    end

                    this.activeMenuMeta:updateMapWidgetCell(dt.dCId)
                    if this.activeMenuMeta.mapWidget and dt.dPos then
                        this.activeMenuMeta.mapWidget:focusOnWorldPosition(dt.dPos)
                        this.activeMenuMeta.mapWidget:updateMarkers(true)
                    end

                    eventSys.triggerEvent(eventSys.EVENT.onMarkerClicked, {marker = imageMarkerHandler})
                    this.activeMenuMeta:update()
                end,

                mouseMove = function(e, layout)
                    if not tooltip.isExists(layout) then
                        local tooltipContent = ui.content{}
                        if eventSys.triggerEvent(eventSys.EVENT.onMarkerTooltipShow, {content = tooltipContent, marker = imageMarkerHandler}) then
                            return
                        end

                        if #tooltipContent > 0 then
                            local newTooltipContent = ui.content{}
                            for i = 1, #tooltipContent - 1 do
                                local item = tooltipContent[i]
                                newTooltipContent:add(item)
                                newTooltipContent:add(interval(0, config.data.ui.fontSize / 3))
                            end
                            newTooltipContent:add(tooltipContent[#tooltipContent])

                            layout.userData.tooltipContent = newTooltipContent
                            tooltip.createOrMove(e, layout, newTooltipContent)
                        else
                            layout.userData.tooltipContent = nil
                        end
                    elseif tooltip.createOrMove(e, layout) then
                        eventSys.triggerEvent(eventSys.EVENT.onMarkerTooltipShowed, {
                            marker = imageMarkerHandler,
                            content = layout.userData.tooltipContent,
                            tooltip = tooltip.get(layout)
                        })
                    end
                end,
            },
        }
        if imageMarkerHandler then
            table.insert(this.entranceMarkersByDestCellId[cId], imageMarkerHandler)
            table.insert(this.markersByName[dt.name], imageMarkerHandler)
            table.insert(this.markersByDoorHash[dt.dHash], imageMarkerHandler)
            if disabledDoors.contains(dt.dHash) then
                updateDoorMarkerVisibility(imageMarkerHandler, false)
            end
            this.markerById[imId] = imageMarkerHandler

            if textMarkerHandler then
                local userData = textMarkerHandler:getUserData()
                if userData then
                    userData.imageMarker = imageMarkerHandler
                end
            end
        end
    end


    if cellId == nil then
        for _, dt in pairs(mapDataHandler.cellNameData or {}) do
            local id = string.format("%s%d_%d", dt.name, dt.posX, dt.posY)

            local isCellDiscovered = not config.data.legend.onlyDiscovered or discoveredLocs.isDiscovered(dt.name) or
                types.Player.journal and types.Player.journal(playerRef).topics[dt.name] and true or false

            this.markersByName[dt.name] = this.markersByName[dt.name] or {}

            local textMarkerHandler = widget:createTextMarker{
                id = id,
                layerId = widget.LAYER.name,
                text = dt.name,
                anchor = util.vector2(0.5, 0.5),
                pos = util.vector2(dt.posX, dt.posY),
                color = discoveredLocs.isVisited(dt.name) and config.data.ui.worldDefaultLightColor or config.data.ui.worldDefaultColor,
                textShadow = config.data.ui.worldMarkerShadow and true or nil,
                shadowColor = config.data.ui.worldMarkerShadow and config.data.ui.worldMarkerShadowColor or nil,
                fontSize = util.round(config.data.legend.worldMarkerSize + math.min(8, dt.count) * 2),
                scaleFunc = widget.SCALE_FUNCTION.linear,
                alpha = config.data.legend.alpha.city * 0.01,
                useCache = true,
                showWhenZoomedOut = true,
                visible = isCellDiscovered,
                userData = {
                    type = commonData.cityRegionMarkerType,
                    searchText = stringLib.utf8_lower(dt.name),
                    allowSearchFilter = true,
                },
            }
            if textMarkerHandler then
                table.insert(this.markersByName[dt.name], textMarkerHandler)
                this.markerById[id] = textMarkerHandler
            end
        end


        for _, info in pairs(mapDataHandler.regionNameData or {}) do
            local fontSize = math.floor(config.data.legend.worldMarkerSize * 1.2 + math.min(8, info.count) * 3)
            widget:createTextMarker{
                layerId = widget.LAYER.region,
                text = info.name,
                anchor = util.vector2(0.5, 0.5),
                pos = util.vector2(info.posX, info.posY),
                color = discoveredLocs.isVisited(info.name) and config.data.ui.worldDefaultLightColor or config.data.ui.worldDefaultColor,
                fontSize = fontSize,
                scaleFunc = widget.SCALE_FUNCTION.linear,
                alpha = config.data.legend.alpha.region * 0.01,
                showWhenZoomedOut = true,
                useCache = true,
                searchText = stringLib.utf8_lower(info.name),
                searchLabel = l10n("Region")..": "..info.name,
                userData = {
                    type = commonData.cityRegionMarkerType,
                }
            }
        end
    end

    if not widget.cellId and widget.onZoomMarkersRect then
        this.onZoomMarkersUpdatedCallback{mapWidget = widget, region = widget.onZoomMarkersRect}
    end

    widget:update()
end


eventSys.registerHandler(eventSys.EVENT.onMarkerTooltipShow, function (e)
    local screenSize = uiUtils.getScaledScreenSize()
    local userData = e.marker:getUserData()
    if not userData then return end

    local text = userData.fullName or ""
    local tooltipWidth = math.max(250,
        math.min(screenSize.x / 5, stringLib.length(text) * config.data.ui.fontSize * config.data.ui.textHeightMul))

    e.content:add{
        type = ui.TYPE.TextEdit,
        props = {
            text = text,
            textColor = config.data.ui.defaultColor,
            textSize = config.data.ui.fontSize * 1.1,
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
end, 10000)


eventSys.registerHandler(eventSys.EVENT.onMapDestroyed, function (e)
    for _, marker in pairs(e.mapWidget:getRegisteredMarkers()) do
        if not marker.id or not this.markerById[marker.id] then goto continue end

        this.markerById[marker.id] = nil

        if marker.text then
            this.markersByName[marker.text] = nil
        end

        if not marker.userData then goto continue end

        if marker.userData.hash then
            this.markersByDoorHash[marker.userData.hash] = nil
        end

        if marker.userData.cellId then
            this.entranceMarkersByDestCellId[marker.userData.cellId] = nil
        end

        ::continue::
    end
end)


eventSys.registerHandler(eventSys.EVENT.onMarkerTooltipShow, function (e)
    local screenSize = uiUtils.getScaledScreenSize()
    local userData = e.marker:getUserData()
    if not userData then return end

    local lastVisited = discoveredLocs.isVisited(userData.cellId or "")
    if lastVisited then
        local lastVisitedText = l10n("LastVisited"):format(dateLib.getDateByTime(lastVisited))
        local width = math.max(250,
            math.min(screenSize.x / 5, stringLib.length(lastVisitedText) * config.data.ui.fontSize * config.data.ui.textHeightMul))

        e.content:add{
            type = ui.TYPE.TextEdit,
            props = {
                text = l10n("LastVisited"):format(dateLib.getDateByTime(lastVisited)),
                textColor = config.data.ui.defaultDarkColor,
                textSize = config.data.ui.fontSize,
                anchor = util.vector2(0.5, 0),
                size = util.vector2(width, 0),
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                readOnly = true,
                autoSize = true,
            },
        }
    end
end, -1000)


local function getClusterBoundingBox(cluster)
    local fpos = cluster[1]._params.pos
    local minX, maxX = fpos.x, fpos.x
    local minY, maxY = fpos.y, fpos.y
    for _, m in pairs(cluster) do
        local pos = m._params.pos
        if pos.x < minX then minX = pos.x end
        if pos.x > maxX then maxX = pos.x end
        if pos.y < minY then minY = pos.y end
        if pos.y > maxY then maxY = pos.y end
    end
    return {x = util.vector2(minX, minY), y = util.vector2(maxX, maxY), center = util.vector2((minX + maxX) / 2, (minY + maxY) / 2)}
end

local function gridClustering(markers, cellSize)
    local grid = {}
    for i, marker in ipairs(markers) do
        local pos = marker._params.pos
        local x = math.floor(pos.x / cellSize)
        local y = math.floor(pos.y / cellSize)
        local key = string.format("%d,%d", x, y)
        grid[key] = grid[key] or {x = x, y = y, m = {}}
        table.insert(grid[key].m, marker)
    end

    local clusters = {}

    local checked = {}
    local function addNearby(key, arr)
        local dt = grid[key]
        if not dt then return end

        for x = dt.x - 1, dt.x + 1 do
            for y = dt.y - 1, dt.y + 1 do
                local nKey = string.format("%d,%d", x, y)
                if checked[nKey] then goto continue end

                local nDt = grid[nKey]
                checked[nKey] = true
                if nDt then
                    tableLib.addValues(nDt.m, arr)
                    addNearby(nKey, arr)
                end

                ::continue::
            end
        end
    end


    for key, arr in pairs(grid) do
        if checked[key] then goto continue end

        local cluster = {}
        addNearby(key, cluster)

        table.insert(clusters, {
            c = cluster,
            bb = getClusterBoundingBox(cluster)
        })

        ::continue::
    end

    return clusters
end


local lastGroupState = nil
function this.onZoomMarkersUpdatedCallback(e)
    ---@type advancedWorldMap.ui.mapWidgetMeta
    local mapWidget = e.mapWidget
    if mapWidget.cellId or not mapWidget:isInZoomInMode() then return end

    local doGroup = mapWidget.zoom * 32 / mapWidget.mapInfo.pixelsPerCell <= config.data.legend.zoomToGroup
    local groupStateChanged = lastGroupState ~= doGroup
    lastGroupState = doGroup

    local markerList = {}

    local activeMarkers = mapWidget:getActiveMarkers()
    for _, marker in pairs(activeMarkers) do
        local userData = marker:getUserData()
        if not userData then goto continue end
        if userData.type == commonData.doorMarkerType then
            local defaultAlpha = marker:getAlpha()
            marker._elemLayout.props.alpha = defaultAlpha
            if doGroup then
                marker._elemLayout.props.alpha = defaultAlpha / 2
            end
            goto continue
        elseif userData.type ~= commonData.doorDescrMarkerType then
            goto continue
        end

        if groupStateChanged then
            ---@diagnostic disable-next-line: missing-fields
            marker:updateLayout{
                anchor = marker._params.anchor,
                pos = marker._params.pos,
                fontSize = marker._params.fontSize,
                alpha = marker._params.alpha,
                text = marker._params.text,
            }
        end

        if doGroup then
            table.insert(markerList, marker)
        end

        ::continue::
    end

    if not doGroup then return end

    local fsize = mapWidget.SCALE_FUNCTION.marker(config.data.legend.markerSize, mapWidget.zoom)

    local fontInWorldCoords = fsize * 8192 / (mapWidget.mapInfo.pixelsPerCell * mapWidget.zoom)

    local eps = 5.5 * fsize * 8192 / (mapWidget.mapInfo.pixelsPerCell * mapWidget.zoom) * config.data.ui.textHeightMul
    local clusters = gridClustering(markerList, eps)

    for _, cluster in pairs(clusters) do
        local count = #cluster.c
        if count <= 2 then goto continue end

        ---@type table<string, advancedWorldMap.ui.mapElementMeta>[]
        local quadrants = {{}, {}, {}, {}}

        for _, marker in pairs(cluster.c) do
            local pos = marker._params.pos
            if pos.x >= cluster.bb.center.x and pos.y >= cluster.bb.center.y then
                quadrants[2][marker._params.text] = marker
            elseif pos.x < cluster.bb.center.x and pos.y >= cluster.bb.center.y then
                quadrants[1][marker._params.text] = marker
            elseif pos.x < cluster.bb.center.x and pos.y < cluster.bb.center.y then
                quadrants[3][marker._params.text] = marker
            else
                quadrants[4][marker._params.text] = marker
            end

            ---@diagnostic disable-next-line: missing-fields
            marker:updateLayout{
                alpha = 0,
            }
        end

        for qn, quadrant in ipairs(quadrants) do
            quadrants[qn] = tableLib.values(quadrant, qn <= 2 and
                function (a, b)
                    return (a._params.pos.y < b._params.pos.y)
                end or
                function (a, b)
                    return (a._params.pos.y > b._params.pos.y)
                end
            )
        end

        local quadrantSize = util.vector2(
            (cluster.bb.y.x - cluster.bb.x.x) / 2,
            (cluster.bb.y.y - cluster.bb.x.y) / 2
        ) + util.vector2(fontInWorldCoords, fontInWorldCoords) * 12

        local newFontWorldSize = fontInWorldCoords
        local newFontSize = config.data.legend.markerSize

        for qn, quadrant in ipairs(quadrants) do
            if not next(quadrant) then goto continue end
            local c = #quadrant
            local columns = c <= 5 and 1 or math.ceil((c * newFontWorldSize) / quadrantSize.y)
            columns = util.clamp(columns, 1, 3)
            local columnWidth = columns == 1 and 999999 or quadrantSize.x / columns
            columnWidth = math.max(newFontWorldSize * 8 * config.data.ui.textHeightMul, columnWidth)
            local textMaxLength = columns <= 1 and 99 or math.floor(columnWidth / (newFontWorldSize * config.data.ui.textHeightMul))
            textMaxLength = math.max(8, textMaxLength)

            local qAnchor = util.vector2(
                (qn == 1 or qn == 3) and 1 or 0,
                (qn > 2) and 1 or 0
            )
            local posMulY = (qn <= 2) and 1 or -1
            local posMulX = (qn == 1 or qn == 3) and -1 or 1
            for i, marker in ipairs(quadrant) do

                local center = cluster.bb.center
                ---@diagnostic disable-next-line: missing-fields
                marker:updateLayout{
                    anchor = qAnchor,
                    pos = center + util.vector2((i % columns) * columnWidth * posMulX, (math.floor(i / columns)) *
                        newFontWorldSize * posMulY),
                    fontSize = newFontSize,
                    alpha = marker:getAlpha(),
                    text = stringLib.utf8_sub(marker._params.text, 2, textMaxLength) ..
                        ((stringLib.length(marker._params.text) - 2) > textMaxLength and "..." or "")
                }

            end

            ::continue::
        end

        ::continue::
    end
end
eventSys.registerHandler(eventSys.EVENT.onZoomMarkersUpdated, this.onZoomMarkersUpdatedCallback, 99999)


eventSys.registerHandler(eventSys.EVENT.onMapElementCreated, function (e)
    if e.mapWidget.cellId then return end

    local userData = e.marker:getUserData()
    if not userData or userData.type ~= commonData.doorMarkerType and userData.type ~= commonData.doorDescrMarkerType then
        return
    end
    if userData.useWorldColor ~= nil then return end

    local hasTexture = mapTextureHandler.isWorldLocalMapTextureExists(cellLib.getGridCoordinates(e.marker._params.pos))
    local color
    if discoveredLocs.isDiscovered(userData.cellId) then
        if discoveredLocs.isVisited(userData.cellId) then
            color = hasTexture and config.data.ui.defaultLightColor or config.data.ui.worldDefaultLightColor
        else
            color = hasTexture and config.data.ui.markerDefaultColor or config.data.ui.worldDefaultColor
        end
    else
        color = hasTexture and config.data.ui.defaultDarkColor or config.data.ui.worldDefaultDarkColor
    end
    userData.useWorldColor = not hasTexture
    e.marker:setColor(color)
    if disabledDoors.contains(userData.hash) then
        updateDoorMarkerVisibility(e.marker, false)
    end
end, 99999)


eventSys.registerHandler(eventSys.EVENT.onMenuOpened, function (e)
    this.activeMenuMeta = e.menu
end)

eventSys.registerHandler(eventSys.EVENT.onMapInitialized, function (e)
    createMarkers(e.mapWidget, e.cellId)
end)


return this