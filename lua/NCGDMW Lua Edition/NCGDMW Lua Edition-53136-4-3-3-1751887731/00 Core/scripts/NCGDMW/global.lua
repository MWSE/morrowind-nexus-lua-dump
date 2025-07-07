local world = require('openmw.world')

local mDef = require('scripts.NCGDMW.definition')

local function skipGameHours(player, hours)
    world.mwscript.getGlobalVariables(player)[mDef.mwscriptGlobalVars.skipGameHours] = hours
end

return {
    eventHandlers = {
        [mDef.events.skipGameHours] = function(data) skipGameHours(data.player, data.hours) end,
    }
}