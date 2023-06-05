local common = require("mer.fishing.common")
local logger = common.createLogger("BaitType")

---@class Fishing.BaitType
---@field id Fishing.Bait.type
---@field name string
---@field description string
---@field getHookChance fun(self:Fishing.BaitType):number Returns a multiplier on the chance that any fish will get hooked
---@field getFishEffect fun(self:Fishing.BaitType, fish:Fishing.FishType):number Returns a multiplier on the chance that a specific fish will get hooked
local BaitType = {
    registeredBaitTypes = {}
}

---@param e Fishing.BaitType
---@return Fishing.BaitType
function BaitType.new(e)
    logger:assert(type(e.id) == "string", "BaitType must have an id")
    logger:assert(type(e.name) == "string", "BaitType must have a name")
    e = e or {}
    setmetatable(e, BaitType)
    BaitType.__index = BaitType
    return e
end

--- Register a new bait type
---@param e Fishing.BaitType
---@return Fishing.BaitType
function BaitType.register(e)
    local baitType = BaitType.new(e)
    BaitType.registeredBaitTypes[e.id] = baitType
    return baitType
end

--- Get a registered bait type by id
---@param id string
---@return Fishing.BaitType
function BaitType.get(id)
    return BaitType.registeredBaitTypes[id]
end

function BaitType:getHookChance()
    logger:debug("Default hook chance: 1.0")
    return 1.0
end

function BaitType:getFishEffect(fish)
    logger:debug("Default fish effect: 1.0")
    return 1.0
end

return BaitType