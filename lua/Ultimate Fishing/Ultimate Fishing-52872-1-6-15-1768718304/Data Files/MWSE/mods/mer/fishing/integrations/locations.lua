local Interop = require("mer.fishing")

---@type Fishing.Location.Category.config[]
local categories = {
    {
        id = "water",
        defaultType = "saltwater",
        locationTypes = {
            {
                id = "saltwater",
                name = "Saltwater",
            },
            {
                id = "freshwater",
                name = "Freshwater"
            }
        }
    },
    {
        id = "climate",
        defaultType = "temperate",
        locationTypes = {
            {
                id = "arctic",
                name = "Arctic"
            },
            {
                id = "swamp",
                name = "Swamp"
            },
            {
                id = "tropical",
                name = "Tropical"
            },
            {
                id = "temperate",
                name = "Temperate"
            }
        }
    },
    {
        id = "location",
    }
}

local vanillaSolstheimRegion = {
    cellX = -22,
    cellY = 23,
    radius = 4,
}

local vanillaThirsk = {
    x = -19,
    y = 23
}

event.register("initialized", function()
    --Register categories
    for _, category in ipairs(categories) do
        Interop.registerLocationCategory(category)
    end

    local thirsk = tes3.getCell{ id = "Thirsk" }
    local difference = { x = thirsk.gridX - vanillaThirsk.x, y = thirsk.gridY - vanillaThirsk.y }

    ---@type Fishing.Location.config
    local solstheimLocation = {
        cellX = vanillaSolstheimRegion.cellX + difference.x,
        cellY = vanillaSolstheimRegion.cellY + difference.y,
        radius = vanillaSolstheimRegion.radius,
        locationType = "freshwater"
    }

    Interop.registerLocation("water", solstheimLocation)

    --Register from JSON config
    local locationConfig = mwse.loadConfig("UltimateFishing_regions")
    for categoryId, locationTypes in pairs(locationConfig) do
        ---@param locationTypeId string
        for locationTypeId, locationType in pairs(locationTypes) do

            mwse.log("id: %s", locationTypeId)
            mwse.log("name: %s", locationType.name)
            mwse.log("color: %s", locationType.color)

            Interop.registerLocationType(categoryId, {
                id = locationTypeId,
                name = locationType.name,
                color = locationType.color
            })
            for _, location in ipairs(locationType.locations) do
                location.locationType = locationTypeId
                Interop.registerLocation(categoryId, location)
            end
        end
    end
end)