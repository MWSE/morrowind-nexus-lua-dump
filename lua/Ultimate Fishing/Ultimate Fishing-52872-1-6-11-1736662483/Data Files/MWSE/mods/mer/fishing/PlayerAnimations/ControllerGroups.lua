---@class ControllerGroup
---@field left niKeyframeController
---@field right niKeyframeController
---@field center niKeyframeController
---@field current niKeyframeController

---@class ControllerGroups
---@field controllersRoot niNode
---@field controllers table<string, ControllerGroup>
---@field targetRoot niNode
local ControllerGroups = {}
ControllerGroups.__index = ControllerGroups

--- Create a ControllerGroups.
---
---@param path string
---@return ControllerGroups
function ControllerGroups.new(path)
    local self = setmetatable({}, ControllerGroups)

    self.controllersRoot = tes3.loadMesh(path):clone() ---@diagnostic disable-line
    self.controllers = {}

    for _, root in pairs(self.controllersRoot.children) do
        for node in table.traverse(root.children) do
            if node.controller then
                local t = table.getset(self.controllers, node.name, {})
                t[root.name] = node.controller
            end
        end
    end

    return self
end

---@param pull number
---@param direction number
function ControllerGroups:update(pull, direction)
    local transition = math.abs(direction)

    self.controllersRoot:update({ controllers = true, time = pull })

    for _, controllers in pairs(self.controllers) do
        -- if direction is positive, interpolate from center to left.
        -- if direction is negative, interpolate from center to right.
        local from, to
        if direction > 0 then
            from = controllers.center.target
            to = controllers.left.target
        else
            from = controllers.center.target
            to = controllers.right.target
        end

        local posKey = controllers.current.data.positionKeys[1]
        posKey.value = from.translation:lerp(to.translation, transition)

        local rotKey = controllers.current.data.rotationKeys[1]
        rotKey.value = from.rotation:toQuaternion():slerp(to.rotation:toQuaternion(), transition)

        controllers.current.data:updateDerivedValues()
    end

    self.targetRoot:update({ controllers = true })
end

--- Enable fishing animations. Use this before calling `update`.
---
function ControllerGroups:setTarget(ref, boneName)
    self.targetRoot = ref.sceneNode:getObjectByName(boneName) ---@diagnostic disable-line
    for name, controllers in pairs(self.controllers) do
        local target = self.targetRoot:getObjectByName(name)
        if target then
            controllers.current:setTarget(target)
        end
    end
end

--- Disable the fishing animations. Allows regular animations to resume.
---
function ControllerGroups:clearTarget()
    for _, controllers in pairs(self.controllers) do
        controllers.current:setTarget(nil) ---@diagnostic disable-line
    end
end

return ControllerGroups
