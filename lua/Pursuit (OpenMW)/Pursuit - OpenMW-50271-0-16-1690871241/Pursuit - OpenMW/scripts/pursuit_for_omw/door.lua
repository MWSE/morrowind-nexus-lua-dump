local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local nearby = require("openmw.nearby")

local isActor = types.Actor.objectIsInstance
local isPlayer = types.Player.objectIsInstance
local DOOR = types.Door

-- todo, use the similar global event in v0.49
return {
    engineHandlers = {
        onActivated = function(actor)
            if actor:isValid() then
                if DOOR.isTeleport(self) then
                    if DOOR.destCell(self) == self.cell then
                        for _, nearbyActor in pairs(nearby.actors) do
                            if not isPlayer(nearbyActor) and isActor(nearbyActor) and (nearbyActor ~= actor) then
                                nearbyActor:sendEvent("Pursuit_goToNearestPursuitDoor_eqnx", {
                                    activatedDoor = self,
                                    activatingActor = actor
                                })
                            end
                        end
                    else
                        -- actor:sendEvent("Pursuit_getPursued_eqnx")
                    end
                end
                -- core.sendGlobalEvent("Pursuit_teleportToDoorDest_eqnx", { self, actor })
            end
        end

    }

}
