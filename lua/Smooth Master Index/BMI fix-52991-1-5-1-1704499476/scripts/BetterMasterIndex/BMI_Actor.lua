local nearby = require("openmw.nearby")
local self = require("openmw.self")
local core = require("openmw.core")
local types = require("openmw.types")
local I = require("openmw.interfaces")
local function getPlayer()         --This
    if core.API_REVISION > 40 then --nearby.players was added after 0.48 was released.
        return nearby.players[1]--Not multiplayer friendly, but oh well
    end
    for index, value in ipairs(nearby.actors) do --This is the best way to get the player without events in 0.48
        if value.type == types.Player then
            return value
        end
    end
end
local isFollowingPlayerTrue = false
local function isFollowingPlayer()
    isFollowingPlayerTrue = false
    local func = function(param)
        --Check if the actor is following the player
        if param.target == getPlayer() and param.type == "Follow" then
            isFollowingPlayerTrue = true
        end
    end
    I.AI.forEachPackage(func)--This runs the above function for every AI package on this actor
    return isFollowingPlayerTrue
end
local function BMI_teleportFollower(data)
    if isFollowingPlayer() then --Only send a global event, if we are following the player.
        core.sendGlobalEvent("BMI_TeleportToCell",
            {
                item = self,
                cellname = data.destCell,
                position = data.destPos,
                rotation = data.destRot
            })
    end
end
return { engineHandlers = { onActive = onActive }, eventHandlers = { BMI_teleportFollower = BMI_teleportFollower } }
