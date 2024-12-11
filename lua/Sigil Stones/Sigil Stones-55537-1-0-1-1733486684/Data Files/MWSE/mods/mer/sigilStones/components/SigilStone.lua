local common = require("mer.sigilStones.common")
local logger = common.createLogger("SigilStone")
local Drip = require("mer.drip")
local Modifier = Drip.Modifier
local Loot = Drip.Loot

---@class SigilStones.SigilStone.Config
---@field baseObjectId string
---@field modifierId? string If not set, will be picked randomly

---@class SigilStones.SigilStone.ObjectConfig
---@field objectId string The object id of the sigil stone
---@field drainedObjectId string The drained version of this sigil stone
---@field modifiers { id: string, description?: string}[] A list of modifier ids that can be applied to this sigil stone

---A sigil stone is a special object that can be used to enchant other objects.
---@class SigilStones.SigilStone : SigilStones.SigilStone.Config
---@field object tes3misc
---@field modifier Drip.Modifier
---@field loot Drip.Loot
local SigilStone = {
    ---@type table<string, SigilStones.SigilStone.ObjectConfig>
    registeredStoneObjects = {}
}

---Register a new sigil stone object
---@param data SigilStones.SigilStone.ObjectConfig
function SigilStone.registerSigilStoneObject(data)
    logger:info("Registering sigil stone %s", data.objectId)
    SigilStone.registeredStoneObjects[data.objectId:lower()] = data
end

function SigilStone.getSigilStoneConfig(objectId)
    return SigilStone.registeredStoneObjects[objectId:lower()]
end

function SigilStone.getRandomModifier(objectId)
    local config = SigilStone.getSigilStoneConfig(objectId)
    if not config then
        logger:error("Failed to find sigil stone config for %s", objectId)
        return nil
    end
    local pick = table.choice(config.modifiers).id
    local attempts = 20
    while not Modifier.getById(pick) and attempts > 0 do
        pick = table.choice(config.modifiers).id
        attempts = attempts - 1
    end
    if attempts == 0 then
        logger:error("Failed to find valid modifier for %s", objectId)
        return nil
    end
    return pick
end

---Create a new sigil stone. This will create a new object
---from the base object and apply the modifier.
---@param data SigilStones.SigilStone.Config
---@return SigilStones.SigilStone?
function SigilStone:create(data)
    if not SigilStone.getSigilStoneConfig(data.baseObjectId) then
        logger:error("%s is not a valid sigil stone object", data.baseObjectId)
        return nil
    end

    data = table.copy(data)
    if not data.modifierId then
        data.modifierId = SigilStone.getRandomModifier(data.baseObjectId)
    end

    if not data.modifierId then
        logger:error("Failed to find modifier for %s", data.baseObjectId)
        return nil
    end

    local self = table.copy(data)
    self = SigilStone:new(self)
    if not self then
        logger:error("Failed to create sigil stone from %s", data.baseObjectId)
        return nil
    end
    self.object = SigilStone.createSigilObject(data.baseObjectId, self.modifier)
    if not self.object then
        logger:error("Failed to create sigil object for %s", data.baseObjectId)
        return nil
    end
    return self
end

---@param data { object: tes3object, baseObjectId: string, modifierId: string }
function SigilStone:new(data)
    local self = table.copy(data)
    self.modifier = Modifier.getById(data.modifierId)
    if not self.modifier then
        logger:error("Failed to find modifier %s", data.modifierId)
        return nil
    end
    setmetatable(self, {__index = SigilStone})
    return self
end


---@param e { item: tes3item, itemData: tes3itemData }
function SigilStone.getFromItem(e)
    logger:trace("Getting sigil stone from %s", e.item.id)
    if not e.itemData then
        logger:trace("No item data")
        return nil
    end
    if not e.item.supportsLuaData then
        logger:trace("Item does not support lua data")
        return nil
    end
    local modifierId = e.itemData.data.sigilStoneModifier
    if not modifierId then
        logger:trace("No modifier id")
        return nil
    end
    local baseObjectId = e.itemData.data.sigilStoneBaseObject
    if not baseObjectId then
        logger:trace("No base object id")
        return nil
    end

    local sigilStone = SigilStone:new{
        object = e.item,
        baseObjectId = baseObjectId,
        modifierId = modifierId
    }
    if not sigilStone then
        logger:error("Failed to create sigil stone from %s", e.item.id)
        return nil
    end
    logger:debug("Created sigil stone from %s", e.item.id)
    return sigilStone
end


---@param baseObjectId string
---@param modifier Drip.Modifier
---@return tes3object?
function SigilStone.createSigilObject(baseObjectId, modifier)
    local baseObject = tes3.getObject(baseObjectId)
    if not baseObject then
        logger:error("Failed to find base object %s", baseObjectId)
        return nil
    end
    local object = baseObject:createCopy{}
    local loot = Loot:new{
        baseObject = baseObject,
        object = object,
        modifiers = {modifier},
        wild = false,
    }
    if not loot then
        logger:error("Failed to create loot for %s", baseObjectId)
        return nil
    end
    object.name = loot:getLootName{}
    object.modified = true
    return object
end

---@class SigilStones.SigilStone.AddToInventory.params
---@field reference tes3reference? (Default: tes3.player) The reference whos inventory to add the sigil stone to

---Add the sigil stone to a reference's inventory
---@param e SigilStones.SigilStone.AddToInventory.params?
function SigilStone:addToInventory(e)
    e = e or {}
    local ref = e.reference or tes3.player
    tes3.addItem{
        reference = ref,
        item = self.object,
        count = 1
    }
    local itemData = tes3.addItemData{
        to = ref,
        item = self.object
    }
    itemData.data.sigilStoneModifier = self.modifier.id
    itemData.data.sigilStoneBaseObject = self.baseObjectId
end

---@class SigilStones.SigilStone.ReplaceInInventory.params
---@field reference tes3reference? (Default: tes3.player) The reference whose inventory holds the sigil stone to replac

---Replace the base sigil stone with enchanted version
---@param e SigilStones.SigilStone.ReplaceInInventory.params
function SigilStone:replaceInInventory(e)
    local ref = e.reference or tes3.player
    tes3.removeItem{
        reference = ref,
        item = self.baseObjectId,
    }
    self:addToInventory{reference = ref}
end

function SigilStone:canFitName(object)
    local loot = Loot:new{
        baseObject = object,
        modifiers = {self.modifier},
        wild = false
    }
    if not loot then
        logger:error("Failed to create loot for %s", object.id)
        return false
    end
    local name = loot:getLootName{}
    return #name < 32
end

---Check if the sigil stone can be applied to a given object
---@param object tes3weapon|tes3armor|tes3clothing
function SigilStone:canEnchant(object)
    return self.modifier:validForObject(object)
        and self:canFitName(object)
        and (object.enchantment == nil
            or self.modifier.effects == nil)
end

function SigilStone:getDrainedObjectId()
    return SigilStone.registeredStoneObjects[self.baseObjectId:lower()].drainedObjectId
end

---@class SigilStones.SigilStone.UseDrained.params
---@field reference tes3reference The reference whose inventory holds the sigil stone to drain

---Replace the sigil stone in a reference's inventory with a drained version
---@param e SigilStones.SigilStone.UseDrained.params
function SigilStone:replaceWithDrainedStone(e)
    local drainedObjectId = self:getDrainedObjectId()
    if not drainedObjectId then
        logger:error("Failed to find drained object for %s", self.object.id)
        return
    end
    tes3.removeItem{
        reference = e.reference,
        item = self.object,
        count = 1
    }
    tes3.addItem{
        reference = e.reference,
        item = tes3.getObject(drainedObjectId),
        count = 1
    }
    logger:debug("Replaced %s with drained version %s", self.object.id, drainedObjectId)
end

---@class SigilStones.SigilStone.Use.params
---@field reference? tes3reference (Default: tes3.player) The reference whose inventory holds the object to enchant
---@field object tes3weapon|tes3armor|tes3clothing The object to enchant
---@field itemData? tes3itemData The item data of the object

---Use the sigil stone to enchant an object
---@param e SigilStones.SigilStone.Use.params
---@return boolean False if the object can't be enchanted.
function SigilStone:use(e)
    if not self:canEnchant(e.object) then
        return false
    end
    local ref = e.reference or tes3.player
    local loot = Loot:new{
        baseObject = e.object,
        modifiers = {self.modifier},
        wild = false
    }:initialize()
    if not loot then
        logger:error("Failed to create loot for %s", e.object.id)
        return false
    end
    local stack = ref.object.inventory:findItemStack(e.object)
    if not stack then
        logger:error("Failed to find stack for %s", e.object.id)
        return false
    end
    loot:replaceLootInInventory(ref, stack, e.itemData)
    self:replaceWithDrainedStone{reference = ref}
    tes3.playSound{
        sound = "enchant success"
    }
    tes3.messageBox("The sigil stone fades, %s created", loot.object.name)
    logger:debug("Enchanted %s with %s", e.object.id, self.object.id)
    return true
end

function SigilStone:getDescription()
    if self.modifier.description then
        return self.modifier.description
    end
    local stoneConfig = SigilStone.getSigilStoneConfig(self.baseObjectId)
    if stoneConfig and stoneConfig.modifiers then
        for _, mod in ipairs(stoneConfig.modifiers) do
            if mod.id == self.modifier.id then
                if mod.description then
                    return mod.description
                end
            end
        end
    end
end

return SigilStone