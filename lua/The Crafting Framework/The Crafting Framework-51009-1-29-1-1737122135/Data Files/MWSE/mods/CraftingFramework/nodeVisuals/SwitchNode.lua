local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("Craftable")

---An implementation of the Node interface for controlling niSwitchNodes
---@class CraftingFramework.NodeManager.SwitchNode : CraftingFramework.NodeManager.Node
---@field getActiveIndex CraftingFramework.NodeManager.SwitchNode.getActiveIndex
local SwitchNode = {}
SwitchNode.__index = SwitchNode

---Returns the index of the child node to select as Active inside the Switch Node
---@alias CraftingFramework.NodeManager.SwitchNode.getActiveIndex fun(self: CraftingFramework.NodeManager.SwitchNode, e: CraftingFramework.NodeManager.RefNodeParams): number

---@class CraftingFramework.NodeManager.SwitchNode.config
---@field id string
---@field getActiveIndex CraftingFramework.NodeManager.SwitchNode.getActiveIndex

---@param e CraftingFramework.NodeManager.SwitchNode.config
---@return CraftingFramework.NodeManager.SwitchNode
function SwitchNode.new(e)
    local self = setmetatable({}, { __index = SwitchNode })
    self.id = e.id
    self.getActiveIndex = e.getActiveIndex
    return self
end

---@param e CraftingFramework.NodeManager.RefNodeParams
function SwitchNode:setNode(e)
    local index = self:getActiveIndex({
        reference = e.reference,
        node = e.node
    })
    logger:trace("Setting switch index of %s to %d", e.node.name, index)
    e.node.switchIndex = index
end

---@param node niNode
---@param name string
---@return number?
function SwitchNode.getIndex(node, name)
    for i, child in ipairs(node.children) do
        local isMatch = name and child and child.name
            and child.name:lower() == name:lower()
        if isMatch then
            return i - 1
        end
    end
    logger:warn("Could not find child node %s in %s", name, node.name)
end

return SwitchNode