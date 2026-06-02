local core = require('openmw.core')
local self = require('openmw.self')
local I = require("openmw.interfaces")
local nearby = require("openmw.nearby")


local function isFollowingPlayer(playerRef)
    if not playerRef then return end

    local res = false
    I.AI.forEachPackage(function (dt)
        if dt.target == playerRef and dt.type == "Follow" then
            res = true
        end
    end)

    return res
end


local followingPlayer = nil;


local function onInactive()
    core.sendGlobalEvent("QuestGuiderLite:ObjectInactive", self)
end


local function checkFollowingPlayer(data)
    local playerRef = data.player
    local isFollowing = isFollowingPlayer(playerRef)
    if followingPlayer ~= isFollowing or isFollowing then
        followingPlayer = isFollowing
        playerRef:sendEvent("QGL:followingPlayerChanged", {actor = self, isFollowing = followingPlayer, requestUpdate = data.requestUpdate})
    end
end


return {
    engineHandlers = {
        onInactive = onInactive,
    },
    eventHandlers = {
        Died = function()
            for _, pl in pairs(nearby.players) do
                pl:sendEvent("QGL:registerActorDeath", {object = self})
            end
            core.sendGlobalEvent("QGL:registerActorDeath", {object = self})
        end,
        ["QGL:checkFollowingPlayer"] = checkFollowingPlayer,
    },
}