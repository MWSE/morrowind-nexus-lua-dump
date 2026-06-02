local self = require("openmw.self")
local I = require("openmw.interfaces")
local core = require("openmw.core")


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


local function fastTravelFollower(data)
    local playerRef = data.player
    if not isFollowingPlayer(playerRef) then return end

    playerRef:sendEvent("AdvWMap:fastTravelFollowerData", {actor = self})
end


local function onInactive()
    core.sendGlobalEvent("AdvWMap:objectInactive", self)
end


return{
    engineHandlers = {
        onInactive = onInactive,
    },
    eventHandlers = {
        ["AdvWMap:fastTravelFollower"] = fastTravelFollower
    }
}
