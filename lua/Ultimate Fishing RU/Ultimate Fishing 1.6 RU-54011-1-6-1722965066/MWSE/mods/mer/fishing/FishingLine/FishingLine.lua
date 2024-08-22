local config = require("mer.fishing.config")
local common = require("mer.fishing.common")
local logger = common.createLogger("FishingLine")

local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")
local MESH_PATH = "mer_fishing\\fishing_line.nif"

---@class FishingLine
---@field sceneNode niNode
---@field curveData niKeyframeData
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
    if self.sceneNode and self.sceneNode.parent then
        self.sceneNode.parent:detachChild(self.sceneNode)
        self.sceneNode = nil
    end
    self.curveData = nil
end


--- Update the fishing line's end points and tension.
---
---@param origin tes3vector3
---@param destination tes3vector3
function FishingLine:updateEndPoints(origin, destination)
    local minTension = config.constants.TENSION_MINIMUM
    local maxTension = config.constants.TENSION_LINE_ROD_TRANSITION
    local tension = math.remap(FishingStateManager.getTension(), minTension, maxTension, 0, 1)
    tension = math.clamp(tension, 0, 1)

    logger:debug("Fishing line tension: %s", tension)
    -- Recenter the fishing line to the origin position.
    self.sceneNode.translation = origin

    -- Convert absolute position into relative position.
    local position = destination - origin

    -- Apply the calculated position and tension values.
    local keys = self.curveData.positionKeys
    local midp = keys[2]
    local endp = keys[3]
    midp.value = position
    midp.tension = tension
    endp.value = position * 2
    endp.value.z = 0
    self.curveData:updateDerivedValues()

    self.sceneNode:update()
    for node in table.traverse({ self.sceneNode }) do
        node:update{ controllers = true, time = 0 }
    end
end

return FishingLine