local AI = require('openmw.interfaces').AI

local fleeingBards = {}
local combatTimer = 0

return {
    engineHandlers = {
        onUpdate = function(dt)
            if dt == 0 then return end

            if combatTimer > 0 then
                combatTimer = combatTimer - dt
            else
                return
            end

            -- filterTimer = math.min(filterTimer + dt, 1)
            -- if filterTimer < 1 then return end
            -- filterTimer = 0

            for id, time in pairs(fleeingBards) do
                if time > 0 then
                    fleeingBards[id] = time - dt
                else
                    fleeingBards[id] = nil
                end
            end

            AI.filterPackages(function(package)
                return package.type ~= 'Combat' or not package.target or not fleeingBards[package.target.recordId]
            end)
        end,
    },
    eventHandlers = {
        BC_FleeingBard = function(data)
            fleeingBards[data.actor.recordId] = 5 -- seconds timer
            combatTimer = 5
        end,
    }
}