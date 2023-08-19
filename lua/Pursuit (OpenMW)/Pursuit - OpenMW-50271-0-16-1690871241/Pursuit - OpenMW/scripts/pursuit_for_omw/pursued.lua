local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local storage = require("openmw.storage")
local SettingsPursuitMain = storage.globalSection("SettingsPursuitMain")
local canMove = types.Actor.canMove
local pursuers = {}
local masa = 0 -- time between active and inactive state during pursuit
local immune = false

local function getPursued()
    if not next(pursuers) or immune then
        pursuers = {}
        return
    end

    masa = core.getSimulationTime() - masa
    for _, pursuer in pairs(pursuers) do
        if canMove(pursuer) then
            pursuer:sendEvent("Pursuit_chaseCombatTarget_eqnx", {
                target = self,
                masa = masa
            })
        end
    end
    pursuers = {}
    masa = 0
end
return {
    engineHandlers = {
        onActive = function()
            getPursued()
        end,
        onInactive = function()
            masa = core.getSimulationTime()
        end
    },
    eventHandlers = {
        -- sent from pursuer.lua
        Pursuit_pursuerData_eqnx = function(actor)
            pursuers[tostring(actor)] = actor
        end,
        Pursuit_getPursued_eqnx = function()
            if self.type == types.Player then
                masa = core.getSimulationTime()
            end
            getPursued()
        end,
        Pursuit_isImmune_eqnx = function(bool)
            immune = bool
        end
    }
}
