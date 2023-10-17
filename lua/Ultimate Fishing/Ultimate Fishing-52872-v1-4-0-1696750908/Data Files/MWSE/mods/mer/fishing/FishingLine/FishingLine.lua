local config = require("mer.fishing.config")

local MESH_PATH = "mer_fishing\\fishing_line.nif"

---@class FishingLine
---@field sceneNode niNode
---@field curveData niKeyframeData
---@field tension number
---@field lerping boolean true while tension is being updated, blocks other updates
local FishingLine = {}
FishingLine.__index = FishingLine

--- Create a new fishing line.
---
---@return FishingLine
function FishingLine.new()
    local self = setmetatable({}, FishingLine)
    self.sceneNode = assert(tes3.loadMesh(MESH_PATH, false)):clone() --[[@as niNode]]
    self.curveData = self.sceneNode.children[1].controller.data
    self.tension = 1.0
    return self
end

--- Attach the fishing line to a parent node.
---
---@param parent niNode
function FishingLine:attachTo(parent)
    parent:attachChild(self.sceneNode)
    parent:update()
    parent:updateEffects()
    parent:updateProperties()
end

function FishingLine:remove()
    self.sceneNode.parent:detachChild(self.sceneNode)
    self.sceneNode = nil
    self.curveData = nil
end


function FishingLine:getTension()
    return self.tension
end

--[[
    Gradually change tension over a given duration
]]
function FishingLine:lerpTension(to, duration)
    if self.lerping then
        error("already lerping")
        return
    end

    local interval = 0.01
    local iterations = math.floor(duration / interval)

    local from = self.tension or 0
    local totalChange = to - from
    local delta = totalChange / iterations
    timer.start{
        duration = interval,
        iterations = iterations,
        callback = function(e)
            if self.sceneNode then
                self.tension = self.tension + delta
            end
        end
    }
end

function FishingLine:setTension(tension)
    if self.lerping then
        error("already lerping")
        return
    end
    self.tension = tension
end


--- Update the fishing line's end points and tension.
---
---@param origin tes3vector3
---@param destination tes3vector3
function FishingLine:updateEndPoints(origin, destination)
    -- Recenter the fishing line to the origin position.
    self.sceneNode.translation = origin

    -- Convert absolute position into relative position.
    local position = destination - origin

    -- Apply the calculated position and tension values.
    local keys = self.curveData.positionKeys
    local midp = keys[2]
    local endp = keys[3]
    midp.value = position
    midp.tension = math.clamp(self.tension, -1.0, 1.0)
    endp.value = position * 2
    endp.value.z = 0
    self.curveData:updateDerivedValues()
    if tes3.is3rdPerson() then
        self.sceneNode:update()
    end
end

return FishingLine