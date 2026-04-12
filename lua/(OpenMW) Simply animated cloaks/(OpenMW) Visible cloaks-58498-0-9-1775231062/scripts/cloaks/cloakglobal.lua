local world   = require('openmw.world')
local types   = require('openmw.types')

local cloakNpcEnabled = true

local function broadcastToNPCs(enabled)
    for _, actor in ipairs(world.activeActors) do
        if actor.type == types.NPC and not types.Player.objectIsInstance(actor) then
            actor:sendEvent('cloakNpcToggled', { enabled = enabled })
        end
    end
end

return {
    engineHandlers = {
        onLoad = function()
            cloakNpcEnabled = true
        end,
    },
    eventHandlers = {
        cloakNpcSettingChanged = function(data)
            cloakNpcEnabled = data.enabled
            broadcastToNPCs(data.enabled)
        end,
    },
}