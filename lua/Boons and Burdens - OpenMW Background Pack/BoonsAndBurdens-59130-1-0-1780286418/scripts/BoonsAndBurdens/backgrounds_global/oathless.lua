---@omw-context global
---@diagnostic disable: assign-type-mismatch
---@diagnostic disable: undefined-field
local registeredPlayers = {}
local healthTable = {}

local healthReductionScript = "scripts/BoonsAndBurdens/backgrounds_custom/oathless.lua"

local function followerListUpdated(data)
    if not next(registeredPlayers) then return end
    for _, fState in pairs(data.followers) do
        if not fState.followsPlayer
            or not fState.leader
            or not registeredPlayers[fState.leader.id]
        then
            goto continue
        end

        local isSummon = string.find(fState.actor.recordId, "_summon$")
            or fState.actor.recordId == "bonewalker_greater_summ"
        if not isSummon then goto continue end

        local health = fState.actor.type.stats.dynamic.health(fState.actor)
        if not healthTable[fState.actor.recordId] or healthTable[fState.actor.recordId] >= health.base then
            healthTable[fState.actor.recordId] = health.base
            fState.actor:addScript(healthReductionScript)
        end

        ::continue::
    end
end

local function onLoad(data)
    if not data then return end
    healthTable = data.healthTable or healthTable
end

local function onSave()
    return {
        healthTable = healthTable
    }
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        BoonsAndBurdens_registerHedgeConjurer = function(player)
            registeredPlayers[player.id] = player
        end,
        FDU_FollowerListUpdated = followerListUpdated,
    }
}
