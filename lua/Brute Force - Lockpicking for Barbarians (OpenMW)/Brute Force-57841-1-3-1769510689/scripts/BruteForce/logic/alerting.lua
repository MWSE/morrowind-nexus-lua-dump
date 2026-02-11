local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local nearby = require("openmw.nearby")

require("scripts.BruteForce.utils.openmw_utils")
require("scripts.BruteForce.utils.detection")

local sectionAlerting = storage.globalSection("SettingsBruteForce_alerting")
local sectionOnUnlock = storage.globalSection("SettingsBruteForce_onUnlock")

local function aggroGuards(actor)
    for _, nearbyActor in ipairs(nearby.actors) do
        if not types.NPC.objectIsInstance(nearbyActor) then
            goto continue
        end

        ---@diagnostic disable-next-line: undefined-field
        local class = nearbyActor.type.records[nearbyActor.recordId].class
        if string.lower(class) == "guard"
            or string.find(nearbyActor.recordId, "guard")
        then
            nearbyActor:sendEvent('StartAIPackage', { type = 'Pursue', target = actor.object })
        end

        ::continue::
    end
end

function AlertNpcs(actor)
    local bounty = sectionOnUnlock:get("bounty")
    if bounty <= 0 then return end

    local losMaxDistBase = sectionAlerting:get("losMaxDistBase")
    local losMaxDistSneakModifier = sectionAlerting:get("losMaxDistSneakModifier")
    local soundRangeBase = sectionAlerting:get("soundRangeBase")
    local soundRangeWeaponSkillModifier = sectionAlerting:get("soundRangeWeaponSkillModifier")
    local sneak = actor.type.stats.skills.sneak(actor).modified
    local weaponSkill = GetEquippedWeaponSkill(actor).modified

    local losMaxDist = losMaxDistBase - sneak * losMaxDistSneakModifier
    local soundRange = soundRangeBase - weaponSkill * soundRangeWeaponSkillModifier

    for _, nearbyActor in ipairs(nearby.actors) do
        local isNPC       = types.NPC.objectIsInstance(nearbyActor)
        local isPlayer    = types.Player.objectIsInstance(nearbyActor)
        local seesPlayer  = CanNpcSeePlayer(nearbyActor, actor, nearby, losMaxDist)
        local hearsPlayer = IsWithinDistance(nearbyActor, actor, soundRange)

        if isNPC and not isPlayer and (seesPlayer or hearsPlayer) then
            core.sendGlobalEvent("AddBounty", { player = actor, bounty = bounty })
            aggroGuards(actor)
            break
        end
    end
end