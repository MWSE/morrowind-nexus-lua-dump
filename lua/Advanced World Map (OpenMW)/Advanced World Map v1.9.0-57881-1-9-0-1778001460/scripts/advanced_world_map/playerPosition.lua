
local playerRef = require("openmw.self")
local util = require("openmw.util")

local common = require("scripts.advanced_world_map.common")
local localStorage = require("scripts.advanced_world_map.storage.localStorage")

local cellHelper = require("scripts.advanced_world_map.helpers.cell")

local storageId = "lastPlayerExPos"

local posDIffThreshold = 16384


local this = {}


this.lastExPos = util.vector3(-8482, -73627, 232)


function this.checkPos()
    if playerRef.cell and playerRef.cell.isExterior then
        local pos = playerRef.position
        this.lastExPos = pos
        if localStorage.isPlayerStorageReady() then
            localStorage.data[storageId] = {x = pos.x, y = pos.y, z = pos.z}
        end
    end
end


function this.init()
    if playerRef.cell and playerRef.cell.isExterior then
        this.checkPos()
    elseif localStorage.isPlayerStorageReady() and localStorage.data[storageId] then
        local p = localStorage.data[storageId]
        this.lastExPos = util.vector3(p.x, p.y, p.z)
    end
end


function this.gexExteriorPos()
    this.checkPos()
    return this.lastExPos
end


function this.updateExteriorPos()
    if not playerRef.cell or playerRef.cell.isExterior then return end

    local cellId = playerRef.cell.id
    local exitPoss = cellHelper.findExitPoss(cellId)
    if not exitPoss or not next(exitPoss) then return end

    for _, pos in pairs(exitPoss) do
        if common.distance2D(pos, this.lastExPos) < posDIffThreshold then
            return
        end
    end

    local _, pos = next(exitPoss)
    this.lastExPos = pos
end


return this