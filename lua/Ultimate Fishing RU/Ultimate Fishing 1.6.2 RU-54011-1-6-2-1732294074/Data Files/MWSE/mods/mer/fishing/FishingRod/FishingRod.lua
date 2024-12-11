local common = require("mer.fishing.common")
local logger = common.createLogger("FishingRod")
local config = require("mer.fishing.config")
local Bait = require("mer.fishing.Bait.Bait")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")

---@class Fishing.FishingRod
---@field reference? tes3reference Reference to the fishing rod
---@field item tes3weapon The fishing rod item
---@field itemData? tes3itemData The itemData for the fishing rod
---@field dataHolder? tes3reference|tes3itemData The reference or itemData that holds the fishing data
---@field config table The config for this fishing rod
---@field data table<string, any> The fishing data
---@field lineAttachNode niNode The node to attach the fishing line to
local FishingRod = {
    ---@type table<string, Fishing.FishingRod.config>
    registeredFishingRods = {}
}

---@class Fishing.FishingRod.config
---@field id string
---@field quality number
---@field defaultBait? string If set, the rod comes pre-equipped with this bait

---------------------------------------------------
-- Static Functions
---------------------------------------------------

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

function FishingRod.isFishingRod(item)
    return FishingRod.getConfig(item.id) ~= nil
end

-- Get the fishing rod equipped by the player
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

-- Get the config for a fishing rod
---@param id string
function FishingRod.getConfig(id)
    return FishingRod.registeredFishingRods[id:lower()]
end

-- Returns true if the player has a fishing rod equipped
---@return boolean
function FishingRod.isEquipped()
    local weaponStack = tes3.getEquippedItem{
        actor = tes3.player,
        objectType = tes3.objectType.weapon
    }
    if not weaponStack then return false end
    return FishingRod.getConfig(weaponStack.object.id) ~= nil
end

-- Get the position of the end of the fishing pole
function FishingRod.getPoleEndPosition()
    local ref = tes3.is3rdPerson() and tes3.player or tes3.player1stPerson
    local attachNode = ref.sceneNode:getObjectByName("AttachFishingLine")--[[@as niNode]]
    return attachNode.worldTransform.translation
end



-- Play the cast sound
function FishingRod.playCastSound(castStrength)
    local pitch = math.remap(castStrength, 0, 1, 2.0, 1.0)
    logger:debug("Playing cast sound with pitch %s", pitch)
    tes3.playSound{
        reference = tes3.player,
        sound = "mer_fish_cast",
        pitch = pitch
    }
end

-- Play the reel sound
function FishingRod.playReelSound(e)
    logger:debug("Playing reel sound")
    FishingRod.stopReelSound()
    tes3.playSound{
        reference = tes3.player,
        sound = "mer_fish_reel",
        loop = e.doLoop,
        pitch = e.pitch or 1.0
    }
end

-- Stop the reel sound from playing
function FishingRod.stopReelSound()
    logger:debug("Stopping reel sound")
    tes3.removeSound{
        reference = tes3.player,
        sound = "mer_fish_reel"
    }
end


local function updateRodAnimation(rootNode, newTension)
    logger:trace("Setting tension of rod to %s", newTension)
    local minTension = config.constants.TENSION_LINE_ROD_TRANSITION
    local maxTension = config.constants.TENSION_MAXIMUM
    local tension = math.clamp(newTension, minTension, maxTension)
    local t = math.remap(tension, minTension, maxTension, 0, 1)


    local armature = rootNode:getObjectByName("FISHING_ROD_ARMATURE")
    if not armature then
        logger:error("FISHING_ROD_ARMATURE not found")
        return
    end

    local targetBone = armature:getObjectByName("Bone")--[[@as niNode]]
    local bonePositions = armature:getObjectByName("BONE_POSITIONS") --[[as niNode]]
    if not bonePositions then
        logger:error("BONE_POSITIONS not found")
        return
    end

    local straightBone = bonePositions:getObjectByName("Straight").children[1]--[[@as niNode]]
    local curvedBone = bonePositions:getObjectByName("Curved").children[1] --[[@as niNode]]


    --Go down bone chains and set position/translation
    ---comment
    ---@param bone niNode
    ---@param bone1 niNode
    ---@param bone2 niNode
    ---@param t number
    local function lerpBone(bone, bone1, bone2, t)
        local pos1 = bone1.translation
        local pos2 = bone2.translation
        local newPos = pos1:copy():lerp(pos2, t)
        bone.translation = newPos
        logger:trace("Lerping bone %s transalation to %s", bone.name, newPos)

        local rot1 = bone1.rotation
        local rot2 = bone2.rotation
        local newRot = rot1:toQuaternion():slerp(rot2:toQuaternion(), t):toRotation()

        bone.rotation = newRot
        logger:trace("Lerping bone %s rotation to %s", bone.name, newRot)
    end

    while targetBone and straightBone and curvedBone do
        lerpBone(targetBone, straightBone, curvedBone, t)
        targetBone = targetBone.children[1]
        straightBone = straightBone.children[1]
        curvedBone = curvedBone.children[1]
    end

    armature:update()
end

---Bends the fishing rod mesh according to tension
---Lerp between bone positions/rotations
function FishingRod.updateRodBend(newTension)
    updateRodAnimation(tes3.player.sceneNode, newTension)
    updateRodAnimation(tes3.player1stPerson.sceneNode, newTension)
end

function FishingRod.setLineAttachNode(node)
    FishingRod.lineAttachNode = node
end

function FishingRod.removeTransforms()
    --Find the 3rd person rod and remove the scaling transforms from it
    local root = tes3.player.sceneNode --[[@as niNode]]
    local armature = root:getObjectByName("FISHING_ROD_ARMATURE")
    if not armature then return end
    local rod = armature.parent
    if not rod then
        logger:error("FISHING_ROD_ARMATURE not found")
        return
    end
    local height = tes3.player.object.race.height[tes3.player.object.female and "female" or "male"]
    local weight = tes3.player.object.race.weight[tes3.player.object.female and "female" or "male"]
    local r = rod.rotation
    local inverseScale = tes3vector3.new(1/weight, 1/height, 1/weight)
    rod.rotation = tes3matrix33.new(r.x * inverseScale, r.y * inverseScale, r.z * inverseScale)
end

function FishingRod.reapplyTransforms()
    --Find the 3rd person rod and remove the scaling transforms from it
    local root = tes3.player.sceneNode --[[@as niNode]]
    local rod = root:getObjectByName("FISHING_ROD_ARMATURE").parent
    if not rod then
        logger:error("FISHING_ROD_ARMATURE not found")
        return
    end
    local height = tes3.player.object.race.height[tes3.player.object.female and "female" or "male"]
    local weight = tes3.player.object.race.weight[tes3.player.object.female and "female" or "male"]
    local r = rod.rotation
    local scale = tes3vector3.new(weight, height, weight)
    rod.rotation = tes3matrix33.new(r.x * scale, r.y * scale, r.z * scale)
end




---------------------------------------------------
-- Instance Functions
---------------------------------------------------

-- Equip a bait to the fishing rod
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
    tes3.messageBox("Вы прикрепили %s к %s", bait:getName(), self:getName())
end

-- Get the bait equipped to the fishing rod
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
    if self.config.defaultBait then
        local defaultBait = Bait.get(self.config.defaultBait)
        if defaultBait then
            return defaultBait:getInstance()
        else
            logger:warn("Default bait %s not found", self.config.defaultBait)
        end
    end
end

-- Reduces condition of equipped fishing rod
function FishingRod:degrade(degradeAmount)
    if not self.itemData then return end
    logger:debug("Degrading fishing rod by %s", degradeAmount)
    self.itemData.condition = math.max(0, self.itemData.condition - degradeAmount)
    if self.itemData.condition <= 0 then
        tes3.messageBox("%s сломалась.", self:getName())
        tes3.playSound{reference = tes3.player, sound = "Item Misc Down"}
    end
end

-- Use bait, reducing uses by 1
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
        tes3.messageBox("%s израсходовано", bait:getName())
        --clear bait
        self.data.equippedBait = nil
        return
    end
    self.data.equippedBait.uses = bait.uses
    logger:debug("- Remaining uses: %s", bait.uses)
end

-- Returns true if the fishing rod has bait equipped
---@return boolean
function FishingRod:hasBait()
    local bait = self:getEquippedBait()
    if not bait then return false end
    if bait.uses == nil then return true end
    return bait.uses > 0
end

-- Get the name of the fishing rod
---@return string
function FishingRod:getName()
    return self.item.name
end


return FishingRod