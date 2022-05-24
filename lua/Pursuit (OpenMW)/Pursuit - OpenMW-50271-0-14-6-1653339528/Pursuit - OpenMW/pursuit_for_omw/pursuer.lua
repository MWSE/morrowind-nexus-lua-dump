local self = require("openmw.self")
local time = require("openmw_aux.time")
local nearby = require("openmw.nearby")
local core = require("openmw.core")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local aux_util = require("openmw_aux.util")
local auxiliary = require('pursuit_for_omw.auxiliary')



local pursueTarget



time.runRepeatedly(
    function()
        if not (ai.getActiveTarget("Combat") or ai.getActiveTarget("Pursue")) then
            pursueTarget = nil
            return
        end

        pursueTarget = ai.getActivePackage().target
        
        if types.Actor.stats.dynamic.health(pursueTarget).current <= 0 then
            return
        end

        if pursueTarget.type ~= types.Player then
            pursueTarget:sendEvent("Pursuit_pursuerData_eqnx", self)
        end
    end,
    0.1 * time.second
)



return {
    engineHandlers = {

    },
}
