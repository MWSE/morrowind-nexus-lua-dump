local world   = require('openmw.world')
local types   = require('openmw.types')
local storage = require('openmw.storage')

local globalSettings = storage.globalSection('Settings_tt_visiblecloaks')

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
            local saved = globalSettings:get('CLOAKNPC')
            cloakNpcEnabled = (saved == nil) and true or (saved ~= false)
            broadcastToNPCs(cloakNpcEnabled)
        end,
    },
    eventHandlers = {
        cloakNpcSettingChanged = function(data)
            cloakNpcEnabled = data.enabled
            globalSettings:set('CLOAKNPC', data.enabled)  -- persist it
            broadcastToNPCs(data.enabled)
        end,
    },
}