local common = require("mer.fishing.common")
local logger = common.createLogger("FishInstance")
local config = require("mer.fishing.config")

---@class Fishing.FishType.instance
---@field fishType Fishing.FishType
---@field fatigue number How much fatigue the fish has left
---@field objectId? string The object id of the fish (if it has been modified)
local FishInstance = {}

---@param fishType Fishing.FishType
---@return Fishing.FishType.instance | nil
function FishInstance.new(fishType)
    logger:debug("Instancing %s", fishType.baseId)
    local self = setmetatable({}, { __index = FishInstance })
    local baseObject = fishType:getBaseObject()
    if not baseObject then
        logger:warn("Could not find base object for %s", fishType.baseId)
        return nil
    end
    if fishType.variants then
        --lowercase all the variants
        for variant, _ in pairs(fishType.variants) do
            fishType.variants[variant:lower()] = true
        end
        --add base id if not already there
        fishType.variants[fishType.baseId:lower()] = true
        --check which variants are valid
        local validVariants = {}
        for variant, _ in pairs(fishType.variants) do
            if tes3.getObject(variant) then
                table.insert(validVariants, variant)
            end
        end
        --pick a variant
        self.objectId = table.choice(validVariants)
        logger:debug("- Selected variant %s", self.objectId)
    end
    self.fishType = fishType
    self.fatigue = fishType:getStartingFatigue()
    return self
end

function FishInstance:getPreviewMesh()
    if self.fishType.previewMesh then
        return self.fishType.previewMesh
    else
        local object = self:getInstanceObject()
        if object then
            return object.mesh
        end
    end
end


--[[
    Returns the name of the fish
]]
function FishInstance:getName()
    return self:getInstanceObject().name
end

function FishInstance:getInstanceObject()
    return tes3.getObject(self.objectId or self.fishType.baseId) --[[@as tes3misc]]
end

function FishInstance:getSplashSize()
    return math.remap(self.fishType.size, 1.0, 5.0, 1.0, 3.0)
end

function FishInstance:getRippleSize()
    return self.fishType.size
end

function FishInstance:getChaseSpeed()
    local variance = math.random(80, 120) / 100
    local speed = variance * math.max(self.fishType.speed, config.constants.MINIMUM_CHASE_SPEED)
    logger:debug("getChaseSpeed() speed: %s", speed)
    return speed
end

function FishInstance:getReelSpeed()
    local variance = math.random(80, 120) / 100
    local speed =  self.fishType.speed * variance * 1.5
    logger:debug("getReelSpeed() speed: %s", speed)
    return speed
end

function FishInstance:getTurnSpeed()
    local min = 3
    local max = 5
    return math.clamp(math.remap(self.fishType.size, 1, 4, max, min), min, max)
end

function FishInstance:getDistanceModifier()
    local currentFatigue = self.fatigue
    local maxFatigue = self.fishType:getStartingFatigue()
    local difficulty = self.fishType.difficulty
    local difficultyModifier = math.remap(difficulty,
        0, 100,
        90, 110
    )
    local fatigueEffect = math.remap(currentFatigue,
        0, maxFatigue,
        0, 1.0
    )
    local distance = difficultyModifier * fatigueEffect
    logger:debug("%s getDistanceModifier() distance: %s",
        self:getName(), distance)
    return distance
end


function FishInstance:getPrefixedName()
    local name = self:getName()
    if self.fishType.namePrefix then
        return self.fishType.namePrefix + " " + name
    else
        return common.addAOrAnPrefix(self:getName())
    end
end

return FishInstance