local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("Craftable")
local SwitchNode = require("CraftingFramework.nodeVisuals.SwitchNode")

---An implementation of the Node interface for attaching items from the reference's inventory to an attach node.
---Also supports an optional "ON/Off" switch node that will be turned on if an item is attached.
---@class CraftingFramework.NodeManager.InventoryAttachNode : CraftingFramework.NodeManager.Node
---@field getItems CraftingFramework.NodeManager.getItems
---@field isActive CraftingFramework.NodeManager.isActive
---@field itemValid CraftingFramework.NodeManager.itemValid
---@field afterAttach? CraftingFramework.NodeManager.afterAttach
---@field switchId? CraftingFramework.NodeManager.switchId
---@field onNode? string `Default: "ON"` The name of the "ON" node in the niSwitchNode
---@field offNode? string `Default: "OFF"` The name of the "OFF" node in the niSwitchNode
local InventoryAttachNode = {}

---@class CraftingFramework.NodeManager.itemValid.params
---@field reference tes3reference The reference being attached to
---@field item tes3item The chosen item to check for validity

---Returns a list of ids of items that are able to be attached to this node
---@alias CraftingFramework.NodeManager.getItems fun(self: CraftingFramework.NodeManager.InventoryAttachNode, reference: tes3reference): table<string, boolean>
---Callback for determining whether this node is active at all, before any item is selected
---@alias CraftingFramework.NodeManager.isActive fun(self: CraftingFramework.NodeManager.InventoryAttachNode, e: CraftingFramework.NodeManager.RefNodeParams): boolean
---Callback for determining if the chosen item is valid for attaching to the node
---@alias CraftingFramework.NodeManager.itemValid fun(self: CraftingFramework.NodeManager.InventoryAttachNode, e: CraftingFramework.NodeManager.itemValid.params): boolean
---This callback is to run additional logic after the item has been attached to the node. it will still run if no item was attached
---@alias CraftingFramework.NodeManager.afterAttach fun(self: CraftingFramework.NodeManager.InventoryAttachNode, e: CraftingFramework.NodeManager.RefNodeParams, item: tes3item)
---If provided, a switch node of this name will be set to the "ON" child if the item is attached, or the "OFF" child otherwise
---@alias CraftingFramework.NodeManager.switchId string

---@class CraftingFramework.NodeManager.InventoryAttachNode.config
---@field id string The id (name) of the attach node
---@field getItems CraftingFramework.NodeManager.getItems
---@field isActive? CraftingFramework.NodeManager.isActive
---@field itemValid? fun(self: CraftingFramework.NodeManager.InventoryAttachNode, tes3item: tes3item): boolean
---@field afterAttach? CraftingFramework.NodeManager.afterAttach
---@field switchId? CraftingFramework.NodeManager.switchId (Optional) The id (name) of the switch node to control
---@field onNode? string `Default: "ON"` The name of the "ON" node in the niSwitchNode
---@field offNode? string `Default: "OFF"` The name of the "OFF" node in the niSwitchNode

---@param e CraftingFramework.NodeManager.InventoryAttachNode.config
---@return CraftingFramework.NodeManager.InventoryAttachNode
function InventoryAttachNode.new(e)
    ---@type CraftingFramework.NodeManager.InventoryAttachNode
    local self = setmetatable({}, { __index = InventoryAttachNode })
    self.id = e.id
    self.getItems = e.getItems
    self.isActive = e.isActive or function() return true end
    self.itemValid = e.itemValid or function() return true end
    self.afterAttach = e.afterAttach
    self.switchId = e.switchId
    self.onNode = e.onNode or "ON"
    self.offNode = e.offNode or "OFF"
    return self
end

---Returns the item to display on the node, if there is one and the node is
---@param e CraftingFramework.NodeManager.RefNodeParams
function InventoryAttachNode:getItemToDisplay(e)
    local item = self:getInventoryItem(e.reference)
    if self:isActive(e) and item then
        return item
    end
end

---Find an item from the reference's inventory that is valid for attaching to this node
---@param reference tes3reference
---@return tes3item|tes3misc?
function InventoryAttachNode:getInventoryItem(reference)
    for itemId in pairs(self:getItems(reference)) do
        local item = tes3.getObject(itemId)
        if item ~= nil and self:itemValid{ reference = reference, item = item} then
            if reference.object.inventory:contains(itemId) then
                return item
            end
        end
    end
end

---Detach all the children of the node. Still need to call update on the sceneNode
---@param e CraftingFramework.NodeManager.RefNodeParams
function InventoryAttachNode:clearAttachNode(e)
    --remove children
    for i, childNode in ipairs(e.node.children) do
        if childNode then
            e.node:detachChildAt(i)
        end
    end
end

---@type CraftingFramework.NodeManager.RefNodeParams
function InventoryAttachNode:doSwitchNode(e, hasItem)
    local switchNode = e.reference.sceneNode:getObjectByName(self.switchId)
    local childName = hasItem and self.onNode or self.offNode
    local index = SwitchNode.getIndex(switchNode, childName)
    switchNode.switchIndex = index
end
function InventoryAttachNode:attachItem(e, item)
    logger:trace("Attaching %s to %s:%s", item.id, e.reference, e.node.name)
    local mesh = tes3.loadMesh(item.mesh, true):clone()
    mesh:clearTransforms()
    e.node:attachChild(mesh, true)
    e.reference.sceneNode:update()
    e.reference.sceneNode:updateEffects()
end

---@type CraftingFramework.NodeManager.setNodeCallback
function InventoryAttachNode:setNode(e)
    self:clearAttachNode(e)
    local item = self:getItemToDisplay(e)
    if self.switchId then
        self:doSwitchNode(e, item ~= nil)
    end
    if item then
        self:attachItem(e, item)
    end
    if self.afterAttach then
        self:afterAttach(e, item)
    end
end

return InventoryAttachNode