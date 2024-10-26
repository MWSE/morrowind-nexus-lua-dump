local common = require("mer.fishing.common")
local logger = common.createLogger("BaitType")

---@class Fishing.BaitType.classCatchChances
---@field small number
---@field medium number
---@field large number
---@field loot number

---@class Fishing.BaitType
---@field id Fishing.Bait.type
---@field name string
---@field description string
---@field getHookChance? fun(self:Fishing.BaitType):number Returns a multiplier on the chance that any fish will get hooked
---@field classCatchChances Fishing.BaitType.classCatchChances
local BaitType = {
    registeredBaitTypes = {},
    classCatchChances = {
        small = 0.5,
        medium = 0.2,
        large = 0.2,
        loot = 0.1,
    }
}


---@param e Fishing.BaitType
---@return Fishing.BaitType
function BaitType.new(e)
    logger:assert(type(e.id) == "string", "BaitType must have an id")
    logger:assert(type(e.name) == "string", "BaitType must have a name")
    if e.classCatchChances then
        local total = 0
        for _, chance in pairs(e.classCatchChances) do
            total = total + chance
        end
        logger:assert(total - 1 <= math.epsilon, "BaitType %s classCatchChances must add up to 1.0. Got: %s", e.id, total)
    end
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