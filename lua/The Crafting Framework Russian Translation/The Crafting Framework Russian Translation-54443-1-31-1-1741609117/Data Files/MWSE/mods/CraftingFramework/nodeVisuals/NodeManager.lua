local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("Craftable")
local CraftingFramework = require("CraftingFramework")
local ReferenceManager = CraftingFramework.ReferenceManager

---@class CraftingFramework.NodeManager
---@field requirements? CraftingFramework.NodeManager.Requirements
---@field nodes CraftingFramework.NodeManager.Node[]
local NodeManager = {
    ---@type table<string, CraftingFramework.NodeManager>
    registeredNodeManagers = {}
}
NodeManager.__index = NodeManager

---@param e CraftingFramework.NodeManager.register.params
function NodeManager.register(e)
    local self = setmetatable({}, { __index = NodeManager })
    self.id = e.id
    self.nodes = e.nodes
    self.requirements = function(_, reference)
        local hasSceneNode = reference and reference.sceneNode
        local meetsRequirements = e.referenceRequirements == nil or e.referenceRequirements(reference)
        return hasSceneNode and meetsRequirements
    end

    ReferenceManager:new{
        id = e.id,
        requirements = self.requirements,
        onActivated = function(_, reference)
            self:processReference(reference)
        end
    }

    self.registeredNodeManagers[self.id] = self
    logger:debug("Registered Node Manager %s", self.id)
    return self
end

---@param reference tes3reference
function NodeManager:processReference(reference)
    for _, node in ipairs(self.nodes) do
        local sceneNode = reference.sceneNode
        if sceneNode then
            local nodeToSet = sceneNode:getObjectByName(node.id)
            if nodeToSet then
                if node.setNode then
                    node:setNode{
                        reference = reference,
                        node = nodeToSet
                    }
                else
                    logger:trace("Setting node %s to visible", nodeToSet.name)
                    nodeToSet.appCulled = false
                end
            end
        end
    end
    reference:updateSceneGraph()
end

return NodeManager