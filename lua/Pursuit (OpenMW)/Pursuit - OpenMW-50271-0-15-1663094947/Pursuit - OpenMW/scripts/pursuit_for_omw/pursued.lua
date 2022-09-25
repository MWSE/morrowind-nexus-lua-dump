local core = require("openmw.core")
local self = require("openmw.self")
local ai = require('openmw.interfaces').AI
local types = require('openmw.types')
local pursuers = {}
local masa = 0 --time between active and inactive state during pursuit

return {
    engineHandlers = {
        onActive = function()
            if not next(pursuers) then
                return
            end
            masa = core.getSimulationTime() - masa
            for pursuer in pairs(pursuers) do
                if types.Actor.canMove(self) and types.Actor.canMove(pursuer) then
                    core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx", {pursuer, self, masa})
                end
            end
            pursuers = {}
        end,
        onInactive = function()
            if not types.Actor.canMove(self) then
                return
            end
            masa = core.getSimulationTime()
            if ai.getActiveTarget('Combat') and ai.getActiveTarget('Combat').type == types.Player then
                core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx", {self, ai.getActiveTarget('Combat')})
                return
            end
            if ai.getActiveTarget('Pursue') and ai.getActiveTarget('Pursue').type == types.Player then
                core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx", {self, ai.getActiveTarget('Pursue')})
            end
        end
    },
    eventHandlers = {
        Pursuit_pursuerData_eqnx = function(data)
            pursuers[data] = true
        end
    }
}
