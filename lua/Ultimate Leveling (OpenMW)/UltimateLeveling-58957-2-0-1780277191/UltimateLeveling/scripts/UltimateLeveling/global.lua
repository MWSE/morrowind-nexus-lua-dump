local world = require('openmw.world')
--local core = require('openmw.core')
--local types = require('openmw.types')
local ulDef = require('scripts.UltimateLeveling.definition')

local reputation = {}

--[[local function onUpdate()
    for _, player in ipairs(world.players) do
        -- Check if Player Reputation has updated
        if reputation[player.id] then
            if core.contentFiles.has('Tamriel_Data.esm') and reputation[player.id] ~= then
                
            end
        end
        if not reputation[player.id] or reputation[player.id] ~= world.mwscript.getGlobalVariables(player)[ulDef.mwscriptGlobalVars.playerReputation] then
            reputation[player.id] = world.mwscript.getGlobalVariables(player)[ulDef.mwscriptGlobalVars.playerReputation]
            player:sendEvent(ulDef.events.playerReputation, {
                reputation = reputation
            })
        end
    end
end--]]

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
        onUpdate = function()
            for _, player in ipairs(world.players) do
                -- Check if Player Reputation has updated
                if not reputation[player.id] or reputation[player.id] ~= world.mwscript.getGlobalVariables(player)[ulDef.mwscriptGlobalVars.playerReputation] then
                    reputation[player.id] = world.mwscript.getGlobalVariables(player)[ulDef.mwscriptGlobalVars.playerReputation]
                    player:sendEvent(ulDef.events.updateReputation, { reputation = reputation })
                end
            end
        end,
        --onActorActive = onActorActive,
    },
}