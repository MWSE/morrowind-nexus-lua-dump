local storage = require("openmw.storage")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local self = require("openmw.self")
local core = require("openmw.core")
local I = require("openmw.interfaces")

local omw_utils = require("scripts.BruteForce.utils.openmw_utils")
local detection = require("scripts.BruteForce.utils.detection")

local sectionOnHit = storage.globalSection("SettingsBruteForce_onHit")
local sectionOnUnlock = storage.globalSection("SettingsBruteForce_onUnlock")
local sectionAlerting = storage.globalSection("SettingsBruteForce_alerting")
local sectionDebug = storage.globalSection("SettingsBruteForce_debug")
local l10n = core.l10n("BruteForce")

local logic = {}

function logic.registerAttack(o)
    return o
        and sectionDebug:get("modEnabled")
        and types.Lockable.objectIsInstance(o)
        and types.Lockable.isLocked(o)
end

function logic.attackMissed(o)
    -- check strength
    local str = self.type.stats.attributes.strength(self).modified
    local lockLevel = types.Lockable.getLockLevel(o)
    local toughness = lockLevel + sectionOnHit:get("strBonus")
    if toughness > str then
        omw_utils.displayMessage(self, l10n("player_too_weak"))
        return true
    end

    -- emulate hit chance
    if not sectionDebug:get("enableMisses") then return false end
    return math.random() > omw_utils.calcHitChance(self)
end

function logic.unlock(o)
    if math.random() > sectionOnHit:get("jamChance") then
        -- unlock lock
        core.sendGlobalEvent("Unlock", { target = o })
        return true
    else
        -- jam lock
        core.sendGlobalEvent("setJammedLock", { id = o.id, val = true })
        omw_utils.displayMessage(self, l10n("lock_got_jammed"))
        return false
    end
end

function logic.giveCurrWeaponXp()
    if not sectionOnUnlock:get("enableXpReward") then return end
    I.SkillProgression.skillUsed(
        omw_utils.getEquippedWeaponSkillId(self),
        { useType = I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit }
    )
end

local function aggroGuards()
    for _, actor in ipairs(nearby.actors) do
        if not types.NPC.objectIsInstance(actor) then
            goto continue
        end

        local class = actor.type.records[actor.recordId].class
        if string.lower(class) == "guard"
            or string.find(actor.recordId, "guard")
        then
            actor:sendEvent('StartAIPackage', { type = 'Pursue', target = self.object })
        end

        ::continue::
    end
end

function logic.alertNpcs()
    local bounty = sectionOnUnlock:get("bounty")
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

function logic.damageContainerEquipment(o)
    if not sectionOnUnlock:get("damageContents") then return end
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
    local weaponSlot = types.Actor.EQUIPMENT_SLOT.CarriedRight
    local weapon = self.type.getEquipment(self, weaponSlot)
    
    if weapon then return end
    
    self:sendEvent("Hit", {
        sourceType = I.Combat.ATTACK_SOURCE_TYPES.Misc,
        strength = 1,
        damage = {
            health = sectionOnHit:get("damageOnH2h"),
        },
        successful = true,
    })
end

function logic.wearWeapon(o, actor)
    local weaponSlot = types.Actor.EQUIPMENT_SLOT.CarriedRight
    local weapon = actor.type.getEquipment(actor, weaponSlot)
    local wearMod = sectionOnUnlock:get("weaponWearModifier")

    if not weapon or wearMod == 0 then return end

    local lockLevel = types.Lockable.getLockLevel(o)
    local dmg = -math.min(
        lockLevel * wearMod,
        weapon.type.records[weapon.recordId].health
    )

    core.sendGlobalEvent("ModifyItemCondition", {
        item = weapon,
        amount = dmg,
    })
end

function logic.weaponTooWorn(o)
    if sectionOnUnlock:get("unlockWithBrokenWeapon") then return false end

    local weaponSlot = types.Actor.EQUIPMENT_SLOT.CarriedRight
    local weapon = self.type.getEquipment(self, weaponSlot)
    local wearMod = sectionOnUnlock:get("weaponWearModifier")

    if not weapon or wearMod == 0 then return false end

    local lockLevel = types.Lockable.getLockLevel(o)
    local weaponCondition = weapon.type.itemData(weapon).condition

    if lockLevel * wearMod > weaponCondition then
        omw_utils.displayMessage(self, l10n("weapon_too_worn"))
        return true
    else
        return false
    end
end

return logic
