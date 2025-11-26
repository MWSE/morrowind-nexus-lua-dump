local world = require('openmw.world')
local types = require('openmw.types')

return {
    eventHandlers = {
        SF_UpdateGlobal = function(data)
            if not data.player or not data.global or not data.value then return end

            if data.player.type ~= types.Player then return end

            local globals = world.mwscript.getGlobalVariables(data.player)
            globals[data.global] = data.value
        end,
    }
}