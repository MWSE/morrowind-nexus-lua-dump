local log = require("leeches.log")
local utils = require("leeches.utils")

local LIFESPAN_MIN_HOURS = 1
local LIFESPAN_MAX_HOURS = 3

--- A leech instance.
---
---@class Leech
---@field index LeechIndex
---@field expireTime LeechExpireTime
local Leech = {}
Leech.__index = Leech

--- Create a new leech instance.
---
---@param index LeechIndex
---@param timestamp number
---@return Leech
function Leech:new(index, timestamp)
    local lifespan = utils.rand(LIFESPAN_MIN_HOURS, LIFESPAN_MAX_HOURS)
    local data = {
        index = index,
        expireTime = timestamp + lifespan,
    }
    return setmetatable(data, Leech)
end

---@return string
function Leech:getName()
    return ("Leech - %d"):format(self.index)
end

---@param ref tes3reference
---@return niNode?
function Leech:getSceneNode(ref)
    return ref.sceneNode:getObjectByName(self:getName()) ---@diagnostic disable-line
end

--- Adds visuals for this leech on the given reference.
---
---@param ref tes3reference
function Leech:addVisuals(ref)
    local attachPoints = utils.getAttachPoints()
    local attachNode = attachPoints[self.index]
    if attachNode == nil then
        log:warn("No attach node for index: %d", self.index)
        return
    end

    local parentName = attachNode.parent.name
    local name = self:getName()

    for sceneNode in utils.get1stAnd3rdSceneNode(ref) do
        local parent = sceneNode:getObjectByName(parentName)
        if parent and parent:getObjectByName(name) == nil then
            local mesh = utils.getLeechMesh()
            mesh.name = name
            mesh:copyTransforms(attachNode) ---@diagnostic disable-line

            parent:attachChild(mesh) ---@diagnostic disable-line
            parent:update()
            parent:updateEffects()
            parent:updateProperties()
        end
    end
end

function Leech:__tojson(state)
    return json.encode({
        index = self.index,
        expireTime = self.expireTime,
    }, state)
end

return Leech
