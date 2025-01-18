local FishInstance = require("mer.fishing.Fish.FishInstance")
local AlphaBlendController = require("mer.fishing.Camera.AlphaBlendController")
local Habitat = require("mer.fishing.Habitat.Habitat")
local common = require("mer.fishing.common")
local logger = common.createLogger("FishType")
local config = require("mer.fishing.config")
local Bait = require("mer.fishing.Bait.Bait")
local Ashfall = include("mer.ashfall.interop")
local Harvest = require("mer.fishing.Harvest")
local FishingSkill = require("mer.fishing.FishingSkill")
local CraftingFramework = include("CraftingFramework")

---@alias Fishing.FishType.rarity
---| '"common"'
---| '"uncommon"'
---| '"rare"'
---| '"legendary"'

---@alias Fishing.FishType.class
---| '"small"' Small fish are used as bait for catching larger fish
---| '"medium"' Medium fish are good for eating or selling
---| '"large"' Large fish are hard to catch, but highly valuable
---| '"loot"' Not a fish, but sometimes you catch random loot

---@class Fishing.FishType.Harvestable
---@field id string The id of the object that is harvested
---@field min number The minimum amount of the object that is harvested
---@field max number The maximum amount of the object that is harvested
---@field isMeat? boolean If true, the object is treated as meat for Ashfall cooking purposes. Default false
---@field isTrophy? boolean If true, will be set up as static Activator in Crafting Framework. Default false

---@class Fishing.FishType.new.params
---@field baseId string The id of the base object representation of the fish
---@field hangable? boolean If true, the fish can be hung from a rack
---@field variants? string[] A table of variant ids that can be selected when instancing this fish
---@field previewMesh? string The mesh to be displayed in the trophy menu
---@field description? string The description to be displayed when the fish is caught
---@field speed? number The base speed of the fish, in units per second. Default 100
---@field size? number A multiplier on the size of the ripples. Default 1.0
---@field difficulty? number The difficulty of catching the fish, out of 100. Default 10 (easy)
---@field class? Fishing.FishType.class The class of the fish. Default "medium"
---@field rarity? Fishing.FishType.rarity The rarity of the fish. Default "common"
---@field habitat? Fishing.Habitat.new.params The habitat where the fish can be found
---@field harvestables? Fishing.FishType.Harvestable[] The item that can be harvested from the fish
---@field isBaitFish? boolean If true, this fish can be used as live bait. Default false
---@field totalPopulation? number If set, only this many fish of this type can ever be caught. Default nil
---@field namePrefix? string #If defined, will override the prefix before the name. E.g. "a fish", "an amulet" or "the Mesmer Ring"
---@field heightAboveGround? number #If set, this fish will crawl along the sea floor during the fishing minigame
---@field requirements? fun(self: Fishing.FishType):boolean #If defined, this fish type will only be available if this function returns true
---@field alphaSwitch? boolean #If true, the fish has a switch node for turning off alpha blending while looking through water

---@class Fishing.FishType : Fishing.FishType.new.params
---@field habitat Fishing.Habitat
---@field variants table<string, boolean> A set of variant ids that can be selected when instancing this fish
local FishType = {
    HANG_NODE = "HANG_FISH",
    --- A list of all registered fish types
    ---@type table<string, Fishing.FishType>
    registeredFishTypes = {},
    --- A list of multipliers for each rarity
    ---@type table<Fishing.FishType.rarity, number>
    rarityValues = {
        common = 0.60,
        uncommon = 0.25,
        rare = 0.10,
        legendary = 0.05,
    }
}

---@param e Fishing.FishType.new.params
function FishType.new(e)
    logger:assert(type(e.baseId) == "string", "FishType must have a baseId")
    logger:assert(type(e.speed) == "number", "FishType must have a speed")
    if e.previewMesh and not tes3.getFileExists(string.format("Meshes\\%s", e.previewMesh)) then
        logger:error("Mesh %s does not exist", e.previewMesh)
        e.previewMesh = nil
    end

    local defaults = {
        hangable = false,
        previewMesh = nil,
        description = nil,
        speed = 100,
        size = 1.0,
        difficulty = 10,
        class = "medium",
        rarity = "common",
        habitat = nil,
        harvestables = nil,
        isBaitFish = false,
        totalPopulation = nil,
        namePrefix = nil,
        heightAboveGround = nil,
        requirements = function() return true end
    }

    local fishType = table.copy(e, {})
    table.copymissing(fishType, defaults)
    fishType.habitat = Habitat.new(e.habitat)

    ---@type Fishing.FishType
    local self = setmetatable(fishType, { __index = FishType })
    self.baseId = e.baseId:lower()
    if e.variants then
        self.variants = {}
        for _, variant in ipairs(e.variants) do
            self.variants[variant:lower()] = true
        end
    end

    Harvest.registerFish(self)
    if Ashfall then
        local obj = self:getBaseObject()
        local fishIsMeat = obj ~= nil
            and obj.objectType == tes3.objectType.ingredient
            and self.class ~= "loot"
        if fishIsMeat then
             logger:debug("Registering %s as meat", obj.id)
             Ashfall.registerFoods{[obj.id] = "meat"}
        end
        --register isMeat harvestables
        if self.harvestables then
            for _, harvestable in ipairs(self.harvestables) do
                if harvestable.isMeat then
                    logger:debug("Registering %s as meat", harvestable.id)
                    Ashfall.registerFoods{ [harvestable.id] = "meat" }
                    Bait.register{
                        id = harvestable.id,
                        type = "bait",
                        uses = 10
                    }
                end
                if harvestable.isTrophy then
                    if CraftingFramework then
                        logger:debug("Registering %s as trophy", harvestable.id)
                        CraftingFramework.Recipe:new{
                            id = "Fishing:" .. harvestable.id,
                            craftableId = harvestable.id,
                            craftedOnly = false,
                            placedObject = harvestable.id .. "_s",
                            pinToWall = true,
                            placementSetting = "free",
                            blockPlacementSettingToggle = true,
                        }
                    end
                end
            end
        end
    end
    if self.alphaSwitch then
        AlphaBlendController.register(self.baseId)
    end

    return self
end

---@return Fishing.FishType | nil
function FishType.get(id)
    return FishType.registeredFishTypes[id:lower()]
end

---@return table<string, Fishing.FishType>
function FishType.getAll()
    return table.copy(FishType.registeredFishTypes)
end

---Register a new type of fish
---@param e Fishing.FishType.new.params
function FishType.register(e)
    local fish = FishType.new(e)
    FishType.registeredFishTypes[fish.baseId] = fish

    if fish.isBaitFish then
        Bait.register{
            id = fish.baseId,
            type = "baitfish",
            uses = 10,
        }
    end
    return fish
end

function FishType:getStartingFatigue()
    return math.remap(self.difficulty, 0, 100, 1, 400)
end

function FishType:getBaseObject()
    return tes3.getObject(self.baseId) --[[@as tes3misc]]
end

function FishType:canHarvest()
    return self.harvestables
        and #self.harvestables > 0
end

---Create an instance of a fish
---@return Fishing.FishType.instance|nil
function FishType:instance()
    return FishInstance.new(self)
end

--Return a catch multiplier based on rarity
function FishType:getRarityEffect()
    local rarityEffect = FishType.rarityValues[self.rarity] or 1.0
    local skillEffect = math.remap(FishingSkill.getCurrent(),
        0, 100,
        1.0, 2.0
    )
    rarityEffect = math.clamp(rarityEffect * skillEffect, 0, 1.0)
    return rarityEffect
end

---@return number min, number max The min and max distance from the lure
function FishType:getStartDistance()
    local MIN = config.constants.FISH_POSITION_DISTANCE_MIN
    local MAX = config.constants.FISH_POSITION_DISTANCE_MAX
    --Slow fish start closer to the lure
    local speed = math.clamp(self.speed, 0, 100)
    local speedEffect = math.remap(speed,
        0, 100,
        0.1, 1.0
    )
    return MIN * speedEffect, MAX * speedEffect
end

function FishType:getPreviewMesh()
    if self.previewMesh then
        return self.previewMesh
    else
        local object = self:getBaseObject()
        if object then
            return object.mesh
        end
    end
end

--Check whether this fish can be hung from a rack
--by checking its mesh for a HANG_FISH node
function FishType:canHang()
    return self.hangable
end


---@class Fishing.FishType.verbs
---@field Take string
---@field Release string
---@field caught string
---@field release string

function FishType:getVerbs()
    local verbs = {
        ---@type Fishing.FishType.verbs
        loot = {
            Take = "Взять",
            Release = "Выбросить",
            caught = "зацепили",
            release = "выбросили",
        },
        ---@type Fishing.FishType.verbs
        fish = {
            Take = "Взять",
            Release = "Отпустить",
            caught = "поймали",
            release = "отпустили",
        }
    }
    return verbs[self.class] or verbs.fish
end

---@return number #The total number of this fish that the player has caught
function FishType:getTotalCaught()
    return config.persistent.fishTypesCaught[self.baseId] or 0
end

---@return number|nil #The total population of this fish. If nil, this fish has an infinite population
function FishType:getPopulation()
    if self.totalPopulation == nil then return nil end
    local remaining = self.totalPopulation - self:getTotalCaught()
    return math.clamp(remaining, 0, self.totalPopulation)
end

---@param amount number #The amount to reduce the population by
---@return number|nil #The new population, or nil if this fish has an infinite population
function FishType:reducePopulation(amount)
    if self.totalPopulation == nil then return nil end
    local newNumCaught = math.clamp(self:getTotalCaught() + amount, 0, self.totalPopulation)
    config.persistent.fishTypesCaught[self.baseId] = newNumCaught
    return self:getPopulation()
end

---@param amount number #The amount to increase the population by
---@return number|nil #The new population, or nil if this fish has an infinite population
function FishType:increasePopulation(amount)
    if self.totalPopulation == nil then return nil end
    local newNumCaught = math.clamp(self:getTotalCaught() - amount, 0, self.totalPopulation)
    config.persistent.fishTypesCaught[self.baseId] = newNumCaught
    return self:getPopulation()
end

function FishType:isExtinct()
    if self.totalPopulation == nil then return false end
    local isExtinct = self:getPopulation() <= 0
    logger:debug("%s is %s", self.baseId, isExtinct and "extinct" or "not extinct")
    return isExtinct
end

---@param depth number?
---@return boolean #Whether this fish is active at the given depth
function FishType:isActive(depth)
    return self:requirements()
    and self.habitat:isActive(depth)
       and self:isExtinct() == false
end


return FishType