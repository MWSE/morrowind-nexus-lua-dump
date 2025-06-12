local world = require('openmw.world')
local types = require('openmw.types')
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

--[[local function onActorActive(actor)
    if actor.type == types.NPC and types.NPC.record(actor).class == 'bookseller' then
        local inv = types.Actor.inventory(actor)
        if inv:countOf('bk_PathOfTheAdventurer') == 0 then
            --add bk_PathOfTheAdventurer
            local obj = world.createObject('bk_PathOfTheAdventurer')
            obj:moveInto(inv)
        end
    end
end--]]

return {
    engineHandlers = {
        onUpdate = onUpdate,
        --onActorActive = onActorActive,
    },
    eventHandlers = {
        [mDef.events.skipGameHours] = function(data) skipGameHours(data.player, data.hours) end,
    }
}