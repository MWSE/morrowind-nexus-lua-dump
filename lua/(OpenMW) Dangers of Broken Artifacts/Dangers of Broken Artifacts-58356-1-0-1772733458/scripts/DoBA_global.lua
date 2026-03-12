local world  = require('openmw.world')
local core   = require('openmw.core')
local shared = require('scripts.DoBA_shared')

math.randomseed(os.time())

local creatureNames = shared.CREATURE_NAMES
local messages      = shared.MESSAGES

local function getDaedraList(charge)
    for _, tier in ipairs(shared.DAEDRA_TIERS) do
        if charge <= tier.maxCharge then return tier.ids end
    end
end

local function spawnDaedra(actor, charge, spawnPos)
    local list   = getDaedraList(charge)
    local id     = list[math.random(#list)]
    local name   = creatureNames[id] or id
    local daedra = world.createObject(id, 1)
    daedra:teleport(actor.cell, spawnPos, {
        rotation = actor.rotation,
        onGround = true,
    })
    daedra:addScript("scripts/daedra_combat.lua")
    daedra:sendEvent("CursedItem_PlayVFX_Self", {
        effectId = core.magic.EFFECT_TYPE.SummonScamp
    })
    daedra:sendEvent("CursedItem_Attack", { target = actor })
    local msg = string.format(messages[math.random(#messages)], name)
    actor:sendEvent("CursedItem_ShowMessage", { message = msg })
end

return {
    eventHandlers = {
        CursedItem_Summon = function(data)
            spawnDaedra(data.actor, data.charge, data.spawnPos)
        end,
        CursedItem_DaedraDied = function(data)
            if data.daedra and data.daedra:isValid() then
                data.daedra:remove()
            end
        end
    }
}