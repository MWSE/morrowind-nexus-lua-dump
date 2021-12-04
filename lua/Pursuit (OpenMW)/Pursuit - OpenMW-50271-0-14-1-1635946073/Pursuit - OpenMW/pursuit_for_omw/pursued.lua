local core = require("openmw.core")
local self = require("openmw.self")
local query = require("openmw.query")
local tabpursuer = {}

--time between active and inactive state during pursuit
local masa = 0


local this = {
    engineHandlers = {
        onActive = function()
            if not next(tabpursuer) then
                return
            end

            masa = core.getGameTimeInSeconds() - masa

            for k, v in pairs(tabpursuer) do
                if self:canMove() and v:canMove() then
                    core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx", {v, self.object, masa})
                else
                    tabpursuer = {}
                end
            end

            tabpursuer = {}
        end,
        onInactive = function()
            if not self:canMove() then
                return
            end
            masa = core.getGameTimeInSeconds()
            if self:getCombatTarget() and self:getCombatTarget().type == "Player" then
                core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx", {self.object, self:getCombatTarget()})
            end
        end
    },
    eventHandlers = {
        Pursuit_pursuerData_eqnx = function(data)
            tabpursuer[tostring(data)] = data
        end
    }
}


return this;
