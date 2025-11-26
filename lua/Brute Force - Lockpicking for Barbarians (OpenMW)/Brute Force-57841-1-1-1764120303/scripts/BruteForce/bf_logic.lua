local storage = require("openmw.storage")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local self = require("openmw.self")
local core = require("openmw.core")
local I = require("openmw.interfaces")

local omw_utils = require("scripts.BruteForce.utils.openmw_utils")
local detection = require("scripts.BruteForce.utils.detection")

local sectionDebug = storage.playerSection("SettingsBruteForce_debug")
local sectionUnlocking = storage.playerSection("SettingsBruteForce_unlocking")
local sectionAlerting = storage.playerSection("SettingsBruteForce_alerting")
local l10n = core.l10n("BruteForce")

local logic = {}

function logic.registerAttack(o)
    return sectionDebug:get("modEnabled")
        and types.Lockable.objectIsInstance(o)
        and types.Lockable.isLocked(o)
end

function logic.attackMissed(o)
    -- check strength
    local str = self.type.stats.attributes.strength(self).modified
    local lockLevel = types.Lockable.getLockLevel(o)
    local toughness = lockLevel + sectionUnlocking:get("strBonus")
    if toughness > str then
        self:sendEvent('ShowMessage', { message = l10n("too_weak") })
        return true
    end

    -- emulate hit chance
    if math.random() > omw_utils.calcHitChance(self) and not sectionDebug:get("alwaysHit") then
        return true
    end

    return false
end

function logic.unlock(o)
    if math.random() > sectionUnlocking:get("jamChance") then
        -- unlock lock
        core.sendGlobalEvent("Unlock", { target = o })
        return true
    else
        -- jam lock
        core.sendGlobalEvent("setJammedLock", { id = o.id, val = true })
        self:sendEvent('ShowMessage', { message = l10n("lock_got_jammed") })
        return false
    end
end

function logic.giveCurrWeaponXp()
    if not sectionUnlocking:get("enableXpReward") then return end
    I.SkillProgression.skillUsed(
        omw_utils.getEquippedWeaponSkillId(self),
        { useType = I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit }
    )
end

local function aggroGuards()
    for _, actor in ipairs(nearby.actors) do
        local class = actor.type.records[actor.recordId].class
        if string.lower(class) == "guard"
            or string.find(actor.recordId, "guard")
        then
            actor:sendEvent('StartAIPackage', { type = 'Pursue', target = self.object })
        end
    end
end

function logic.alertNpcs()
    local bounty = sectionAlerting:get("bounty")
    if bounty <= 0 then return end

    local losMaxDistBase = sectionAlerting:get("losMaxDistBase")
    local losMaxDistSneakModifier = sectionAlerting:get("losMaxDistSneakModifier")
    local soundRangeBase = sectionAlerting:get("soundRangeBase")
    local soundRangeWeaponSkillModifier = sectionAlerting:get("soundRangeWeaponSkillModifier")
    local sneak = self.type.stats.skills.sneak(self).modified
    local weaponSkill = omw_utils.getEquippedWeaponSkill(self).modified

    local losMaxDist = losMaxDistBase - sneak * losMaxDistSneakModifier
    local soundRange = soundRangeBase - weaponSkill * soundRangeWeaponSkillModifier

    for _, actor in ipairs(nearby.actors) do
        local isNPC       = types.NPC.objectIsInstance(actor)
        local isPlayer    = types.Player.objectIsInstance(actor)
        local seesPlayer  = detection.canNpcSeePlayer(actor, self, nearby, losMaxDist)
        local hearsPlayer = detection.isWithinDistance(actor, self, soundRange)

        if isNPC and not isPlayer and (seesPlayer or hearsPlayer) then
            core.sendGlobalEvent("addBounty", { player = self, bounty = bounty })
            aggroGuards()
            break
        end
    end
end

function logic.objectIsOwned(o)
    return o.owner.factionId or o.owner.recordId
end

function logic.damageContainerEquipment(o)
    if not sectionUnlocking:get("damageContentsOnUnlock") then return end
    for _, item in pairs(o.type.inventory(o):getAll()) do
        if omw_utils.itemCanBeDamaged(item) then
            local dmg = -math.random(item.type.records[item.recordId].health)
            core.sendGlobalEvent("ModifyItemCondition", {
                item = item,
                amount = dmg
            })
        end
    end
end

function logic.damageIfH2h()
    local weaponSkill = omw_utils.getEquippedWeaponSkillId(self)
    if weaponSkill == "handtohand" then
        local attack = {
            sourceType = I.Combat.ATTACK_SOURCE_TYPES.Misc,
            strength = 1,
            damage = {
                health = sectionUnlocking:get("damageOnH2h"),
            },
            successful = true,
        }
        self:sendEvent("Hit", attack)
    end
end

return logic
