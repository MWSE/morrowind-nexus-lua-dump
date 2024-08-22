local common = require("mer.fishing.common")
local logger = common.createLogger("LocationManager")
local CELL_SIZE = 8192


--[[
    categoryId: Category{
        locationTypeId: LocationType{
            descrtiption: string,
            color: #rrggbb
            locations: [
                Location{
                    cellX: number,
                    cellY: number,
                    radius: number,
                }
            ]
        }
    }
]]

---@class Fishing.Location.Category.config
---@field id string
---@field defaultType string|nil
---@field locationTypes Fishing.LocationType.config[]?

---@class Fishing.Location.Category : Fishing.Location.Category.config
---@field locationTypes table<string, Fishing.LocationType>

---@class Fishing.LocationType.config
---@field id string
---@field name string
---@field color string? E.g "#ff0000"

---@class Fishing.LocationType : Fishing.LocationType.config
---@field locations Fishing.Location[]

---@class Fishing.Location.config
---@field cellX number The X coordinate of the cell that this location is centered on
---@field cellY number The Y coordinate of the cell that this location is centered on
---@field radius number The number of cells from the center cell that are included in the location.
---@field locationType string The type of location that this location represents.
---@field name string? If provided, a custom locationType will be generated for this location.
---@field color string? E.g "#ff0000"

---@class Fishing.Location
---@field cellX number The X coordinate of the cell that this location is centered on
---@field cellY number The Y coordinate of the cell that this location is centered on
---@field radius number The number of cells from the center cell that are included in the location.
---@field locationType string The type of location that this location represents.


---@class Fishing.LocationManager
---@field categories table<string, Fishing.Location.Category> @A table of location categories indexed by id
local LocationManager = {
    categories = {},
}

---Register a LocationType Category
---@param e Fishing.Location.Category.config
function LocationManager.registerCategory(e)
    if not e.id then
        logger:error("Category must have an id")
        return
    end
    logger:debug("Registering category %s", e.id)

    ---@type Fishing.Location.Category
    local category = {
        id = e.id,
        defaultType = e.defaultType,
        locationTypes = {}
    }
    LocationManager.categories[category.id] = category --[[@as Fishing.Location.Category]]
    if e.locationTypes then
        for _, locationType in ipairs(e.locationTypes) do
            LocationManager.registerLocationType(category.id, locationType)
        end
    end
end

---Register a locationType for a category
---@param categoryId string
---@param locationType Fishing.LocationType.config
function LocationManager.registerLocationType(categoryId, locationType)
    if not LocationManager.categories[categoryId] then
        logger:error("No category registered for id %s", categoryId)
        return
    end
    if not locationType.id then
        logger:error("LocationType must have an id")
        return
    end
    if not locationType.name then
        logger:error("LocationType must have a name")
        return
    end
    logger:debug("Registering locationType %s for category %s", locationType.id, categoryId)
    if not LocationManager.categories[categoryId].locationTypes then
        LocationManager.categories[categoryId].locationTypes = {}
    end

    LocationManager.categories[categoryId].locationTypes[locationType.id] = {
        id = locationType.id,
        name = locationType.name,
        locations = {}
    }
end


---Register a location
---@param categoryId string
---@param location Fishing.Location.config
function LocationManager.registerLocation(categoryId, location)
    local category = LocationManager.categories[categoryId]
    if not category then
        logger:error("No category registered for id %s", categoryId)
        return
    end
    if not location.locationType then
        logger:error("Location must have a locationType")
        return
    end
    logger:debug("Registering location for category %s", categoryId)
    --Register a custom locationType if a name was provided
    if location.name then
        LocationManager.registerLocationType(categoryId, {
            id = location.locationType,
            name = location.name,
            color = location.color
        })
        location.name = nil
    end
    if not category.locationTypes[location.locationType] then
        logger:error("No locationType registered for id %s in category %s", location.locationType, categoryId)
        return
    end
    if not location.cellX then
        logger:error("Location must have a cellX")
        return
    end
    if not location.cellY then
        logger:error("Location must have a cellY")
        return
    end
    if not location.radius then
        logger:error("Location must have a radius")
        return
    end

    table.insert(category.locationTypes[location.locationType].locations, location)
end


---@param categoryId string
---@param position tes3vector3|nil
---@return table<string, Fishing.LocationType>
function LocationManager.getLocations(categoryId, position)
    local category = LocationManager.categories[categoryId]

    if not category then
        logger:warn("getLocations(): No locations registered for categoryId %s", categoryId)
        return {}
    end

    if tes3.player.cell.isInterior then
        logger:debug("Player is in an interior")
        return {interior = true}
    end

    ---@type table<string, Fishing.LocationType>
    local foundLocationTypes = {}
    position = position or tes3.player.position
    logger:trace("Getting locations for category '%s' at cell position %s", categoryId, tes3vector2.new(tes3.player.position.x / CELL_SIZE, tes3.player.position.y / CELL_SIZE))

    for _, locationType in pairs(category.locationTypes) do
        for _, location in ipairs(locationType.locations) do
            local center = tes3vector2.new(location.cellX*CELL_SIZE, location.cellY*CELL_SIZE)
            local radius = location.radius*CELL_SIZE
            local distance = center:distance(tes3vector2.new(position.x, position.y))
            if distance < radius then
                foundLocationTypes[locationType.id] = locationType
            end
        end
    end
    if table.size(foundLocationTypes) == 0 then
        if category.defaultType then
            logger:debug("No valid locations found, defaulting to %s", category.defaultType)
            local defaultType = category.locationTypes[category.defaultType]
            if defaultType then
                foundLocationTypes[category.defaultType] = defaultType
            else
                logger:error("The defaultType %s is not registered for category %s", category.defaultType, categoryId)
            end
        end
    end
    return foundLocationTypes
end



return LocationManager