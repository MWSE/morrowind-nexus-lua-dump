local storage = require('openmw.storage')
local world = require('openmw.world')

local data = storage.globalSection('The-Popular-Plague')

return {
    eventHandlers = {
        md24_furn_paradoxscale = function(e)
            data:set("cell", e.cell)
            data:set("position", e.position)
        end,
        md24_teleport_return = function()
            local cell = data:get("cell")
            local position = data:get("position")
            world.players[1]:teleport(cell, position)
        end
    }
}