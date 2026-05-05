local world  = require('openmw.world')
local core   = require('openmw.core')
local util   = require('openmw.util')
local async   = require('openmw.async')
local shared = require('scripts.DoBA_shared')

local activeFollower = nil

local function spawnDaedra(actor, charge, spawnPos, playerStats, followerEnabled)
    local tierIndex = 0
    local list = nil

    for i, tier in ipairs(shared.DAEDRA_TIERS) do
        if charge <= tier.maxCharge then 
            list = tier.ids
            tierIndex = i
            break 
        end
    end

    if not list or #list == 0 then return end

    local threshold = 30 + (20 * (tierIndex - 1))
    local isTamed = false
    if followerEnabled and playerStats then
        if playerStats.int >= threshold and playerStats.will >= threshold and playerStats.conj >= threshold then
            isTamed = true
        end
    end

    local id     = list[math.random(#list)]
    local name   = shared.CREATURE_NAMES[id] or id
    
    if isTamed and activeFollower and activeFollower:isValid() then
        local oldFollower = activeFollower 
        
        activeFollower = nil

        oldFollower:sendEvent("CursedItem_Despawn_VFX")
        async:newUnsavableSimulationTimer(0.2, function()
            if oldFollower and oldFollower:isValid() and oldFollower.count > 0 then
                oldFollower:remove()
            end
        end)
    end

    local daedra = world.createObject(id)
    daedra:teleport(actor.cell, spawnPos, { onGround = true })
    daedra:addScript("scripts/daedra_combat.lua")
    daedra:sendEvent("CursedItem_PlayVFX_Self", {})

    if isTamed then
        activeFollower = daedra
        daedra:sendEvent("CursedItem_Follow", { target = actor })
        local msgList = shared.MESSAGES_FOLLOW or shared.MESSAGES
        local msg = string.format(msgList[math.random(#msgList)], name)
        actor:sendEvent("CursedItem_ShowMessage", { message = msg })
    else
        daedra:sendEvent("CursedItem_Attack", { target = actor })
        local msg = string.format(shared.MESSAGES[math.random(#shared.MESSAGES)], name)
        actor:sendEvent("CursedItem_ShowMessage", { message = msg })
    end
end

return {
    engineHandlers = {
        onSave = function()
            return { activeFollower = activeFollower }
        end,
        onLoad = function(saved)
            if saved then activeFollower = saved.activeFollower end
        end,
    },

    eventHandlers = {
        CursedItem_Summon = function(data)
            spawnDaedra(data.actor, data.charge, data.spawnPos, data.stats, data.followerEnabled)
        end,
        CursedItem_DaedraDied = function(data)
            if data.daedra and data.daedra:isValid() and data.daedra.count > 0 then
                if data.daedra == activeFollower then
                    activeFollower = nil
                end
                data.daedra:remove()
            end
        end,
    }
}