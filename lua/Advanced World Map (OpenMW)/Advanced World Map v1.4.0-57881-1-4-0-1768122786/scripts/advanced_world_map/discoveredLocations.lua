local core = require("openmw.core")

local stringLib = require("scripts.advanced_world_map.utils.string")
local tableLib = require("scripts.advanced_world_map.utils.table")

local commonData = require("scripts.advanced_world_map.common")

local localStorage = require("scripts.advanced_world_map.storage.localStorage")

local this = {}


---@type table<string, number> by cell id or cell name
this.visited = {}
---@type table<string, boolean> by cell id or cell name
this.discovered = {}

this.blockDiscovery = false


function this.addVisitedCell(cell)
    local timeStamp = core.getGameTime()
    if not this.visited[cell.id] then
        local res = {cell.id}

        this.visited[cell.id] = timeStamp
        local cellName = cell.displayName or cell.name or ""
        if cellName ~= "" then
            if cell.isExterior then
                this.visited[cellName] = timeStamp
                table.insert(res, cellName)
            elseif cellName:find(",") then
                local name = stringLib.getBeforeComma(cellName)
                this.visited[name] = timeStamp
                table.insert(res, name)
            end
        end

        return res
    else
        this.visited[cell.id] = timeStamp
    end
end


function this.addDiscoveredCell(cell, addNearbyExteriors)
    if this.blockDiscovery then return end

    local newDiscovered = {}

    if cell.isExterior and addNearbyExteriors then
        for i = -1, 1 do
            for j = -1, 1 do
                local cId = commonData.exteriorCellIdFormat:format(cell.gridX + i, cell.gridY + j)
                if not this.discovered[cId] then
                    this.discovered[cId] = true
                    newDiscovered[cId] = true
                end
            end
        end
    end

    if not this.discovered[cell.id] then
        this.discovered[cell.id] = true
        newDiscovered[cell.id] = true

        local cellName = cell.displayName or cell.name
        if cellName:find(",") then
            local name = stringLib.getBeforeComma(cellName)
            this.discovered[name] = true
            newDiscovered[name] = true
        end
    end

    if next(newDiscovered) then
        return tableLib.keys(newDiscovered)
    end
end


function this.init()
    if not localStorage.isPlayerStorageReady() then return end

    if not localStorage.data[commonData.visitedLocsFieldId] then
        localStorage.data[commonData.visitedLocsFieldId] = {}
    end
    this.visited = localStorage.data[commonData.visitedLocsFieldId]

    if not localStorage.data[commonData.discoveredLocsFieldId] then
        localStorage.data[commonData.discoveredLocsFieldId] = {}
    end
    this.discovered = localStorage.data[commonData.discoveredLocsFieldId]
end


---@return boolean
function this.isDiscovered(name)
    return this.discovered[name] and true or false
end


---@param id string
---@return number?
function this.isVisited(id)
    return this.visited[id]
end



return this