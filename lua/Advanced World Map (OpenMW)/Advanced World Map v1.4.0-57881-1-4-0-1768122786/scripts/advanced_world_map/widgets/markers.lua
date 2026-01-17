local core = require("openmw.core")
local util = require("openmw.util")
local ui = require("openmw.ui")
local types = require("openmw.types")

local pDoor = require("scripts.advanced_world_map.helpers.protectedDoor")

local eventSys = require("scripts.advanced_world_map.eventSys")

local uiUtils = require("scripts.advanced_world_map.ui.utils")
local stringLib = require("scripts.advanced_world_map.utils.string")
local tableLib = require("scripts.advanced_world_map.utils.table")
local cellLib = require("scripts.advanced_world_map.utils.cell")
local dateLib = require("scripts.advanced_world_map.utils.date")

local commonData = require("scripts.advanced_world_map.common")
local mapDataHandler = require("scripts.advanced_world_map.mapDataHandler")
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
                    handler:setColor(config.data.ui.defaultLightColor)
                elseif discoveredLocs.isDiscovered(userData.cellId) then
                    handler:setColor(config.data.ui.markerDefaultColor)
                end
            end
        end

        for _, handler in pairs(this.markersByName[name] or {}) do
            local userData = handler:getUserData()
            if userData and userData.type == commonData.cityRegionMarkerType then
                updateVisibility(handler)
                handler:setColor(config.data.ui.defaultLightColor)
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
        marker:setAlpha(visible and (config.data.legend.alpha.entrance * 0.01) or (config.data.legend.alpha.entrance * 0.01 / 8))
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

    ---@type table<integer, {dt : advancedWorldMap.dynamicDataHandler.entranceData, startPos : number?, endPos : number?}[]>
    local entranceByLine = {}
    local lineHeight = 4 * config.data.legend.markerSize * uiUtils.getUIScale()
    local charWidth = 2 * 4 * config.data.legend.markerSize * uiUtils.getUIScale()
    local maxLine
    local minLine

    if cellId == nil then
        for cellId, list in pairs(entrances) do
            if not cellId:find(commonData.exteriorCellLabel) then
                goto continue
            end

            for _, dt in pairs(list) do
                local line = math.floor(dt.pos.y / lineHeight)
                entranceByLine[line] = entranceByLine[line] or {}
                table.insert(entranceByLine[line], {dt = dt})
                maxLine = math.max(maxLine or line, line)
                minLine = math.min(minLine or line, line)
            end

            ::continue::
        end
    else
        local entranceData = entrances[cellId]
        if not entranceData then return end

        for _, dt in pairs(entranceData) do
            local line = math.floor(dt.pos.y / lineHeight)
            entranceByLine[line] = entranceByLine[line] or {}
            table.insert(entranceByLine[line], {dt = dt})
            maxLine = math.max(maxLine or line, line)
            minLine = math.min(minLine or line, line)
        end
    end

    for _, line in pairs(entranceByLine) do
        table.sort(line, function (a, b)
            return a.dt.pos.x < b.dt.pos.x
        end)
    end


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

    local function isOverlap(s, e, intervals)
        for _, interv in ipairs(intervals) do
            local is, ie = interv[1], interv[2]
            if s <= ie and e >= is then
                return true
            end
        end
        return false
    end

    for j, line in pairs(entranceByLine) do
        for i = #line, 1, -1 do
            local data = line[i]
            local dt = data.dt

            local textAnchor = anchors[1]
            local text = "  "..dt.name
            local textWidth = (charWidth + 2) * stringLib.length(dt.name)

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

                local function calcTextAnchor(arr, s, e, anchor, name)
                    local valid = true
                    local cnt = 0
                    for _, lin in pairs(arr) do
                        if isOverlap(s, e, lin) then
                            valid = false
                        else
                            cnt = cnt + 1
                        end
                    end

                    local func = function ()
                        textAnchor = anchor
                        text = name
                        for _, lin in pairs(arr) do
                            table.insert(lin, {s, e})
                        end
                    end

                    if valid then
                        func()
                        return true
                    else
                        table.insert(funcs, {cnt, func})
                    end
                end

                if currentLine then
                    local s, e = dt.pos.x, dt.pos.x + textWidth
                    if calcTextAnchor(currentLines, s, e, anchors[1], "  "..dt.name) then
                        goto next
                    end

                    s, e = dt.pos.x - textWidth, dt.pos.x
                    if calcTextAnchor(currentLines, s, e, anchors[2], dt.name.."  ") then
                        goto next
                    end
                end

                if upperLine then
                    local s, e = dt.pos.x - textWidth / 2, dt.pos.x + textWidth / 2
                    if calcTextAnchor(upperLines, s, e, anchors[3], dt.name) then
                        goto next
                    end
                end

                if lowerLine then
                    local s, e = dt.pos.x - textWidth / 2, dt.pos.x + textWidth / 2
                    if calcTextAnchor(lowerLines, s, e, anchors[4], dt.name) then
                        goto next
                    end
                end

                if upperLine then
                    local s, e = dt.pos.x - textWidth * 0.25, dt.pos.x + textWidth * 0.75
                    if calcTextAnchor(upperLines, s, e, anchors[5], dt.name) then
                        goto next
                    end
                    s, e = dt.pos.x - textWidth * 0.75, dt.pos.x + textWidth * 0.25
                    if calcTextAnchor(upperLines, s, e, anchors[6], dt.name) then
                        goto next
                    end
                end

                if lowerLine then
                    local s, e = dt.pos.x - textWidth * 0.25, dt.pos.x + textWidth * 0.75
                    if calcTextAnchor(lowerLines, s, e, anchors[7], dt.name) then
                        goto next
                    end
                    s, e = dt.pos.x - textWidth * 0.75, dt.pos.x + textWidth * 0.25
                    if calcTextAnchor(lowerLines, s, e, anchors[8], dt.name) then
                        goto next
                    end
                end

                table.sort(funcs, function (a, b)
                    return a[1] > b[1]
                end)

                if funcs[1][1] ~= 0 then
                    funcs[1][2]()
                else
                    tableLib.shuffle(funcs)
                    funcs[1][2]()
                end

            end

            ::next::

            for _, ln in pairs(currentLines) do
                table.insert(ln, {dt.pos.x - charWidth / 2, dt.pos.x + charWidth / 2})
            end

            local imId = this.getMarkerId(cellId, dt.pos.x, dt.pos.y, "marker")
            local textId = this.getMarkerId(cellId, dt.pos.x, dt.pos.y, "markerText")

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
                    searchText = stringLib.utf8_lower(dt.name),
                    allowSearchFilter = true,
                    imageMarker = nil,
                    anchor = textAnchor,
                },
            }
            if textMarkerHandler then
                table.insert(this.entranceMarkersByDestCellId[cId], textMarkerHandler)
                table.insert(this.markersByName[dt.name], textMarkerHandler)
                table.insert(this.markersByDoorHash[dt.dHash], textMarkerHandler)
                if disabledDoors.contains(dt.dHash) then
                    updateDoorMarkerVisibility(textMarkerHandler, false)
                end
                this.markerById[textId] = textMarkerHandler
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
                            this.activeMenuMeta.mapWidget:updateMarkers()
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
    end


    for _, dt in pairs(mapDataHandler.cellNameData or {}) do
        local id = string.format("%s%d_%d", dt.name, dt.posX, dt.posY)

        local isCellDiscovered = not config.data.legend.onlyDiscovered or discoveredLocs.isDiscovered(dt.name)

        this.markersByName[dt.name] = this.markersByName[dt.name] or {}

        local textMarkerHandler = widget:createTextMarker{
            id = id,
            layerId = widget.LAYER.name,
            text = dt.name,
            anchor = util.vector2(0.5, 0.5),
            pos = util.vector2(dt.posX, dt.posY),
            color = discoveredLocs.isVisited(dt.name) and config.data.ui.defaultLightColor or config.data.ui.markerDefaultColor,
            fontSize = 10 + math.min(8, dt.count) * 2,
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
        local fontSize = 14 + math.min(8, info.count) * 3
        widget:createTextMarker{
            layerId = widget.LAYER.region,
            text = info.name,
            anchor = util.vector2(0.5, 0.5),
            pos = util.vector2(info.posX, info.posY),
            color = discoveredLocs.isVisited(info.name) and config.data.ui.defaultLightColor or config.data.ui.markerDefaultColor,
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

    widget:updateMarkers()
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
            textColor = config.data.ui.markerDefaultColor,
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


eventSys.registerHandler(eventSys.EVENT.onMenuOpened, function (e)
    this.activeMenuMeta = e.menu
end)

eventSys.registerHandler(eventSys.EVENT.onMapInitialized, function (e)
    createMarkers(e.mapWidget, e.cellId)
end)


return this