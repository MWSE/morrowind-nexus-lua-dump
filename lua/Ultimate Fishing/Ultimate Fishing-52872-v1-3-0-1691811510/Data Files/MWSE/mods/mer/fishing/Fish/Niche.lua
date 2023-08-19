local common = require("mer.fishing.common")
local logger = common.createLogger("Niche")

---@alias Fishing.FishType.Niche.Time
---| '"dawn"' #The fish is active during dawn
---| '"day"' #The fish is active during the day
---| '"dusk"' #The fish is active during dusk
---| '"night"' #The fish is active during the night

---A Niche defines where and when a fish can be found.
---@class Fishing.FishType.Niche.new.params
---@field regions? string[] If defined, limits fish to the regioned specified.
---@field cells? string[] If defined, limits fish to the cells specified. Uses pattern matching, for example "Vivec" will match "Vivec, Foreign Quarter Waistworks".
---@field times? Fishing.FishType.Niche.Time[] What times of day the fish is active. If undefined, the fish is always active.
---@field interiors? boolean `default: false` Whether the fish can be found in interiors. If undefined, the fish can not be found in interiors.
---@field exteriors? boolean `default: true` Whether the fish can be found in exteriors. If undefined, the fish can be found in exteriors.
---@field minDepth? number `default: 0` The minimum depth the fish can be found at.
---@field maxDepth? number The maximum depth the fish can be found at. If undefined, max depth is infinite.
---@field requirements? fun(self: Fishing.FishType.Niche): boolean A function that returns true if the fish can be found in the current cell. If undefined, the fish can be found everywhere.

---@class Fishing.FishType.Niche : Fishing.FishType.Niche.new.params
local Niche = {}

---Creates a new niche
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
    if o.cells then
        self.cells = {}
        for _, cell in ipairs(o.cells) do
            logger:trace("Cell: %s", cell)
            table.insert(self.cells, cell:lower())
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
    self.requirements = o.requirements
    return self
end


---Returns true if the fish can be found in the current cell
---@return boolean
function Niche:isInCell()
    local cell = tes3.player.cell
    logger:trace("Checking if in cell %s", cell.id)
    if not self.cells then
        logger:trace("No cells defined, fish are everywhere")
        -- If undefined, fish are everywhere
        return true
    end

    local cellId = cell.id:lower()
    for _, cellPattern in ipairs(self.cells) do
        if string.find(cellId, cellPattern) then
            logger:trace("Fish is in cell %s", cellId)
            return true
        end
    end
    logger:trace("Fish is not in cell %s", cellId)
    return false
end


---Returns true if the fish can be found in the current region
---@return boolean
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

---Returns the current timeslot(s) as a table
---@return string[]
local function getCurrentTimeslots( )
    local activeTimeslots = {}
    local hour = tes3.worldController.hour.value
    if hour >= 4 and hour < 8 then
        table.insert(activeTimeslots, "dawn")
    elseif hour >= 7 and hour < 17 then
        table.insert(activeTimeslots, "day")
    elseif hour >= 16 and hour < 20 then
        table.insert(activeTimeslots, "dusk")
    else
        table.insert(activeTimeslots, "night")
    end
    return activeTimeslots
end

---Returns true if the fish is active at the current time
---@return boolean
function Niche:isActiveAtTime()
    local timeslotss = getCurrentTimeslots()
    for _, timeslot in ipairs(timeslotss) do
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
    end
    logger:trace("Fish is not active for current time")
    return false
end

---Returns true if the fish is active in the current cell type (interior/exterior)
---@return boolean
function Niche:isActiveCellType()
    local cell = tes3.player.cell
    local isInterior = cell.isInterior and not cell.behavesAsExterior
    logger:trace("Checking if active in %s", isInterior and "interior" or "exterior")
    if isInterior then
        return self.interiors ~= false
    else
        return self.exteriors ~= false
    end
end

---Returns true if the fish is active at the given depth
---@param depth number
---@return boolean
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

---Returns true if the fish is active in the current cell
---@param depth number
---@return boolean
function Niche:isActive(depth)
    local isActive = self:isInRegion()
        and self:isInCell()
        and self:isActiveAtTime()
        and self:isActiveCellType()
        and self:isAtDepth(depth)
        and (self.requirements == nil or self:requirements())
    logger:trace("Fish is %s", isActive and "active" or "inactive")
    return isActive
end

return Niche
