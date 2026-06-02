---@omw-context global
---@diagnostic disable: assign-type-mismatch
---@diagnostic disable: undefined-field
local storage = require("openmw.storage")
local time = require("openmw_aux.time")
local async = require("openmw.async")

local messages = require("scripts.BoonsAndBurdens.utils.messages")

local settings = storage.globalSection("SettingsBoonsAndBurdens_insecureConjurer")
local registeredPlayers = {}
local ignoredSummons = {}

local delayedAttack = async:registerTimerCallback(
    "delayedAttack",
    function(data)
        messages.show(data.leader, "msg_summonTurned",
            { summon_name = data.actor.type.records[data.actor.recordId].name }
        )
        data.actor:sendEvent(
            "StartAIPackage",
            { type = 'Combat', target = data.leader }
        )
    end
)

local function followerListUpdated(data)
    if not next(registeredPlayers) then return end
    for _, fState in pairs(data.followers) do
        if not fState.followsPlayer
            or not fState.leader
            or not registeredPlayers[fState.leader.id]
            or ignoredSummons[fState.actor.id]
        then
            goto continue
        end

        local isSummon = string.find(fState.actor.recordId, "_summon$")
            or fState.actor.recordId == "bonewalker_greater_summ"
        if not isSummon then goto continue end

        if math.random(100) < settings:get("disobeyChance") then
            fState.actor:sendEvent("RemoveAIPackages", "Follow")
            time.newSimulationTimer(1, delayedAttack,
                { actor = fState.actor, leader = fState.leader }
            )
        else
            ignoredSummons[fState.actor.id] = true
        end

        ::continue::
    end
end

return {
    eventHandlers = {
        BoonsAndBurdens_registerInsecureConjurer = function(player)
            registeredPlayers[player.id] = player
        end,
        FDU_FollowerListUpdated = followerListUpdated,
    }
}
