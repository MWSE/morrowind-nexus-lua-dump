local common = require("mer.fishing.common")
local logger = common.createLogger("Habitat")

local LocationManager = require("mer.fishing.Habitat.LocationManager")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")

---@alias Fishing.Habitat.WaterType
---| '"saltwater"' #The fish is found in saltwater
---| '"freshwater"' #The fish is found in freshwater

---@alias Fishing.Habitat.Time
---| '"dawn"' #The fish is active during dawn
---| '"day"' #The fish is active during the day
---| '"dusk"' #The fish is active during dusk
---| '"night"' #The fish is active during the night

---@alias Fishing.Habitat.Climate
---| '"arctic"' Cold, snowy, and icy
---| '"temperate"' Mild, with four distinct seasons
---| '"tropical"' Hot and humid, with a wet and dry season
---| '"swamp"' Wet, humid, and marshy

---@type table<Fishing.Habitat.Time, {start: number, finish: number}>
local timesOfDay = {
    dawn = { start = 5, finish = 8 },
    day = { start = 6, finish = 19 },
    dusk = { start = 17, finish = 20 },
    night = { start = 19, finish = 6 },
}


---A Habitat defines where and when a fish can be found.
---@class Fishing.Habitat.new.params
---@field regions? string[] If defined, limits fish to the regioned specified.
---@field cells? string[] If defined, limits fish to the cells specified. Uses pattern matching, for example "Vivec" will match "Vivec, Foreign Quarter Waistworks".
---@field times? Fishing.Habitat.Time[] What times of day the fish is active. If undefined, the fish is always active.
---@field interiors? boolean `default: false` Whether the fish can be found in interiors. If undefined, the fish can not be found in interiors.
---@field exteriors? boolean `default: true` Whether the fish can be found in exteriors. If undefined, the fish can be found in exteriors.
---@field minDepth? number `default: 0` The minimum depth the fish can be found at.
---@field maxDepth? number The maximum depth the fish can be found at. If undefined, max depth is infinite.
---@field requirements? fun(self: Fishing.Habitat): boolean A function that returns true if the fish can be found in the current cell. If undefined, the fish can be found everywhere.
---@field waterType? string The type of water the fish can be found in.
---@field climates? Fishing.Habitat.Climate[] The climate the fish can be found in. If undefined, the fish can be found in all climates
---@field locations? string[] The specific locations this fish can be found in. If undefined, the fish can be found in all water types


---@class Fishing.Habitat : Fishing.Habitat.new.params
local Habitat = {}

local defaults = {
    interiors = false,
    exteriors = true,
    minDepth = 0,
}

---Creates a new habitat
---@param o Fishing.Habitat.new.params
---@return Fishing.Habitat
function Habitat.new(o)
    o = o or {}
    ---@type Fishing.Habitat
    local self = table.copy(o)
    table.copymissing(self, defaults)
    setmetatable(self, { __index = Habitat })
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
    return self
end


---Returns true if the fish can be found in the current cell
---@return boolean
function Habitat:isInCell()
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
function Habitat:isInRegion()
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
    for timeslot, times in pairs(timesOfDay) do
        local check = hour >= times.start and hour < times.finish
        if times.start > times.finish then
            check = hour >= times.start or hour < times.finish
        end
        if check then
            table.insert(activeTimeslots, timeslot)
        end
    end

    return activeTimeslots
end

---Returns true if the fish is active at the current time
---@return boolean
function Habitat:isActiveAtTime()
    local timeslots = getCurrentTimeslots()
    for _, timeslot in ipairs(timeslots) do
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
function Habitat:isActiveCellType()
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
---@param depth number? If not provided, depth check is skipped
---@return boolean
function Habitat:isAtDepth(depth)
    if depth == nil then return true end

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

---Returns true if the fish is active in the current water type
---@return boolean
function Habitat:isInLocation(position)
    logger:debug("Checking if fish is in location")
    if not self.locations then
        logger:debug("No locations defined")
        return true
    end
    local validLocations = LocationManager.getLocations("location", position)

    for _, location in ipairs(self.locations) do
        if validLocations[location] then
            logger:debug("Fish is in water type %s", location)
            return true
        end
    end
    logger:debug("Fish is not in any valid location types")
    return false
end

function Habitat:isInWaterType(position)
    logger:debug("Checking if fish is in water type")
    if not self.waterType then
        logger:debug("No water type defined")
        return true
    end
    local waterTypes = LocationManager.getLocations("water", position)

    if waterTypes.interior then
        logger:debug("Player is in an interior")
        return true
    end

    if waterTypes[self.waterType] then
        logger:debug("Fish is in water type %s", self.waterType)
        return true
    end
    logger:debug("Fish is not in water type %s", self.waterType)
    return false
end

function Habitat:isInClimate(position)
    logger:debug("Checking if fish is in climate")

    if not self.climates then
        logger:debug("No climate defined")
        return true
    end
    local climates = LocationManager.getLocations("climate", position)

    if climates.interior then
        logger:debug("Player is in an interior")
        return true
    end

    for _, climate in ipairs(self.climates) do
        if climates[climate] then
            logger:debug("Fish is in climate %s", climate)
            return true
        end
    end
    logger:debug("Fish is not in any valid climates")
    return false
end

---Returns true if the fish is active in the current cell
---@param depth number?
---@return boolean
function Habitat:isActive(depth)
    local position = tes3.player.position
    local lure = FishingStateManager.getLure()
    if lure then position = lure.position end

    local isActive = self:isInRegion()
        and self:isInCell()
        and self:isActiveAtTime()
        and self:isActiveCellType()
        and self:isAtDepth(depth)
        and self:isInLocation(position)
        and self:isInWaterType(position)
        and self:isInClimate(position)
        and (self.requirements == nil or self:requirements())
    logger:trace("Fish is %s", isActive and "active" or "inactive")
    return isActive
end

---Returns a message box with the habitat information
---@param position tes3vector3?
function Habitat.showHabitatMessage(position)
    position = position or tes3.player.position
    local values = {}
    local waterTypes = LocationManager.getLocations("water", position)
    if table.size(waterTypes) > 0 then
        for _, waterType in pairs(waterTypes) do
            table.insert(values, waterType.name)
        end
    else
        logger:error("No water types found")
    end

    local climates = LocationManager.getLocations("climate")
    if table.size(climates) > 0 then
        for _, climate in pairs(climates) do
            table.insert(values, climate.name)
        end
    end

    for i, value in ipairs(values) do
        values[i] = value:gsub("^%l", string.upper)
    end

    tes3.messageBox(table.concat(values, ", "))
end

return Habitat
