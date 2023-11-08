---@meta

---An interface for creating a node to be managed by a Node Manager
---@class CraftingFramework.NodeManager.Node
---@field id string The id (name) of the attach/switch node
---@field setNode CraftingFramework.NodeManager.setNodeCallback

---A table for holding reference and node parameters
---@class CraftingFramework.NodeManager.RefNodeParams
---@field reference tes3reference
---@field node niNode|niSwitchNode

---A callback which returns true if the node should be displayed. If not provided, will always return true
---@alias CraftingFramework.NodeManager.setNodeCallback fun(self: CraftingFramework.NodeManager.Node, e: CraftingFramework.NodeManager.RefNodeParams)

---Callback for determining if a reference meets the requirements to be processed by a node
---@alias CraftingFramework.NodeManager.ReferenceRequirements fun(reference: tes3reference): boolean

---Callback for determining if a reference meets the requirements to be processed by a node
---@alias CraftingFramework.NodeManager.Requirements fun(self: CraftingFramework.NodeManager, reference: tes3reference): boolean

---Params for registering a Node Manager
---@class CraftingFramework.NodeManager.register.params
---@field id string The Id of the Node Manager
---@field nodes CraftingFramework.NodeManager.Node[] A list of Nodes to be managed
---@field referenceRequirements CraftingFramework.NodeManager.ReferenceRequirements
