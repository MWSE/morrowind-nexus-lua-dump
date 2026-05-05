
local types = require("openmw.types")
local crimes = require('openmw.interfaces').Crimes
local types = require("openmw.types")
local world = require("openmw.world")
local cooldownTimer = 0
return {
    engineHandlers = {
        onUpdate = function(dt)
            if cooldownTimer > 0 then
                cooldownTimer = cooldownTimer - dt
                if cooldownTimer > 0 then
                    return
                else
                    cooldownTimer = 0
                end
            end
        end,
    },
    eventHandlers = {
        reportCrimeEvent_FC = function(data)
            if data and data.crime == "fleeingCrime" and cooldownTimer <= 0 then
                --print("Fleeing crime reported!")
                types.Player.setCrimeLevel(world.players[1],types.Player.getCrimeLevel(world.players[1]) + 500)
                world.players[1]:sendEvent("reportCrimeEvent_FC", { crime = "fleeingCrime" })
                cooldownTimer = 120
            end
        end,
    },
}