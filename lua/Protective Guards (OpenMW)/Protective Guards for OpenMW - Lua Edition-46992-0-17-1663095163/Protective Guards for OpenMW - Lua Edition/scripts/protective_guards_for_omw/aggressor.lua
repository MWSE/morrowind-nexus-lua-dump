local self = require("openmw.self")
local nearby = require("openmw.nearby")
local time = require("openmw_aux.time")
local ai = require("openmw.interfaces").AI
local core = require("openmw.core")
local types = require("openmw.types")
local aux_util = require("openmw_aux.util")
local rTimer
local scanIfAttackingPlayer

--//check if this NPC is attacking a player every few seconds
--//yes? send event to the player to start guard protection

scanIfAttackingPlayer = function()
    if not ai.getActiveTarget("Combat") or not types.Actor.canMove(self) then
        return
    end

    if ai.getActiveTarget("Combat").type == types.Player then
        ai.getActiveTarget("Combat"):sendEvent("ProtectiveGuards_thisPlayerIsAttackedBy", {
            actor = self
        })
        rTimer()
        rTimer = nil
        rTimer = time.runRepeatedly(scanIfAttackingPlayer, math.random(2, 4) * time.second)
    end
end

rTimer = time.runRepeatedly(scanIfAttackingPlayer, math.random(1, 3) * time.second)

return {
    engineHandlers = {
        onInactive = function()
            if types.Actor.stats.dynamic.health(self).current <= 0 then
                rTimer()
                return 
            end
        end
    }
}
