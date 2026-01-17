
local playerRef = require("openmw.self")
local util = require("openmw.util")

local localStorage = require("scripts.advanced_world_map.storage.localStorage")

local storageId = "lastPlayerExPos"


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


return this