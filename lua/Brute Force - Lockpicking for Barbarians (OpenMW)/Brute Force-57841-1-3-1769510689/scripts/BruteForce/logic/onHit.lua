local storage = require("openmw.storage")
local types = require("openmw.types")
local core = require("openmw.core")
local I = require("openmw.interfaces")

require("scripts.BruteForce.utils.openmw_utils")

local sectionOnHit = storage.globalSection("SettingsBruteForce_onHit")
local sectionOnUnlock = storage.globalSection("SettingsBruteForce_onUnlock")
local sectionDebug = storage.globalSection("SettingsBruteForce_debug")
local l10n = core.l10n("BruteForce")

function RegisterAttack(o)
    return o
        and sectionDebug:get("modEnabled")
        and types.Lockable.objectIsInstance(o)
end

function IsLocked(o)
    return types.Lockable.isLocked(o)
end

function IsTrapped(o)
    return o.type.getTrapSpell(o)
        and sectionOnHit:get("triggerNonLockedTraps")
end

function AttackMissed(o, actor)
    -- check strength
    local str = actor.type.stats.attributes.strength(actor).modified
    local lockLevel = types.Lockable.getLockLevel(o)
    local toughness = lockLevel + sectionOnHit:get("strBonus")
    if toughness > str then
        ---@diagnostic disable-next-line: missing-parameter
        DisplayMessage(actor, l10n("player_too_weak"))
        return true
    end

    return math.random() > CalcHitChance(actor) and sectionDebug:get("enableMisses")
end

function DamageIfH2h(actor, missed)
    if missed and sectionOnHit:get("damageOnH2hMisses") then return end

    local weaponSlot = types.Actor.EQUIPMENT_SLOT.CarriedRight
    local weapon = actor.type.getEquipment(actor, weaponSlot)

    if weapon then return end

    actor:sendEvent("Hit", {
        sourceType = I.Combat.ATTACK_SOURCE_TYPES.Unspecified,
        strength = 1,
        attacker = actor,
        damage = {
            health = sectionOnHit:get("damageOnH2h"),
        },
        successful = true,
    })
end

function WeaponTooWorn(o, actor)
    if sectionOnHit:get("unlockWithBrokenWeapon") then return false end

    local weaponSlot = types.Actor.EQUIPMENT_SLOT.CarriedRight
    local weapon = actor.type.getEquipment(actor, weaponSlot)
    local wearMod = sectionOnUnlock:get("weaponWearModifier")

    if not weapon or wearMod == 0 then return false end

    local lockLevel = types.Lockable.getLockLevel(o)
    local weaponCondition = weapon.type.itemData(weapon).condition

    if lockLevel * wearMod > weaponCondition then
        ---@diagnostic disable-next-line: missing-parameter
        DisplayMessage(actor, l10n("weapon_too_worn"))
        return true
    else
        return false
    end
end
