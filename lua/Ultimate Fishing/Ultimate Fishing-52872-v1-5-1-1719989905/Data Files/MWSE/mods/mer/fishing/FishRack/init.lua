local common = require("mer.fishing.common")
local logger = common.createLogger("FishRack")
local config = require("mer.fishing.config")

local FishType = require("mer.fishing.Fish.FishType")
local ReferenceManager = require("CraftingFramework.components.ReferenceManager")
local NodeUtils = require("CraftingFramework.util.NodeUtils")
local StaticActivator = require("CraftingFramework.components.StaticActivator")

---Class for storing data about a hook,
--- including its index and what fish is on it
---@class Fishing.FishRack.HookData
---@field fishId string The id of the fish
---@field data table The associated itemData.data table

---@class Fishing.FishRack.Data
---@field hookDatas table<string, Fishing.FishRack.HookData> A list of hook data, indexed by the node name

--A craftable rack that you can hang fish on.
---@class Fishing.FishRack
---@field reference tes3reference
---@field data Fishing.FishRack.Data
---@field hangableFishTypesCache Fishing.FishType[]?
local FishRack = {
    ATTACH_NODES = {
        ATTACH_FISH_01 = true,
        ATTACH_FISH_02 = true,
        ATTACH_FISH_03 = true,
        ATTACH_FISH_04 = true,
        ATTACH_FISH_05 = true,
        ATTACH_FISH_06 = true,
        ATTACH_FISH_07 = true,
        ATTACH_FISH_08 = true,
        ATTACH_FISH_09 = true,
        ATTACH_FISH_10 = true,
    },
    fishRackIds = {
        mer_fish_rack = {
            name = "Fish Rack"
        },
    }
}

--Register a reference manager to update the fish nodes
ReferenceManager:new{
    id = "fishRack",
    logger = logger,
    onActivated = function(_, reference)
        local fishRack = FishRack:new(reference)
        if fishRack then fishRack:updateFishNodes() end
    end,
    requirements = function(_, reference)
        return not not FishRack.fishRackIds[reference.baseObject.id:lower()]
    end
}

---------------------------------------------------
-- Static Functions
---------------------------------------------------

function FishRack.isAFishRack(id)
    return FishRack.fishRackIds[id:lower()]
end

---@return Fishing.FishRack|nil
function FishRack:new(reference)
    if not FishRack.isAFishRack(reference.baseObject.id:lower()) then
        logger:debug("Not a fish rack")
        return nil
    end
    ---@type Fishing.FishRack
    local this = {
        reference = reference,
        data = setmetatable({}, {
            __index = function(_, k)
                if not reference.data.fishRack then
                    ---@type Fishing.FishRack.Data
                    reference.data.fishRack = {
                        hookDatas = {}
                    }
                end
                return reference.data.fishRack[k]
            end,
            __newindex = function(_, k, v)
                if not reference.data.fishRack then
                    ---@type Fishing.FishRack.Data
                    reference.data.fishRack = {
                        hookDatas = {}
                    }
                end
                reference.data.fishRack[k] = v
            end
        })
    }
    setmetatable(this, self)
    self.__index = self
    return this
end


---@return table<string, Fishing.FishType>
function FishRack.getHangableFishTypes()
    logger:trace("Getting hangable fish types")
    if FishRack.hangableFishTypesCache then
        logger:trace("Using cached hangable fish types")
        return FishRack.hangableFishTypesCache
    end
    local hangableFishTypes = {}
    for id, fishType in pairs(FishType.registeredFishTypes) do
        logger:trace("Checking %s", fishType.baseId)
        if fishType:canHang() then
            logger:trace("- Can hang")
            hangableFishTypes[id] = fishType
        else
            logger:trace("- Can't hang")
        end
    end
    if table.size(hangableFishTypes) > 0 then
        FishRack.hangableFishTypesCache = hangableFishTypes
    end
    return hangableFishTypes
end

---@return boolean
function FishRack.playerHasHangableFish()
    local playerHasHangableFish = false
    local hangableFishTypes = FishRack.getHangableFishTypes()
    --check player inventory for hangable fish
    for _, fishType in pairs(hangableFishTypes) do
        if tes3.player.object.inventory:contains(fishType.baseId) then
            playerHasHangableFish = true
            break
        end
    end
    return playerHasHangableFish
end

---------------------------------------------------
-- Instance Functions
---------------------------------------------------

function FishRack:canAddFish()
    return self:hasEmptyHook() and FishRack.playerHasHangableFish()
end

function FishRack:hasEmptyHook()
    local hookNodes = {}
    for child in table.traverse{ self.reference.sceneNode } do
        if FishRack.ATTACH_NODES[child.name] then
            table.insert(hookNodes, child)
        end
    end

    for _, hookNode in ipairs(hookNodes) do
        local hookData = self.data.hookDatas[hookNode.name]
        if not hookData or not hookData.fishId then
            return true
        end
    end

    return false
end

--Picks a random empty hook, or returns nil if none are available
function FishRack:pickEmptyHook()

    local hookNodes = {}
    for child in table.traverse{ self.reference.sceneNode } do
        if FishRack.ATTACH_NODES[child.name] then
            table.insert(hookNodes, child)
        end
    end

    local emptyHooks = {}
    for _, hookNode in pairs(hookNodes) do
        local hookData = self.data.hookDatas[hookNode.name]
        if not hookData or not hookData.fishId then
            table.insert(emptyHooks, hookNode.name)
        end
    end
    if #emptyHooks == 0 then
        return nil
    end
    return table.choice(emptyHooks)
end


function FishRack:updateFishNode(nodeId)
    logger:debug("Updating Fish Node %s", nodeId)
    local hookNode = self.reference.sceneNode:getObjectByName(nodeId) --[[@as niNode]]
    if hookNode then
        logger:debug("- Found Hook Node %s", hookNode.name)
        hookNode:detachAllChildren()
        local hookData = self.data.hookDatas[nodeId] or {}

        local fishType = FishType.get(hookData.fishId)
        if fishType then
            local fishNode = tes3.loadMesh(fishType:getPreviewMesh(), false) --[[@as niNode]]
            local hangNode = fishNode:getObjectByName(FishType.HANG_NODE):clone() --[[@as niNode]]
            hookNode:attachChild(hangNode)
            hangNode:attachChild(fishNode)
            fishNode.flags = 0
            self.reference.sceneNode:update()
            self.reference.sceneNode:updateEffects()
            logger:debug("- Finished attaching fish node")
        else
            logger:debug("- No fish to attach")
        end
    else
        logger:error("Not a valid hook node id: %s", nodeId)
    end
end

function FishRack:updateFishNodes()
    for nodeId, hookData in pairs(self.data.hookDatas) do
        self:updateFishNode(nodeId)
    end
end

--- Hang a fish on the rack
---@param item tes3misc
---@param itemData tes3itemData
function FishRack:hangFish(item, itemData)
    logger:debug("Hanging fish %s", item.id)
    local fishType = FishType.get(item.id)

    if not fishType then
        logger:error("No fish type for %s", item.id)
        return
    end

    local hookId = self:pickEmptyHook()
    if not hookId then
        logger:error("No empty hooks")
        return
    end

    --add to hook data
    self.data.hookDatas[hookId] = {
        fishId = item.id,
        data = itemData and itemData.data
    }

    self:updateFishNode(hookId)

    -- remove from player inventory
    tes3.removeItem{
        reference = tes3.player,
        item = item,
        itemData = itemData,
        count = 1,
        playSound = false
    }
end

function FishRack:openAddFishMenu()
    if not self:hasEmptyHook() then
        logger:error("No empty hooks")
        return
    end
    FishRack.hangableFishTypesCache = nil
    local hangableFishTypes = FishRack.getHangableFishTypes()
    tes3ui.showInventorySelectMenu{
        title = "Select Fish to Hang",
        noResultsText = "You have no fish to hang",
        callback = function(e)
            if e.item then
                self:hangFish(e.item, e.itemData)
            end
        end,
        filter = function(e)
            return not not hangableFishTypes[e.item.id:lower()]
        end,
        leaveMenuMode = true
    }
end

---@return string | nil
function FishRack:getHookLookingAt(lookingAtNode)
    local hangNode = NodeUtils.getNamedParent(lookingAtNode, FishType.HANG_NODE)
    if not hangNode then
        logger:trace("No hang node parent")
        return
    end
    if #hangNode.children == 0 then
        logger:trace("Hang node doesn't have a fish")
        return
    end
    local hookNode = hangNode.parent
    return hookNode.name
end

---@param parentElement tes3uiElement
function FishRack:doTooltip(parentElement, lookingAtNode)
    if not lookingAtNode then return end
    local hookName = self:getHookLookingAt(lookingAtNode)
    local hookData = self.data.hookDatas[hookName]
    if not hookData then return end
    local fishId = hookData.fishId
    if not fishId then return end
    local fish = tes3.getObject(fishId)
    if not fish then return end
    local labelText = string.format("Take %s", fish.name)
    local nameLabel = parentElement.parent:findChild("CraftingFramework:activatorTooltipLabel")
    if not nameLabel then
        logger:error("No name label")
        return
    end
    nameLabel.text = labelText
end

---@return boolean #Returns false to revert to default activate menu
function FishRack:onActivate()
    local result = StaticActivator.getLookingAt()
    if not result then
        return false
    end
    local lookingAtNode = result.object
    local hookName = self:getHookLookingAt(lookingAtNode)
    if not hookName then
        logger:warn("No hook looking at")
        return false
    end
    local hookData = self.data.hookDatas[hookName]
    if not hookData then
        logger:error("No hook data for %s", hookName)
        return false
    end
    local fishId = hookData.fishId
    if not fishId then
        logger:warn("No fish id for %s", hookName)
        return false
    end
    local fish = tes3.getObject(fishId)
    if not fish then
        logger:error("No fish for %s", fishId)
        return false
    end
    logger:debug("Taking fish")
    tes3.addItem{
        reference = tes3.player,
        item = fish,
        showMessage = true
    }
    if hookData.data then
        local itemData = tes3.addItemData{
            to = tes3.player,
            item = fish,
        }
        table.copy(hookData.data, itemData.data)
    end


    self.data.hookDatas[hookName] = nil
    self:updateFishNode(hookName)
    return true
end

return FishRack