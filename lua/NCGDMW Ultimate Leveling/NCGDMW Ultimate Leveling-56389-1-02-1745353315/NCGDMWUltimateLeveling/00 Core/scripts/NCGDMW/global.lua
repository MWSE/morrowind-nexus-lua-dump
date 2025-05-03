local world = require('openmw.world')

local mDef = require('scripts.NCGDMW.definition')

local function skipGameHours(player, hours)
    world.mwscript.getGlobalVariables(player)[mDef.mwscriptGlobalVars.skipGameHours] = hours
end

local reputation = {}

local function onUpdate()
    for _, player in ipairs(world.players) do
        -- Check if Player Reputation has updated
        if not reputation[player.id] or reputation[player.id] ~= world.mwscript.getGlobalVariables(player)[mDef.mwscriptGlobalVars.playerReputation] then
            reputation[player.id] = world.mwscript.getGlobalVariables(player)[mDef.mwscriptGlobalVars.playerReputation]
            player:sendEvent(mDef.events.playerReputation, {
                reputation = reputation
            })
        end
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        [mDef.events.skipGameHours] = function(data) skipGameHours(data.player, data.hours) end,
    }
}