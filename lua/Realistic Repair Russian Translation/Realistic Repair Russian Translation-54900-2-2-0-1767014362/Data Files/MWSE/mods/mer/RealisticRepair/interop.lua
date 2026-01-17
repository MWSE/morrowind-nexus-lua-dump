---@class RealisticRepair.Interop
local interop = {}

local config = require("mer.realisticRepair.config")

---@class RealisticRepair.StationConfig
---@field id string The object ID of the station (anvil/forge)
---@field name string The display name of the station
---@field toolIdPattern string A pattern to match repair tool IDs associated with this station

---@class RealisticRepair.RegisteredStation
---@field id string The object ID of the station (anvil/forge)
---@field name string The display name of the station
---@field toolPatterns string[] A list of patterns to match repair tool IDs associated with this station

---@param newStation RealisticRepair.StationConfig
function interop.addStation(newStation)
    local errorMsg = "Invalid station object. Must be in the form { id, name, toolIdPattern }"
    assert(newStation.id, errorMsg)
    assert(newStation.name, errorMsg)
    assert(newStation.toolIdPattern, errorMsg)

    mwse.log("[Realistic Repair] Adding station: %s", newStation.id)
    local stationId = string.lower(newStation.id)
    config.stations[stationId] = config.stations[stationId] or {
        id = stationId,
        name = newStation.name,
        toolPatterns = {}
    }

    table.insert(config.stations[stationId].toolPatterns, newStation.toolIdPattern )
end

return interop