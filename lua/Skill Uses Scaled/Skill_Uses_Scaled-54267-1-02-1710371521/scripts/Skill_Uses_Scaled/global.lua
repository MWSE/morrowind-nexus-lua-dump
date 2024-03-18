local core  = require('openmw.core')
local world = require('openmw.world')
local storage = require('openmw.storage')

return {
    eventHandlers = {
        SUS_updateGLOBvar = function(t) t.source:sendEvent('SUS_updateGLOBvar', {id = t.id, val = world.mwscript.getGlobalVariables(t.source)[t.id]}) end, -- t = {id = 'id', source = _obj}
    }
}
