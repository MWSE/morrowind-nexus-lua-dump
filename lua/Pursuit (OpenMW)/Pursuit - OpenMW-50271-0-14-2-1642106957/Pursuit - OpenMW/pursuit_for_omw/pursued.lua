local core = require("openmw.core")
local self = require("openmw.self")
local query = require("openmw.query")
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
                if self:canMove() and pursuer:canMove() then
                    core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx", {pursuer, self, masa})
                end
            end
            pursuers = {}
        end,
        onInactive = function()
            if not self:canMove() then
                return
            end
            masa = core.getSimulationTime()
            if self:getCombatTarget() and self:getCombatTarget().type == "Player" then
                core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx", {self, self:getCombatTarget()})
            end
        end
    },
    eventHandlers = {
        Pursuit_pursuerData_eqnx = function(data)
            pursuers[data] = true
        end
    }
}
