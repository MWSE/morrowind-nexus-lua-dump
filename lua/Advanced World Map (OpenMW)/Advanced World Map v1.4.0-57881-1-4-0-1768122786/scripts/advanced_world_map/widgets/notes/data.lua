local util = require("openmw.util")

local commonData = require("scripts.advanced_world_map.common")
local localStorage = require("scripts.advanced_world_map.storage.localStorage")
local mapDataHandler = require("scripts.advanced_world_map.mapDataHandler")

local config = require("scripts.advanced_world_map.config.config")


local function getDataTable()
    if not localStorage.isPlayerStorageReady() then return end

    localStorage.data[commonData.notesFieldId] = localStorage.data[commonData.notesFieldId] or {}

    return localStorage.data[commonData.notesFieldId]
end



local this = {}


function this.getMarkerId(cellId, pos)
    return string.format("%s_%d_%d", cellId or commonData.exteriorMapId, pos.x, pos.y)
end


---@class advancedWorldMap.widget.notes.data.markerData
---@field cellId string?
---@field pos Vector2
---@field name string?
---@field descr string?
---@field colorId integer?
---@field nameColorId integer?
---@field namePosId integer?

---@class advancedWorldMap.widget.notes.data.addMarkerDataParams
---@field cellId string?
---@field pos Vector2
---@field name string?
---@field descr string?
---@field colorId integer?
---@field nameColorId integer?
---@field namePosId integer?


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


---@param params advancedWorldMap.widget.notes.data.addMarkerDataParams|advancedWorldMap.widget.notes.data.markerData
---@return advancedWorldMap.widget.notes.data.markerData?
function this.addMarkerData(params)
    local cellId = params.cellId or commonData.exteriorMapId
    local id = this.getMarkerId(cellId, params.pos)

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
    }
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
    local id = this.getMarkerId(cellId, data.pos)

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
    local id = this.getMarkerId(cellId, data.pos)

    return this.removeMarkerData(id, cellId)
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
function this.getDataText(dt)
    local text = ""
    if dt.name and dt.name ~= "" then
        text = text.."#"..this.colors[dt.nameColorId or 1]:asHex()..dt.name.."#"..config.data.ui.defaultColor:asHex().."\n\n"
    end
    do
        local cellId = not dt.cellId and commonData.exteriorCellIdFormat:format(dt.pos.x / 8192, dt.pos.y / 8192) or dt.cellId
        local str = string.format("%s (%d, %d)", mapDataHandler.cellNameById[cellId] or "", dt.pos.x, dt.pos.y)
        text = text..str
    end
    if dt.descr and dt.descr ~= "" then
        text = text.."\n\n"..dt.descr
    end

    return text
end


return this