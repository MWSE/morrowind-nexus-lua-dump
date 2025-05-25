local nearby = require("openmw.nearby")
local self = require("openmw.self")
local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local standingOn
local function checkStanding()
    local selfData = {}
    local result = nearby.castRay(self.position, util.vector3(self.position.x,
                                                              self.position.y,
                                                              self.position.z -
                                                                  1000),
                                  {ignore = self})

    if result.hitObject and result.hitObject ~= standingOn then
        standingOn = result.hitObject
        core.sendGlobalEvent("standUpdate",{actor = self, object = standingOn})
        
    elseif standingOn and not result.hitObject then
        standingOn = nil
        core.sendGlobalEvent("standUpdate",{actor = self, object = nil})
    end

end
local function getPlayer()
end
local isFollowingPlayerTrue = false
local function isFollowingPlayer(player)
    local func = function(param) if param.target == player and param.type == "Follow" then isFollowingPlayerTrue = true end end
    I.AI.forEachPackage(func)
    return isFollowingPlayerTrue
end
local delay = 0
local function onUpdate(dt)
    delay = delay + dt
 
    if delay > 0.5 then
        checkStanding()
        delay = 0
    end
end
local function GroupfollowerTeleport(data)
    local player = data.player
    local destCell = data.destCell
    local destPos = data.destPos
    if isFollowingPlayer(player) then
core.sendGlobalEvent("GroupFollowerTeleport",{actor = self, destCell = destCell,destPos = destPos})
    end
end
return {engineHandlers = {onUpdate = onUpdate}
,
eventHandlers = {
    GroupfollowerTeleport = GroupfollowerTeleport
}}
