---@class RealisticRepair.StationService
--- Manages repair station state and detection.
--- Provides clean API for checking station status.
local StationService = {}

local config = require("mer.RealisticRepair.config")
local logger = mwse.Logger.new{
    logLevel = config.mcm.logLevel,
}

---Get the current station the player is looking at
---@return table? station The station config object, or nil if not at a station
function StationService.getCurrentStation()
    return tes3.player.tempData.realisticRepairCurrentStation
end

---Set the current station the player is looking at
---@param station table? The station config object, or nil to clear
function StationService.setCurrentStation(station)
    tes3.player.tempData.realisticRepairCurrentStation = station
    if station then
        logger:trace("Set current station to: %s", station.name)
    else
        logger:trace("Cleared current station")
    end
end

---Check if the player is currently at a repair station
---@return boolean
function StationService.isAtStation()
    return StationService.getCurrentStation() ~= nil
end

---Get the station name if at a station
---@return string? stationName
function StationService.getStationName()
    local station = StationService.getCurrentStation()
    return station and station.name
end

---Check if a repair tool matches the current station's requirements
---@param item tes3repairTool
---@return boolean matches
function StationService.isToolValidForStation(item)
    local station = StationService.getCurrentStation()
    if not station then
        return false
    end

    if item.objectType ~= tes3.objectType.repairItem then
        return false
    end

    for _, pattern in ipairs(station.toolPatterns) do
        if string.find(string.lower(item.name), string.lower(pattern)) then
            return true
        end
    end

    return false
end

---Set the "at station" flag for the next repair menu opening
---This flag is used by repair calculations to apply station bonuses
---@param atStation boolean
function StationService.setRepairMenuStationFlag(atStation)
    tes3.player.tempData.realisticRepairAtStation = atStation
    logger:debug("Set repair menu station flag: %s", tostring(atStation))
end

---Check if the repair menu was opened at a station
---@return boolean
function StationService.isRepairMenuAtStation()
    return tes3.player.tempData.realisticRepairAtStation or false
end

---Clear the "at station" flag (called after repair menu closes)
function StationService.clearRepairMenuStationFlag()
    tes3.player.tempData.realisticRepairAtStation = false
    logger:debug("Cleared repair menu station flag")
end

return StationService
