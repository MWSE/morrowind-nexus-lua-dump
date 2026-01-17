local world = require("openmw.world")
local core = require("openmw.core")

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

local function onSave()
    return followers
end

local function onLoad(saveData)
    if saveData then
        followers = saveData
    end
end

local function updateFollowerList(data)
    local state = data.state
    
    -- duplicate
    if followers[state.actor.id] == state then return end

    followers[state.actor.id] = state
    notifyOtherScripts()
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        FDU_UpdateFollowerList = updateFollowerList
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        getFollowerList = function() return followers end,
    },
}
