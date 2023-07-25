local common = require("mer.fishing.common")
local logger = common.createLogger("FishingRod")
local config = require("mer.fishing.config")
local Bait = require("mer.fishing.Bait.Bait")

---@class Fishing.FishingRod
---@field reference? tes3reference @Reference to the fishing rod
---@field item tes3weapon @The fishing rod item
---@field itemData? tes3itemData @The itemData for the fishing rod
---@field dataHolder? tes3reference|tes3itemData @The reference or itemData that holds the fishing data
---@field config table @The config for this fishing rod
---@field data table<string, any> @The fishing data
local FishingRod = {
    ---@type table<string, Fishing.FishingRod.config>
    registeredFishingRods = {}
}

---@class Fishing.FishingRod.config
---@field id string
---@field quality number

--Register an item as a fishing rod
---@param e Fishing.FishingRod.config
function FishingRod.register(e)
    logger:assert(type(e.id) == "string", "Fishing rod must have an id")
    logger:assert(type(e.quality) == "number", "Fishing rod must have a quality")
    FishingRod.registeredFishingRods[e.id:lower()] = e
end

---@return Fishing.FishingRod|nil
function FishingRod.new(e)
    logger:assert(e.reference or e.item, "FishingRod requires either a reference or an item")
    local item = e.item or e.reference.object
    local config = FishingRod.getConfig(e.item.id)
    if not config then return nil end

    local self = {}
    setmetatable(self, {__index = FishingRod})

    self.item =  item
    self.itemData = e.itemData
    self.reference = e.reference
    self.dataHolder = (e.itemData ~= nil) and e.itemData or e.reference
    self.config = config

    self.data = setmetatable({}, {
        __index = function(_, k)
            if not (
                self.dataHolder
                and self.dataHolder.data
                and self.dataHolder.data.fishing
            ) then
                return nil
            end
            return self.dataHolder.data.fishing[k]
        end,
        __newindex = function(_, k, v)
            if self.dataHolder == nil then
                logger:debug("Setting value %s and dataHolder doesn't exist yet", k)
                if not self.reference then
                    logger:debug("self.item: %s", self.item)
                    --create itemData
                    self.dataHolder = tes3.addItemData{
                        to = tes3.player,
                        item = self.item.id,
                    }
                    if self.dataHolder == nil then
                        logger:error("Failed to create itemData for FishingRod")
                        return
                    end
                end
            end
            if not ( self.dataHolder.data and self.dataHolder.data.fishing) then
                self.dataHolder.data.fishing = {}
            end
            self.dataHolder.data.fishing[k] = v
        end
    })

    return self
end

---@return Fishing.FishingRod|nil
function FishingRod.getEquipped()
    local weaponStack = tes3.getEquippedItem{
        actor = tes3.player,
        objectType = tes3.objectType.weapon
    }
    if not weaponStack then return nil end
    return FishingRod.new{
        item = weaponStack.object,
        itemData = weaponStack.itemData
    }
end

---@param bait Fishing.Bait
function FishingRod:equipBait(bait)
    logger:debug("Equipping bait %s", bait:getName())
    --get existing bait
    local existingBait = self:getEquippedBait()
    if existingBait then
        logger:debug("Existing Bait: %s", existingBait:getName())
        if existingBait:reusable() then
            logger:debug("Adding currently equipped %s to inventory", existingBait:getName())
            tes3.addItem{
                reference = tes3.player,
                item = existingBait.id,
                playSound = false
            }
        else
            logger:debug("not reusable")
        end
    else
        logger:debug("No existing bait")
    end

    self.data.equippedBait = {
        id = bait.id,
        uses = bait.uses
    }
    tes3.removeItem{
        reference = tes3.player,
        item = bait.id,
        playSound = true
    }
    tes3.messageBox("Equipped %s to %s", bait:getName(), self:getName())
end

---@return Fishing.Bait|nil
function FishingRod:getEquippedBait()
    if self.data.equippedBait then
        local uses = self.data.equippedBait.uses
        local bait = Bait.get(self.data.equippedBait.id)
        if not bait then
            logger:error("Bait %s not found", self.data.equippedBait.id)
            return nil
        end
        return bait:getInstance(uses)
    end
end

--reduces condition of equipped fishing rod
function FishingRod:degrade(degradeAmount)
    if not self.itemData then return end
    logger:debug("Degrading fishing rod by %s", degradeAmount)
    self.itemData.condition = math.max(0, self.itemData.condition - degradeAmount)
    if self.itemData.condition <= 0 then
        tes3.messageBox("%s is broken.", self:getName())
        tes3.playSound{reference = tes3.player, sound = "Item Misc Down"}

    end
end

function FishingRod:useBait()
    logger:debug("Using bait")
    local bait = self:getEquippedBait()
    if not bait then
        logger:debug("- No bait equipped")
        return
    end
    if bait:reusable() then
        logger:debug("- Bait is reusable")
        return
    end

    bait.uses = bait.uses - 1
    if bait.uses <= 0 then
        tes3.messageBox("%s is used up", bait:getName())
        --clear bait
        self.data.equippedBait = nil
        return
    end
    self.data.equippedBait.uses = bait.uses
    logger:debug("- Remaining uses: %s", bait.uses)
end

function FishingRod:hasBait()
    local bait = self:getEquippedBait()
    if not bait then return false end
    if bait.uses == nil then return true end
    return bait.uses > 0
end

function FishingRod:getName()
    return self.item.name
end

---@param id string
function FishingRod.getConfig(id)
    return FishingRod.registeredFishingRods[id:lower()]
end

function FishingRod.isEquipped()
    local weaponStack = tes3.getEquippedItem{
        actor = tes3.player,
        objectType = tes3.objectType.weapon
    }
    if not weaponStack then return false end
    return FishingRod.getConfig(weaponStack.object.id) ~= nil
end

function FishingRod.getPoleEndPosition()
    local ref = tes3.is3rdPerson() and tes3.player or tes3.player1stPerson
    local attachNode = ref.sceneNode:getObjectByName("AttachFishingLine")--[[@as niNode]]
    return attachNode.worldTransform.translation
end

function FishingRod.playCastSound(castStrength)
    local pitch = math.remap(castStrength, 0, 1, 2.0, 1.0)
    logger:debug("Playing cast sound with pitch %s", pitch)
    tes3.playSound{
        reference = tes3.player,
        sound = "mer_fish_cast",
        pitch = pitch
    }
end

function FishingRod.playReelSound(e)
    FishingRod.stopReelSound()
    tes3.playSound{
        reference = tes3.player,
        sound = "mer_fish_reel",
        loop = e.doLoop,
        pitch = e.pitch or 1.0
    }
end

function FishingRod.stopReelSound()
    tes3.removeSound{
        reference = tes3.player,
        sound = "mer_fish_reel"
    }
end

return FishingRod