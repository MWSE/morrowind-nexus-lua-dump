local common = require("mer.fishing.common")
local logger = common.createLogger("Niche")


---@alias Fishing.FishType.Niche.Time
---| '"dawn"' #The fish is active during dawn
---| '"day"' #The fish is active during the day
---| '"dusk"' #The fish is active during dusk
---| '"night"' #The fish is active during the night

---@class Fishing.FishType.Niche
---@field regions? string[] The regions where the fish can be found. If undefined, the fish can be found everywhere. Not checked when in interior cells
---@field times? Fishing.FishType.Niche.Time[] What times of day the fish is active. If undefined, the fish is always active.
---@field interiors? boolean `default: false` Whether the fish can be found in interiors. If undefined, the fish can not be found in interiors.
---@field exteriors? boolean `default: true` Whether the fish can be found in exteriors. If undefined, the fish can be found in exteriors.
---@field minDepth? number `default: 0` The minimum depth the fish can be found at.
---@field maxDepth? number The maximum depth the fish can be found at. If undefined, max depth is infinite.
local Niche = {}


function Niche.new(o)
    logger:trace("Creating niche: %s", require("inspect").inspect(o))
    local self = setmetatable({}, { __index = Niche })
    if not o then return self end
    if o.regions then
        self.regions = {}
        for _, region in ipairs(o.regions) do
            logger:trace("Region: %s", region)
            table.insert(self.regions, region:lower())
        end
    end
    self.times = o.times
    --interiors false by default
    if o.interiors ~= nil then
        self.interiors = o.interiors
    else
        self.interiors = false
    end
    self.exteriors = o.exteriors ~= false
    self.minDepth = o.minDepth or 0
    self.maxDepth = o.maxDepth
    return self
end

function Niche:isInRegion()
    local currentRegion = tes3.player.cell.region
    if not self.regions then
        logger:trace("No regions defined, fish are everywhere")
        -- If undefined, fish are everywhere
        return true
    end
    if not currentRegion then
        logger:trace("Cell has no region, return true")
        return true
    end

    local regionId = currentRegion.id:lower()
    logger:trace("Checking if in region %s", regionId)
    for _, region in ipairs(self.regions) do
        if region == regionId then
            logger:trace("Fish is in region %s", regionId)
            return true
        end
    end
    logger:trace("Fish is not in region %s", regionId)
    return false
end

local function getCurrentTimeslot( )
    local hour = tes3.worldController.hour.value
    if hour >= 4 and hour < 8 then
        return "dawn"
    elseif hour >= 7 and hour < 17 then
        return "day"
    elseif hour >= 16 and hour < 20 then
        return "dusk"
    else
        return "night"
    end
end

function Niche:isActiveAtTime()
    local timeslot = getCurrentTimeslot()

    logger:trace("Checking if active at %s", timeslot)
    if not self.times then
        logger:trace("No times defined, fish are always active")
        -- If undefined, fish are always active
        return true
    end
    for _, fishTime in ipairs(self.times) do
        if fishTime == timeslot then
            logger:trace("Fish is active at %s", timeslot)
            return true
        end
    end
    logger:trace("Fish is not active at %s", timeslot)
    return false
end

function Niche:isActiveCellType()
    local isInterior = tes3.player.cell.isInterior
    logger:trace("Checking if active in %s", isInterior and "interior" or "exterior")
    if isInterior then
        return self.interiors ~= false
    else
        return self.exteriors ~= false
    end
end

---@param depth number
function Niche:isAtDepth(depth)
    logger:trace("Checking if fish is at depth %s", depth)
    logger:trace("Min depth: %s, max depth: %s", self.minDepth, self.maxDepth)

    if self.minDepth and (depth < self.minDepth) then
        logger:trace("Fish is not at depth %s, min depth is %s", depth, self.minDepth)
        return false
    end
    if self.maxDepth and (depth > self.maxDepth) then
        logger:trace("Fish is not at depth %s, max depth is %s", depth, self.maxDepth)
        return false
    end
    return true
end

---@param depth number
function Niche:isActive(depth)
    local isActive = self:isInRegion()
        and self:isActiveAtTime()
        and self:isActiveCellType()
        and self:isAtDepth(depth)
    logger:trace("Fish is %s", isActive and "active" or "inactive")
    return isActive
end

return Niche
