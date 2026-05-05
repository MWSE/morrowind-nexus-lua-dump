local world = require('openmw.world')

local trackedGlobals = {}
local cachedVars = {}

local onUpdate = function()
    for _, player in ipairs(world.players) do
        if trackedGlobals[player.id] then
            local vars = world.mwscript.getGlobalVariables(player)
            for varName in pairs(trackedGlobals[player.id]) do
                local value = vars[varName]
                if cachedVars[player.id][varName] ~= value then
                    cachedVars[player.id][varName] = value
                    player:sendEvent('SW_GlobalChanged', { var = varName, newValue = value })
                end
            end
        end
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        SW_TrackGlobal = function(e)
            if not e.var or not e.player then return end
            trackedGlobals[e.player.id] = trackedGlobals[e.player.id] or {}
            trackedGlobals[e.player.id][e.var] = true
            cachedVars[e.player.id] = cachedVars[e.player.id] or {}
        end,
        SW_UntrackGlobal = function(e)
            if not e.var or not e.player then return end
            if trackedGlobals[e.player.id] then
                trackedGlobals[e.player.id][e.var] = nil
            end
        end,
    }
}