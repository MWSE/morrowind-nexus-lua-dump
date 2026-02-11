local self = require("openmw.self")
local core = require("openmw.core")
local I = require("openmw.interfaces")

require("scripts.BruteForce.utils.consts")
require("scripts.BruteForce.logic.onHit")
require("scripts.BruteForce.logic.alerting")
require("scripts.BruteForce.utils.openmw_utils")

local function onObjectHit(o, var, res)
    if not RegisterAttack(o) then return end

    if not IsLocked(o) then
        if IsTrapped(o) then
            core.sendGlobalEvent("TriggerTrap", { o = o, player = self })
        end
        return
    end

    local missed = AttackMissed(o, self) or WeaponTooWorn(o, self)
    DamageIfH2h(self, missed)

    if missed then return end

    core.sendGlobalEvent("CheckJammedLock", { o = o, sender = self })
end

local function giveCurrWeaponXp()
    I.SkillProgression.skillUsed(
        GetEquippedWeaponSkillId(self),
        { useType = I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit }
    )
end

local function aggroGuards()
    AlertNpcs(self)
end

CheckDependencies(self, Dependencies)
I.impactEffects.addHitObjectHandler(onObjectHit)

return {
    eventHandlers = {
        GiveCurrWeaponXp = giveCurrWeaponXp,
        AggroGuards = aggroGuards,
    }
}
