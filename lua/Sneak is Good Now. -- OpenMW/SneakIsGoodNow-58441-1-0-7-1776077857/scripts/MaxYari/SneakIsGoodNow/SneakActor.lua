local mp = "scripts/MaxYari/SneakIsGoodNow/"

local types = require("openmw.types")
local nearby = require("openmw.nearby")
local omwself = require("openmw.self")
local I = require('openmw.interfaces')


local DEFS = require(mp .. 'utils/sneak_defs')


local function onGetFollowTargets(dt)
    for _, player in ipairs(nearby.players) do 
        player:sendEvent("MaxYariUtil_FollowTargets", {actor = omwself.object, targets = I.AI.getTargets("Follow")})
    end
end


I.Combat.addOnHitHandler(function(a)
    if not a.attacker then return end    
    if types.Player.objectIsInstance(a.attacker) and a.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Melee or a.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Ranged then 
        a.attacker:sendEvent(DEFS.e.ReportAttack, {attacker = a.attacker, target = omwself.object})
    end
end)

return {    
    eventHandlers = { MaxYariUtil_GetFollowTargets = onGetFollowTargets }
}