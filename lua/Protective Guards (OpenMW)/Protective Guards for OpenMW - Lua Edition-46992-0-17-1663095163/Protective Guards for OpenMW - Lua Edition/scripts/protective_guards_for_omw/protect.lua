local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local time = require("openmw_aux.time")
local aux_util = require("openmw_aux.util")
local nearby = require("openmw.nearby")
local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")

return {
    engineHandlers = {
        --[[onUpdate = function(dt)
                local guards =
                    aux_util.mapFilter(
                    nearby.actors,
                    function(actor)
                        return actor ~= self.object and actor.type == types.NPC and
                            types.NPC.record(actor).class == "Guard"
                    end
                )
            if ai.getActiveTarget("Pursue") then
                for _, actor in pairs(guards) do
                    if (actor.position - self.position):length() < 512 then
                        actor:sendEvent("ProtectiveGuards_alertGuardPursue_eqnx", ai.getActiveTarget("Pursue"))
                    end
                end
            end
        end]]
    },
    eventHandlers = {
        ProtectiveGuards_alertGuard_eqnx = function(attacker)
            --causes this NPC to attack the attacker
            if not types.Actor.canMove(self) or not attacker:isValid() then
                return
            end
            ai.startPackage({type = "Combat", target = attacker})
        end,
        --[[ProtectiveGuards_alertGuardPursue_eqnx = function(pursueTarget)
            if types.NPC.record(self).class ~= "Guard" or not types.Actor.canMove(self) or not pursueTarget:isValid() then
                return
            end
            if ai.getActiveTarget("Pursue") then
                return
            end
            ai.startPackage({type = "Pursue", target = pursueTarget})
            pursueTarget:sendEvent("ProtectiveGuards_guardPursueNotifyPlayer_eqnx", self)
        end]]
    },
}
