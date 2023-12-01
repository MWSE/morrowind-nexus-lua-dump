local nearby = require("openmw.nearby")
local self = require("openmw.self")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local function getPlayer()
    for index, value in ipairs(nearby.actors) do
        if value.recordId == "player" then
            return value
        end
    end
end
local isFollowingPlayerTrue = false
local function isFollowingPlayer()
    isFollowingPlayerTrue = false
    local func = function(param) if param.target == getPlayer() and param.type == "Follow" then isFollowingPlayerTrue = true end end
    I.AI.forEachPackage(func)
    return isFollowingPlayerTrue
end
local function teleportFollower(data)
    if isFollowingPlayer() then
        core.sendGlobalEvent("LMM_TeleportToCell",
            {
                item = self,
                cellname = data.destCell,
                position = data.destPos,
                rotation = data.destRot
            })
    end
end
local function onActive()
    local package = I.AI.getActivePackage()
    if self.recordId:lower() == "teleport_summonmark" and isFollowingPlayer() then
        local player = getPlayer()
        player:sendEvent("saveMarkLoc")
    elseif self.recordId:lower() == "teleport_summonrecall" and isFollowingPlayer() then
        local player = getPlayer()
        player:sendEvent("openMarkMenu")
    end
end
return { engineHandlers = { onActive = onActive }, eventHandlers = { teleportFollower = teleportFollower } }
