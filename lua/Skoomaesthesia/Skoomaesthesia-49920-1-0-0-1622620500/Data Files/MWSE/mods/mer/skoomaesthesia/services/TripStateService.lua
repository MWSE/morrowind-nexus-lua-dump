--[[
    Keeps track of the state of the Skooma hallucination
]]

local TripStateService = {}
local config = require('mer.skoomaesthesia.config')
local Util = require('mer.skoomaesthesia.util.Util')
local STATES = {
    beginning = "beginning",
    active = "active",
    ending = "ending"
}

function TripStateService.updateState(newState)
    if not config.persistent then return end
    if (newState ~= nil) and not STATES[newState] then
        Util.log:error("Tried to update to an invalid trip state")
        return
    end
    local oldState = config.persistent.tripState
    config.persistent.tripState = STATES[newState]
    local eventData = {
        oldState = oldState,
        newState = config.persistent.tripState,
    }
    event.trigger("Skoomaesthesia:TripStateUpdated", eventData)
end

function TripStateService.getState()
    if config.persistent then
        return config.persistent.tripState
    end
end

function TripStateService.isState(state)
    return config.persistent and (config.persistent.tripState == state)
end

return TripStateService