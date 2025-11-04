local this = {}

this.stations = {}

--{ id = "furn_anvil00", name = "Anvil", namePattern = "hammer"  },
function this.addStation(newStation)
    local errorMsg = "Invalid station object. Must be in the form { id, name, toolIdPattern }"
    assert(newStation.id, errorMsg)
    assert(newStation.name, errorMsg)
    assert(newStation.toolIdPattern, errorMsg)

    mwse.log("[Realistic Repair] Adding station: %s", newStation.id)
    local stationId = string.lower(newStation.id)
    this.stations[stationId] = this.stations[stationId] or {
        name = newStation.name,
        toolPatterns = {}
    }
    
    table.insert(this.stations[stationId].toolPatterns, newStation.toolIdPattern )
end

return this