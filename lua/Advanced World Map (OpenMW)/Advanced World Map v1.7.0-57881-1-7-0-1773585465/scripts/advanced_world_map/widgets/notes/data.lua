local util = require("openmw.util")
local playerRef = require("openmw.self")
local NPC = require("openmw.types").NPC
local storage = require("openmw.storage")

local commonData = require("scripts.advanced_world_map.common")
local localStorage = require("scripts.advanced_world_map.storage.localStorage")
local mapDataHandler = require("scripts.advanced_world_map.mapDataHandler")
local tableLib = require("scripts.advanced_world_map.utils.table")
local celllLib = require("scripts.advanced_world_map.utils.cell")

local config = require("scripts.advanced_world_map.config.config")


local this = {}

this.data = nil


local function getDataTable()
    return this.data
end


function this.getMarkerId(plName, cellId, pos)
    return string.format("%s_%s_%d_%d", plName or NPC.record(playerRef.recordId).name, cellId or commonData.exteriorMapId, pos.x, pos.y)
end


local function getOldDataTable()
    if not localStorage.isPlayerStorageReady() then return end

    local data = localStorage.data[commonData.notesFieldId]
    localStorage.data[commonData.notesFieldId] = nil

    if data then
        local newData = {}
        for cellId, cellData in pairs(data) do
            newData[cellId] = {}
            for id, dt in pairs(cellData) do
                dt.plName = NPC.record(playerRef.recordId).name or ""
                local nId = this.getMarkerId(dt.plName, cellId, dt.pos)
                newData[cellId][nId] = dt
            end
        end
        return newData
    end
end


---@class advancedWorldMap.widget.notes.data.markerData
---@field cellId string?
---@field pos Vector2
---@field name string?
---@field descr string?
---@field colorId integer?
---@field nameColorId integer?
---@field namePosId integer?
---@field plName string?
---@field icon string?
---@field size number?
---@field onWorldMap boolean?

---@class advancedWorldMap.widget.notes.data.addMarkerDataParams
---@field cellId string?
---@field pos Vector2
---@field name string?
---@field descr string?
---@field colorId integer?
---@field nameColorId integer?
---@field namePosId integer?
---@field plName string?
---@field icon string?
---@field size number?
---@field onWorldMap boolean?

this.colors = {
    commonData.defaultColor,
    util.color.rgb(1, 0, 0),
    util.color.rgb(0, 1, 0),
    util.color.rgb(0, 0, 1),
    util.color.rgb(1, 1, 0),
    util.color.rgb(1, 0, 1),
    util.color.rgb(0, 1, 1),
    util.color.rgb(1, 1, 1),
}


this.markerSizeNames = {
    "S",
    "M",
    "L",
    "X1",
    "X2",
    "X3",
}


---@param params advancedWorldMap.widget.notes.data.addMarkerDataParams|advancedWorldMap.widget.notes.data.markerData
---@param onWorldMap boolean?
---@return advancedWorldMap.widget.notes.data.markerData?
function this.addMarkerData(params, onWorldMap)
    local cellId = params.cellId or commonData.exteriorMapId
    local id = this.getMarkerId(params.plName, cellId, params.pos)

    local dataTable = getDataTable()
    if not dataTable then return end

    dataTable[cellId] = dataTable[cellId] or {}
    local dt = {
        cellId = params.cellId,
        pos = params.pos,
        name = params.name,
        descr = params.descr,
        colorId = params.colorId,
        nameColorId = params.nameColorId,
        namePosId = params.namePosId,
        plName = params.plName,
        icon = params.icon,
        size = params.size,
        onWorldMap = params.onWorldMap
    }
    if onWorldMap ~= nil then
        params.onWorldMap = onWorldMap
        dt.onWorldMap = onWorldMap
    end
    dataTable[cellId][id] = dt

    return dt
end


---@param id string
---@param cellId string?
---@return advancedWorldMap.widget.notes.data.markerData?
function this.getMarkerData(id, cellId)
    local dataTable = getDataTable()
    if not dataTable then return end

    cellId = cellId or commonData.exteriorMapId

    if not dataTable[cellId] then return end

    return dataTable[cellId][id]
end


---@param data advancedWorldMap.widget.notes.data.markerData
function this.getMarkerDataAlt(data)
    local dataTable = getDataTable()
    if not dataTable then return end

    local cellId = data.cellId or commonData.exteriorMapId
    local id = this.getMarkerId(data.plName, cellId, data.pos)

    return this.getMarkerData(id, cellId)
end


---@param id string
---@param cellId string?
function this.removeMarkerData(id, cellId)
    local dataTable = getDataTable()
    if not dataTable then return end

    cellId = cellId or commonData.exteriorMapId

    if not dataTable[cellId] then return end

    dataTable[cellId][id] = nil
end


---@param data advancedWorldMap.widget.notes.data.markerData
function this.removeMarkerDataAlt(data)
    local dataTable = getDataTable()
    if not dataTable then return end

    local cellId = data.cellId or commonData.exteriorMapId
    local id = this.getMarkerId(data.plName, cellId, data.pos)

    return this.removeMarkerData(id, cellId)
end


---@param cellId string? nil for exterior map
function this.hasCellNotes(cellId)
    local dataTable = getDataTable()
    if not dataTable then return false end

    cellId = cellId or commonData.exteriorMapId

    if not dataTable[cellId] then return false end

    return next(dataTable[cellId]) ~= nil
end


---@param cellId string? nil for exterior map
function this.getCellData(cellId)
    local dataTable = getDataTable()
    if not dataTable then return false end

    cellId = cellId or commonData.exteriorMapId

    if not dataTable[cellId] then return false end

    return dataTable[cellId]
end


---@param cellId string?
---@return fun(): (cellId: string, id: string, data: advancedWorldMap.widget.notes.data.markerData)
function this.getCellIterator(cellId)
    local dataTable = getDataTable()
    if not dataTable then return coroutine.wrap(function() end) end

    local function iterator()
        cellId = cellId or commonData.exteriorMapId

        for id, markerData in pairs(dataTable[cellId] or {}) do
            coroutine.yield(cellId, id, markerData)
        end

    end

    return coroutine.wrap(iterator)
end


---@return fun(): (cellId: string, id: string, data: advancedWorldMap.widget.notes.data.markerData)
function this.getIterator()
    local dataTable = getDataTable()
    if not dataTable then return coroutine.wrap(function() end) end

    local function iterator()
        for cellId, cellData in pairs(dataTable) do
            for id, markerData in pairs(cellData) do
                coroutine.yield(cellId, id, markerData)
            end
        end
    end

    return coroutine.wrap(iterator)
end


---@param dt advancedWorldMap.widget.notes.data.markerData
---@return string
function this.getPosText(dt)
    local cellId = not dt.cellId and celllLib.getCellIdByPos(dt.pos) or dt.cellId
    local str = string.format("%s (%d, %d)", mapDataHandler.cellNameById[cellId] or "", dt.pos.x, dt.pos.y)
    return str
end


---@param dt advancedWorldMap.widget.notes.data.markerData
---@param includeCellPos boolean? default=true
---@param insertLineBreaks boolean? default=true
function this.getDataText(dt, includeCellPos, insertLineBreaks)
    local text = ""
    if dt.name and dt.name ~= "" then
        text = text.."#"..this.colors[dt.nameColorId or 1]:asHex()..dt.name.."#"..config.data.ui.defaultColor:asHex()
    end
    if dt.descr and dt.descr ~= "" then
        text = text ~= "" and text..(insertLineBreaks ~= false and "\n\n" or "\n") or text
        text = text..dt.descr
    end
    if includeCellPos ~= false then
        text = text ~= "" and text..(insertLineBreaks ~= false and "\n\n" or "\n") or text
        local cellId = not dt.cellId and celllLib.getCellIdByPos(dt.pos) or dt.cellId
        local str = string.format("%s (%d, %d)", mapDataHandler.cellNameById[cellId] or "", dt.pos.x, dt.pos.y)
        text = text..str
    end

    return text
end


function this.loadData()
    local notesStorage = storage.playerSection(commonData.notesStorageName)
    local dt = notesStorage:asTable() or {}
    this.data = dt[commonData.notesFieldId] or {}

    local oldData = getOldDataTable()
    if oldData then
        tableLib.addMissing(this.data, oldData)
    end
end


function this.saveData()
    local notesStorage = storage.playerSection(commonData.notesStorageName)
    notesStorage:set(commonData.notesFieldId, this.data)
end


return this