local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local playerRef = require("openmw.self")

local config = require("scripts.quest_guider_lite.config")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local dataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")
local questBase = require("scripts.quest_guider_lite.questBase")
local commonInfo = require("scripts.quest_guider_lite.common")
local localStorage = require("scripts.quest_guider_lite.storage.localStorage")
local protectedDoor = require("scripts.quest_guider_lite.helpers.protectedDoor")

local trackingMenu = require("scripts.quest_guider_lite.ui.trackingMenu")

local l10n = core.l10n(commonInfo.l10nKey)
local storageLabel = commonInfo.aWMIntegrationDataLabel

local this = {}

---@module "scripts.quest_guider_lite.trackingLocal"
this.trackingLib = nil


---@type AdvancedWorldMap.Interface
local interface
---@type AdvWMap_tracking.Interface
local trackingInt

local initialized = false

this.storageData = {}

---@type table<string, table<string, boolean>> by cellId, templateId = true
this.targetCells = {}
---@type table<string, table<string, boolean>> by cellId, templateId = true
this.pathCells = {}
---@type table<string, table<string, table<string, string>>> by cellId, doorHash, templateId = advWMapMarkerId
this.doorMarkers = {}
---@type table<string, {qNames: string[], mId: string}> by doorHash
this.doorGiversMarkers = {}
---@type string
this.doorGiversTemplate = nil
---@type table<string, boolean> by templateId
this.markerTemplatesVis = {}

this.giverMarkersVisible = true

---@type AdvancedWorldMap.Menu.Map?
this.activeMenu = nil
---@type questGuider.ui.trackingMenuMeta
this.widgetMeta = nil

---@type number
this.doorMarkerSize = 6


---@param cellId string
---@param marker AdvancedWorldMap.MapElement
---@param templatesByDHash table<string, table<string, boolean>>?
local function checkMapElement(cellId, marker, templatesByDHash)
    local userData = marker:getUserData()
    if not userData or userData.type ~= "AdvWMap:DoorMarker" then return end

    local destCellId = userData.cellId
    if not templatesByDHash and (not destCellId or not this.targetCells[destCellId]) then return end

    local dHash = userData.hash
    if not dHash then return end

    if not templatesByDHash then
        templatesByDHash = {}
        for templateId, _ in pairs(this.targetCells[destCellId]) do
            templatesByDHash[dHash] = templatesByDHash[dHash] or {}
            templatesByDHash[dHash][templateId] = true
        end
    end

    this.doorMarkers[cellId or ""] = this.doorMarkers[cellId or ""] or {}
    local doorMarkers = this.doorMarkers[cellId or ""]

    for templateId, _ in pairs(templatesByDHash[dHash] or {}) do
        local template = trackingInt.getTemplate(templateId)

        if not template then goto continue end

        if template.invalid then
            if doorMarkers[dHash] then
                local id = doorMarkers[dHash][templateId]
                if id then
                    doorMarkers[dHash][id] = nil

                    if not next(doorMarkers[dHash]) then
                        doorMarkers[dHash] = nil
                    end
                end
            end

            goto continue
        end

        if doorMarkers[dHash] and doorMarkers[dHash][templateId] then goto continue end

        local id = trackingInt.addMarker{
            template = templateId,
            positions = {{pos = marker._params.pos, id = cellId}},
            short = true,
            priority = template.userData and template.userData.priority or nil,
        }

        if id then
            doorMarkers[dHash] = doorMarkers[dHash] or {}
            doorMarkers[dHash][templateId] = id
        end

        ::continue::
    end
end



function this.init()
    if initialized then return true end

    if not localStorage.isPlayerStorageReady() then return false end

    if not localStorage.data then return false end
    if not localStorage.data[storageLabel] then
        localStorage.data[storageLabel] = {}
    end

    this.storageData = localStorage.data[storageLabel]
    if this.storageData.giversVisibility == nil then
        this.storageData.giversVisibility = true
    end
    if this.storageData.markersVisibility == nil then
        this.storageData.markersVisibility = true
    end
    if this.storageData.markerTemplatesVis == nil then
        this.storageData.markerTemplatesVis = {}
    end
    this.markerTemplatesVis = this.storageData.markerTemplatesVis

    ---@type AdvancedWorldMap.Interface
    interface = I.AdvancedWorldMap
    ---@type AdvWMap_tracking.Interface
    trackingInt = I.AdvWMap_tracking
    if not interface or not trackingInt or interface.version < 10 then
        return false
    end

    this.doorMarkerSize = interface.getConfig().legend.markerSize

    local events = interface.events


    events.registerHandler(events.EVENT.onMenuOpened, function (e)
        this.activeMenu = e.menu
    end)


    events.registerHandler(events.EVENT.onMenuClosed, function (e)
        this.activeMenu = nil
        this.widgetMeta = nil
    end)


    events.registerHandler(events.EVENT.onMapShown, function (e)
        if not e.isNew and not config.data.tracking.advWMapMarkers.enabled or
            not config.data.tracking.advWMapMarkers.details.markers then return end

        local dt = this.getTemplatesByDHashTable(e.mapWidget)
        for _, marker in pairs(e.mapWidget:getActiveMarkers()) do
            checkMapElement(e.mapWidget.cellId, marker, dt)
        end
    end)


    -- events.registerHandler(events.EVENT.onMapElementCreated, function (e)
    --     if e.mapWidget.cellId then return end
    --     if not config.data.tracking.advWMapMarkers.enabled or
    --         not config.data.tracking.advWMapMarkers.details.markers then return end

    --     checkMapElement(e.mapWidget.cellId, e.marker)
    -- end)


    events.registerHandler(events.EVENT.onMapDestroyed, function (e)
        this.doorMarkers[e.mapWidget.cellId or ""] = nil
    end)


    events.registerHandler(events.EVENT.onMarkerTooltipShow, function (e)
        if not config.data.tracking.advWMapMarkers.enabled or
            not config.data.tracking.advWMapMarkers.details.markers then return end

        local mapWidget = e.marker._parent
        local cellId = mapWidget.cellId
        local userData = e.marker:getUserData()
        if not userData then return end
        local destCellId = userData.cellId
        local dHash = userData.hash
        if not destCellId or not dHash or
                (not this.pathCells[destCellId] and not this.targetCells[destCellId] and
                not (this.doorMarkers[cellId] and this.doorMarkers[cellId][dHash])) then return end

        local names = {}

        local function processTemplate(templateId)
            local template = trackingInt.getTemplate(templateId)
            if not template or not template.userData or not template.visible then return end

            local diaId = template.userData.diaId
            local index = template.userData.index
            local objname = template.userData.objName
            local color = template.userData.color

            local questName = playerQuests.getQuestNameByDiaId(diaId)
            if not questName then return end

            names[questName] = names[questName] or {}
            if objname then
                names[questName][objname] = color
            end
        end

        for templateId, _ in pairs(this.targetCells[destCellId] or {}) do
            processTemplate(templateId)
        end
        for templateId, _ in pairs(this.pathCells[destCellId] or {}) do
            if not cellId or not (this.targetCells[cellId] and this.targetCells[cellId][templateId]) then
                processTemplate(templateId)
            end
        end
        if this.doorMarkers[cellId] and this.doorMarkers[cellId][dHash] then
            for templ, _ in pairs(this.doorMarkers[cellId][dHash]) do
                processTemplate(templ)
            end
        end

        local size = util.vector2(uiUtils.getTooltipWidth(), 0)

        for qName, objects in pairs(names) do
            local strs = {}

            table.insert(strs, string.format("\"%s\"", qName))

            local cnt = 0
            for objName, color in pairs(objects) do
                if cnt == 0 then
                    table.insert(strs, ": ")
                end

                table.insert(strs, string.format("%s#%s%s#%s",
                    cnt ~= 0 and ", " or "", color:asHex(), objName, interface.getConfig().ui.defaultColor:asHex()))

                cnt = cnt + 1
            end

            if cnt > 0 then table.insert(strs, ".") end

            local text = table.concat(strs)

            e.content:add{
                type = ui.TYPE.TextEdit,
                props = {
                    text = text,
                    textColor = interface.getConfig().ui.defaultColor,
                    textSize = interface.getConfig().ui.fontSize,
                    anchor = util.vector2(0.5, 0.5),
                    size = size,
                    multiline = true,
                    wordWrap = true,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                    readOnly = true,
                    autoSize = true,
                }
            }
        end
    end, 8)


    this.updateGiversMarker(true)


    local dmSize = util.vector2(1, 1) * math.floor(config.data.tracking.advWMapMarkers.size * 0.6)
    local dmAnchor = util.vector2(0.5, (this.doorMarkerSize * 0.5 + dmSize.y) / dmSize.y + 0.2)
    this.doorGiversTemplate = trackingInt.addTemplate{
        path = commonInfo.mapGiverMarkerPath,
        size = dmSize,
        layer = "nonInteractive",
        anchor = dmAnchor,
        color = config.data.ui.defaultColor,
        visible = this.giverMarkersVisible and this.storageData.giversVisibility or false,
    }

    ---@param e AdvancedWorldMap.Event.onTrackingTooltipShowEvent
    events.registerHandler("onTrackingTooltipShow", function (e)
        if e.markerId ~= this.questGiverMarker or not e.object then return end
        if not config.data.tracking.questGivers then return end

        local dialogIds = questBase.getGiverQuests(e.object)
        if not dialogIds then return end

        local qNames = {}
        for diaId, _ in pairs(dialogIds) do
            local qName = playerQuests.getQuestNameByDiaId(diaId)
            if qName then
                qNames[qName] = true
            end
        end
        if not next(qNames) then return end
        qNames = tableLib.keys(qNames)

        local text = stringLib.getValueEnumString(qNames, config.data.journal.objectNames, l10n("starts").." %s")
        local size = util.vector2(uiUtils.getTooltipWidth(), 0)
        e.content:add{
            type = ui.TYPE.TextEdit,
            props = {
                text = text,
                textColor = interface.getConfig().ui.defaultColor,
                textSize = interface.getConfig().ui.fontSize,
                anchor = util.vector2(0.5, 0.5),
                size = size,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                readOnly = true,
                autoSize = true,
            }
        }
    end)


    events.registerHandler(events.EVENT.onMarkerTooltipShow, function (e)
        if not config.data.tracking.advWMapMarkers.enabled or
            not config.data.tracking.advWMapMarkers.details.givers or
            not this.storageData.giversVisibility then return end

        local userData = e.marker:getUserData()
        if not userData or not userData.hash then return end

        local doorMarkerData = this.doorGiversMarkers[userData.hash]
        if not doorMarkerData then return end

        if not trackingInt.isValid(doorMarkerData.mId) then
            this.doorGiversMarkers[userData.hash] = nil
            trackingInt.removeMarker(doorMarkerData.mId)
            return
        end

        local text = stringLib.getValueEnumString(doorMarkerData.qNames, config.data.journal.objectNames, l10n("doorGiverMessage"))
        local size = util.vector2(uiUtils.getTooltipWidth(), 0)
        e.content:add{
            type = ui.TYPE.TextEdit,
            props = {
                text = text,
                textColor = interface.getConfig().ui.defaultColor,
                textSize = interface.getConfig().ui.fontSize,
                anchor = util.vector2(0.5, 0.5),
                size = size,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                readOnly = true,
                autoSize = true,
            }
        }
    end)


    events.registerHandler(events.EVENT.onLegendWidgetCreate, function (e)

        local flexContent = ui.content{}
        local cfg = interface.getConfig()

        local size = e.size

        local function addVPadding(elem, padding)
            return {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(
                        size.x,
                        (elem.props.textSize or elem.props.size and elem.props.size.y or cfg.ui.fontSize) * (padding or 1.5)
                    ),
                },
                content = ui.content{
                    elem
                }
            }
        end

        local label = {
            type = ui.TYPE.Text,
            props = {
                text = l10n("quests"),
                textSize = cfg.ui.fontSize,
                textColor = cfg.ui.defaultColor,
                autoSize = true,
                anchor = util.vector2(0, 0.5),
                position = util.vector2(4, cfg.ui.fontSize * 0.75),
            },
        }

        local markersCB = interface.uiElements.checkbox{
            updateFunc = e.menu.update,
            text = l10n("markers"),
            textSize = cfg.ui.fontSize,
            anchor = util.vector2(0, 0.5),
            position = util.vector2(cfg.ui.fontSize, cfg.ui.fontSize * 0.75),
            checked = this.storageData.markersVisibility,
            getScrollBoxMeta = function ()
                return e.scrollBox
            end,
            event = function (checked, layout)
                this.storageData.markersVisibility = checked
                this.updateMarkerTemplatesVisibility()
                trackingInt.update()
            end
        }

        local giversCB = interface.uiElements.checkbox{
            updateFunc = e.menu.update,
            text = l10n("givers"),
            textSize = cfg.ui.fontSize,
            anchor = util.vector2(0, 0.5),
            position = util.vector2(cfg.ui.fontSize, cfg.ui.fontSize * 0.75),
            checked = this.storageData.giversVisibility,
            getScrollBoxMeta = function ()
                return e.scrollBox
            end,
            event = function (checked, layout)
                this.storageData.giversVisibility = checked
                this.updateGiverMarkersVisibility()
                trackingInt.update()
            end
        }

        flexContent:add(
            addVPadding(label)
        )
        flexContent:add(
            addVPadding(markersCB)
        )
        flexContent:add(
            addVPadding(giversCB)
        )

        e.content:add{
            type = ui.TYPE.Flex,
            props = {
                horizontal = false,
            },
            content = flexContent,
        }
    end, 50)


    events.registerHandler(events.EVENT.onMenuOpened, function (e)
        if not config.data.tracking.advWMapMarkers.enabled then return end

        local layout = {
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture{path = commonInfo.mapWidgetIcoPath},
                size = util.vector2(e.menu.headerHeight - 2, e.menu.headerHeight - 2) * 0.9,
                anchor = util.vector2(0.5, 0.5),
                color = interface.getConfig().ui.defaultColor,
            }
        }

        ---@param m AdvancedWorldMap.Menu.Map
        ---@param content Content
        local function onOpen(m, content)
            if not this.trackingLib then return end

            layout.props.color = interface.getConfig().ui.whiteColor

            local mapWidgetSize = m.mapWidget:getSize()

            local size = util.vector2(
                math.max(mapWidgetSize.x * 0.4, 200),
                mapWidgetSize.y
            )

            local qListMeta = trackingMenu.createContent{
                updateFunc = m.update,
                size = size,
                advWMapInt = interface,
                advWMapMenu = m,
                advWMapTrackingInt = trackingInt,
                createSBFunc = interface.uiElements.scrollBox,
                tooltipLib = interface.uiElements.tooltip,
                listMode = true,
            }

            if not qListMeta then return end

            this.widgetMeta = qListMeta

            qListMeta.layout.props.position = util.vector2(0, 1)

            local objectIds = tableLib.keys(this.trackingLib.markerByObjectId)
            core.sendGlobalEvent("QGL:getPositionsForTrackingMenu", {
                objectIds = objectIds,
                advWMapMode = true,
                player = playerRef.object,
            })

            content:add{
                type = ui.TYPE.Widget,
                props = {
                    size = size,
                },
                content = ui.content{
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = commonInfo.whiteTexture,
                            color = interface.getConfig().ui.backgroundColor,
                            size = size,
                        }
                    },
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture{ path = "textures/menu_thin_border_right.dds" },
                            tileH = false,
                            tileV = true,
                            size = util.vector2(2, 0),
                            relativeSize = util.vector2(0, 1),
                            anchor = util.vector2(1, 0),
                            relativePosition = util.vector2(1, 0),
                        },
                    },
                    qListMeta.layout,
                }
            }
        end

        local function onClose()
            layout.props.color = interface.getConfig().ui.defaultColor
        end

        e.menu:addWidget{
            id = commonInfo.advWMapWidgetId,
            layout = layout,
            priority = 0,
            onOpen = onOpen,
            onClose = onClose,
        }
    end)


    initialized = true
    return true
end


function this.addPosDataToWidget(posData)
    if not this.widgetMeta then return end

    this.widgetMeta.positions = posData
end


---@return string
local function doorHash(doorRef, destCellId)
    local doorPos = doorRef.position
    local destCellIdHash = destCellId:sub(-10)
    local cellIdHash = doorRef.cell.id:sub(-10)
    return string.format("%s_%d_%d_%s", cellIdHash, math.floor(doorPos.x / 256), math.floor(doorPos.y / 256), destCellIdHash)
end


function this.getTemplatesByDHashTable(mapWidget)
    local cellId = mapWidget.cellId
    if not cellId then return end

    local maxDepth = 6
    local arr = {}

    ---@param eDt AdvancedWorldMap.DataHandler.EntranceData
    local function processCell(parentDHash, eDt, depth)
        if eDt.dCId:find(commonInfo.exteriorCellLabel) or depth > maxDepth or (depth > 1 and eDt.dHash == parentDHash) then return end
        arr[eDt.dCId] = arr[eDt.dCId] or {d = depth, dHashes = {[depth] = {[parentDHash] = true}}}
        if arr[eDt.dCId].d >= depth then
            arr[eDt.dCId].d = depth
            arr[eDt.dCId].dHashes[depth] = arr[eDt.dCId].dHashes[depth] or {}
            arr[eDt.dCId].dHashes[depth][parentDHash] = true
        else
            return
        end

        local entrances = interface.getEntranceMarkerData(eDt.dCId)
        if not entrances then return end

        for _, dt in pairs(entrances) do
            processCell(parentDHash, dt, depth + 1)
        end
    end

    local entrances = interface.getEntranceMarkerData(cellId)
    for _, dt in pairs(entrances or {}) do
        processCell(dt.dHash, dt, 1)
    end

    local templatesByDHash = {}
    for cId, dt in pairs(arr) do
        if cId ~= cellId and this.targetCells[cId] then
            for templateId, _ in pairs(this.targetCells[cId]) do
                for h, _ in pairs(dt.dHashes[dt.d] or {}) do
                    templatesByDHash[h] = templatesByDHash[h] or {}
                    templatesByDHash[h][templateId] = true
                end
            end
        end
    end

    return templatesByDHash
end


function this.updateDoorMarkers()
    if not this.activeMenu then return end
    local mapWidget = this.activeMenu.mapWidget
    local dt = this.getTemplatesByDHashTable(mapWidget)
    for _, marker in pairs(mapWidget:getActiveMarkers()) do
        checkMapElement(mapWidget.cellId, marker, dt)
    end
end


function this.createDoorGiversMarker(doorRef, qNames)
    if not initialized then return end
    local destCell = protectedDoor.destCell(doorRef)
    if not destCell then return end

    local destCellId = destCell.id
    local isDiscovered = not interface.getConfig().legend.onlyDiscovered or interface.isDiscovered(destCellId)

    local markerId = trackingInt.addMarker{
        template = this.doorGiversTemplate,
        positions = {{pos = doorRef.position, id = not doorRef.cell.isExterior and doorRef.cell.id or nil}},
        short = true,
        priority = -100,
        isVisibleFn = not isDiscovered and function (markerDt)
            local discovered = interface.isDiscovered(destCellId)
            if discovered then
                markerDt.isVisibleFn = nil
            end
            return discovered
        end or nil,
    }
    if not markerId then return end

    local hash = doorHash(doorRef, destCellId)
    this.doorGiversMarkers[hash] = {qNames = qNames, mId = markerId}
end


function this.updateGiversMarker(force)
    if not force and not initialized then return end

    if this.questGiverMarker then
        trackingInt.removeMarker(this.questGiverMarker)
        this.questGiverMarker = nil
    end

    if not config.data.tracking.questGivers or not config.data.tracking.advWMapMarkers.enabled or
            not config.data.tracking.advWMapMarkers.details.givers then
        if this.questGiverTemplate then
            trackingInt.removeTemplate(this.questGiverTemplate)
            this.questGiverTemplate = nil
        end
        return
    end

    this.questGiverTemplate = this.questGiverTemplate or trackingInt.addTemplate{
        path = commonInfo.mapGiverMarkerPath,
        pathA = commonInfo.mapGiverMarkerUpPath,
        pathB = commonInfo.mapGiverMarkerDownPath,
        size = util.vector2(1, 1) * config.data.tracking.advWMapMarkers.size,
        anchor = util.vector2(0.5, 0.8),
        visible = this.giverMarkersVisible and this.storageData.giversVisibility or false,
        color = config.data.ui.defaultColor,
        tText = "@name@",
        tEvent = true,
        onClick = commonInfo.advWMapGiverCallback,
        userData = {
            type = "questGiver",
        },
    }

    this.questGiverMarker = trackingInt.addMarker{
        template = this.questGiverTemplate,
        types = {"NPC", "Creature"},
        alive = true,
        priority = 8,
        objValidateFn = function (marker, template, object)
            if not config.data.tracking.advWMapMarkers.enabled or
                not config.data.tracking.advWMapMarkers.details.givers then return false end

            local giverQuests = questBase.getGiverQuests(object)

            if giverQuests then
                return true
            else
                return false
            end
        end,
    }
end


function this.setGiverMarkersVisibility(val)
    if not initialized then return end

    this.giverMarkersVisible = val
    if this.questGiverTemplate then
        trackingInt.setTemplateVisibility(this.questGiverTemplate, val and this.storageData.giversVisibility or false)
    end
    if this.doorGiversTemplate then
        trackingInt.setTemplateVisibility(this.doorGiversTemplate, val and this.storageData.giversVisibility or false)
    end
end


function this.updateGiverMarkersVisibility()
    if not initialized then return end

    this.setGiverMarkersVisibility(this.giverMarkersVisible)
end


function this.updateCellMarkers()
    if not initialized then return end

    if this.activeMenu then
        this.activeMenu.mapWidget:updateOnZoomMarkers(true)
    end
end


---@param markerId string
---@param table table<string, any>
function this.registerTargetCells(markerId, table)
    for cellId, _ in pairs(table) do
        this.targetCells[cellId] = this.targetCells[cellId] or {}
        this.targetCells[cellId][markerId] = true
    end
end


---@param markerId string
---@param table table<string, any>
function this.unregisterTargetCells(markerId, table)
    for cellId, _ in pairs(table) do
        local dt = this.targetCells[cellId]
        if dt then
            dt[markerId] = nil
            if not next(dt) then
                this.targetCells[cellId] = nil
            end
        end
    end
end


---@param markerId string
---@param table table<string, any>
function this.registerPathCells(markerId, table)
    for cellId, _ in pairs(table) do
        this.pathCells[cellId] = this.pathCells[cellId] or {}
        this.pathCells[cellId][markerId] = true
    end
end


---@param markerId string
---@param table table<string, any>
function this.unregisterPathCells(markerId, table)
    for cellId, _ in pairs(table) do
        local dt = this.pathCells[cellId]
        if dt then
            dt[markerId] = nil
            if not next(dt) then
                this.pathCells[cellId] = nil
            end
        end
    end
end


function this.setMarkerTemplateVisibility(templateId, visible)
    this.markerTemplatesVis[templateId] = visible or false

    if not initialized then return end

    local vis = this.storageData.markersVisibility and visible or false
    if not trackingInt.setTemplateVisibility(templateId, vis) then
        this.markerTemplatesVis[templateId] = nil
    end
end


function this.updateMarkerTemplatesVisibility()
    for templateId, visible in pairs(this.markerTemplatesVis) do
        this.setMarkerTemplateVisibility(templateId, visible)
    end
end


function this.unregisterTemplate(templateId)
    this.markerTemplatesVis[templateId] = nil
end




return this