local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("Pack")
local NodeManager = require("CraftingFramework.nodeVisuals.NodeManager")

---@class GuarWhisperer.Pack.GuarCompanion.refData
---@field hasPack boolean has a backpack equipped
---@field triggerDialog boolean

---@class GuarWhisperer.Pack.GuarCompanion : GuarWhisperer.GuarCompanion
---@field refData GuarWhisperer.Pack.GuarCompanion.refData

---@class GuarWhisperer.Pack
---@field guar GuarWhisperer.Pack.GuarCompanion
local Pack = {}

---@param guar GuarWhisperer.Pack.GuarCompanion
---@return GuarWhisperer.Pack
function Pack.new(guar)
    local self = setmetatable({}, { __index = Pack })
    self.guar = guar
    return self
end

function Pack:hasPackItem(packItem)
    --No items associated, base off pack
    if not packItem.items or #packItem.items == 0 then
        return true
    end
    for _, item in ipairs(packItem.items) do
        if self.guar.object.inventory:contains(item) then
            return true
        end
    end
end

function Pack:equipPack()
    if not self.guar.reference.context or not self.guar.reference.context.Companion then
        logger:error("[Guar Whisperer] Attempting to give pack to guar with no Companion var")
    end
    self.guar.reference.context.companion = 1
    tes3.removeItem{
        reference = tes3.player,
        item = common.packId,
        playSound = true
    }
    self.guar.refData.hasPack = true
    self:setSwitch()
    NodeManager.registeredNodeManagers["GuarWhisperer_PackNodes"]:processReference(self.guar.reference)
end

function Pack:unequipPack()
    if self.guar.reference.context and self.guar.reference.context.Companion then
        self.guar.reference.context.companion = 0
    end
    for _, stack in pairs(self.guar.object.inventory) do
        tes3.transferItem{
            from = self.guar.reference,
            to = tes3.player,
            item = stack.object,
            count = stack.count or 1,
            playSound=false
        }
    end
    tes3.addItem{
        reference = tes3.player,
        item = common.packId,
        playSound = true
    }
    self.guar.refData.hasPack = false
    self:setSwitch()
    NodeManager.registeredNodeManagers["GuarWhisperer_PackNodes"]:processReference(self.guar.reference)
end

function Pack:canEquipPack()
    return self.guar.refData.hasPack ~= true
        and tes3.player.object.inventory:contains(common.packId)
        and self.guar.needs:hasTrustLevel("Trusting")
        and (not self.guar.genetics:isBaby())
end

---Returns true if the guar has a pack equipped
function Pack:hasPack()
    return self.guar.refData.hasPack == true
end

function Pack:setSwitch()
    logger:debug("Setting switch")
    if not self.guar.reference.sceneNode then return end
    if not self.guar.reference.mobile then return end
    NodeManager.registeredNodeManagers["GuarWhisperer_PackNodes"]:processReference(self.guar.reference)
end

local function findNamedParentNode(node, name)
    logger:debug("Searching for %s parent of node %s", name, node.name)
    local parent = node
    while parent do
        if parent.name == name then
            logger:debug("Found parent %s", name)
            return parent
        end
        parent = parent.parent
    end
    return parent
end


function Pack:grabItem(nodeConfig)
    for itemId in pairs(nodeConfig:getItems(self.guar.reference)) do
        local inventory = self.guar.object.inventory
        if inventory:contains(itemId) then
            logger:debug("Found %s in inventory", itemId)
            for _, stack in pairs(inventory) do
                if stack.object.id:lower() == itemId:lower() then
                    local count = stack.count
                    local itemData
                    if stack.variables and #stack.variables > 0 then
                        count = 1
                        itemData = stack.variables[1]
                    end
                    logger:debug("Item transferred successfully")
                    tes3.messageBox("Retrieved %s from pack.", stack.object.name)
                    tes3.transferItem{
                        from = self.guar.reference,
                        to = tes3.player,
                        item = stack.object.id,
                        itemData = itemData,
                        count = count
                    }
                    event.trigger("Ashfall:triggerPackUpdate")
                    self:setSwitch()
                    return true
                end
            end
        end
    end
    return false
end


function Pack:takeItemLookingAt()
    logger:debug("takeItemLookingAt")
    local eyePos =  tes3.getPlayerEyePosition()
    local results = tes3.rayTest{
        position = eyePos,
        direction = tes3.getPlayerEyeVector(),
        ignore = { tes3.player },
        findAll = true,
        maxDistance = tes3.getPlayerActivationDistance()
    }
    if results then
        local nodeManager = NodeManager.registeredNodeManagers["GuarWhisperer_PackNodes"]
        ---@param nodeConfig CraftingFramework.NodeManager.InventoryAttachNode
        for _, nodeConfig in ipairs(nodeManager.nodes) do
            for _, result in ipairs(results) do
                if result and result.object then
                    logger:debug("Ray hit %s", result.object.name)
                    if nodeConfig.getItems then
                        logger:debug("Checking %s, has items", nodeConfig.id)
                        local node = result.object
                        local hitNode = findNamedParentNode(node, nodeConfig.id)

                        --Block if node is on the other side of the guar
                        if hitNode then
                            local distanceToIntersection = result.intersection:distance(eyePos)
                            local distanceToGuar = self.guar.reference.position:distance(eyePos)
                            if distanceToIntersection > distanceToGuar then
                                hitNode = false
                            end
                        end

                        if not hitNode then
                            logger:debug("Didn't find parent node %s", nodeConfig.id)
                        else
                            --if its a lantern, toggle instead of taking
                            if nodeConfig.id == "ATTACH_LANTERN" then
                                if self.guar.lantern:isOn() then
                                    self.guar.lantern:turnLanternOff{ playSound = true }
                                else
                                    self.guar.lantern:turnLanternOn{ playSound = true }
                                end
                                return
                            else
                                logger:debug("Grabbing %s from pack", nodeConfig.id)
                                if self:grabItem(nodeConfig) then
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    --Didn't find anything, opening pack instead
    logger:debug("Entering pack")
    self.guar.refData.triggerDialog = true
    self.guar.reference.context.companion = 1
    tes3.player:activate(self.guar.reference)
end

return Pack