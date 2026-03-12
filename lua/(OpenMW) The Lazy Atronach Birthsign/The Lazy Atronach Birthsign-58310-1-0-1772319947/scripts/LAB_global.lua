local world = require('openmw.world')
local types = require('openmw.types')

local COMBAT_SCRIPT     = "scripts/LAB_local.lua"
local TARGET_GHOST      = "ancestor_ghost_summon"
local TARGET_SPELL_ID   = "summon ancestral ghost atronach" 

return {
    engineHandlers = {
        onActorActive = function(actor)
            if actor.recordId == TARGET_GHOST then
                local player = world.players[1]
                if not player then return end
                
                local blessingActive = false
                local activeSpells = types.Actor.activeSpells(player)
                
                for _, s in pairs(activeSpells) do
                    if s.id == TARGET_SPELL_ID then 
                        blessingActive = true 
                        break 
                    end
                end
                
                if blessingActive then
                    actor:addScript(COMBAT_SCRIPT)
                    actor:sendEvent("ForceGhostAttack", { target = player })
                end
            end
        end
    }
}