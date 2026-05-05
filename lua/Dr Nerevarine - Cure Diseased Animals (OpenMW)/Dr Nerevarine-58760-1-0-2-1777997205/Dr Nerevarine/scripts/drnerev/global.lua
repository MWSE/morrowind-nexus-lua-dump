local types = require('openmw.types')
local core = require('openmw.core')
local world = require('openmw.world')
local async = require('openmw.async')
local util = require('openmw.util')
local cure = require('Scripts.drnerev.cure_g')


local function drnrReplaceCreature(data)
    
    local oldCreature = data.ill
    if not oldCreature or not oldCreature:isValid() then
        return
    end

    local callback = async:registerTimerCallback("drnrReplaceCreatureTimer" .. oldCreature.id .. "_" .. math.random(1, 100000), function()
        if not oldCreature or not oldCreature:isValid() then
            return
        end

        local pos = oldCreature.position
        local rot = oldCreature.rotation
        local cell = oldCreature.cell
        local newCreatureId = data.healfy

        local removed = pcall(function() oldCreature:remove() end)
        if not removed then
            return
        end

        local newCreature = world.createObject(newCreatureId, 1)
        newCreature:teleport(cell, pos, rot)

        cure.getGratitude(newCreatureId, cell, pos)

        async:newSimulationTimer(0.1, async:registerTimerCallback("drnrCalmDelay" .. newCreature.id .. "_" .. math.random(1, 100000), function()
            if newCreature:isValid() then
                newCreature:sendEvent('drnrCalm')
            end
        end))
    end)

    async:newSimulationTimer(2.0, callback)
end

return {
    eventHandlers = {
        drnrReplaceCreature = drnrReplaceCreature,
    }
}