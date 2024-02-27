local world = require('openmw.world')
local types = require('openmw.types')

-- All we do here is set Global variables through an event call, because openmw.world has to be called from a global script.

return {
    eventHandlers = {
        grm_setGlobals = function(_data)
            local name = _data[1]
            local value = _data[2]
            world.mwscript.getGlobalVariables()[name] = value
        end
    }
}
