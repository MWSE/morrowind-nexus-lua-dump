local world = require("openmw.world")
local core = require("openmw.core")

require("scripts.FollowerDetectionUtil.utils.consts")

local followers = {}

local function notifyOtherScripts()
    for _, fState in pairs(followers) do
        fState.actor:sendEvent("FDU_UpdateFollowerList", { followers = followers })
    end

    for _, player in ipairs(world.players) do
        player:sendEvent("FDU_UpdateFollowerList", { followers = followers })
    end

    core.sendGlobalEvent("FDU_FollowerListUpdated", { followers = followers })
end

local function updateFollowerList(data)
    local state = data.state

    -- if duplicate
    if followers[state.actor.id] == state then return end

    followers[state.actor.id] = state
    notifyOtherScripts()
end

return {
    eventHandlers = {
        FDU_UpdateFollowerList = updateFollowerList
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        version = ModVersion,
        getFollowerList = function() return followers end,
    },
}
