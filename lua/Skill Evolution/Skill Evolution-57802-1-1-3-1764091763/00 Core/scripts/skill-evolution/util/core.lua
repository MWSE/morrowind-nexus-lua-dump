local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')
local I = require('openmw.interfaces')

local log = require('scripts.skill-evolution.util.log')
local mDef = require('scripts.skill-evolution.config.definition')
local mH = require('scripts.skill-evolution.util.helpers')

local Skills = core.stats.Skill.records

local currBaseSkillModsKey
local lastUseAnimation

local module = {}

module.GravityAcceleration = 69.99125109 * 8.96
module.JumpVelocityFactor = 0.707
module.MaxSlopeAngle = math.rad(46.0)

module.self = {
    health = T.Actor.stats.dynamic.health(self),
    magicka = T.Actor.stats.dynamic.magicka(self),
    inventory = self.type.inventory(self),
    activeEffects = T.Actor.activeEffects(self),
    halfExtents = T.Actor.getPathfindingAgentBounds(self).halfExtents,
}

module.werewolfClawMult = 25

module.GMSTs = {
    fFatigueBase = core.getGMST("fFatigueBase"),
    fFatigueMult = core.getGMST("fFatigueMult"),
    fPickLockMult = core.getGMST("fPickLockMult"),
    fTrapCostMult = core.getGMST("fTrapCostMult"),
    fEffectCostMult = core.getGMST("fEffectCostMult"),
    fJumpEncumbranceBase = core.getGMST("fJumpEncumbranceBase"),
    fJumpEncumbranceMultiplier = core.getGMST("fJumpEncumbranceMultiplier"),
    fJumpAcrobaticsBase = core.getGMST("fJumpAcrobaticsBase"),
    fJumpAcroMultiplier = core.getGMST("fJumpAcroMultiplier"),
    fJumpRunMultiplier = core.getGMST("fJumpRunMultiplier"),
    fFallAcroBase = core.getGMST("fFallAcroBase"),
    fFallAcroMult = core.getGMST("fFallAcroMult"),
    fFallDamageDistanceMin = core.getGMST("fFallDamageDistanceMin"),
    fFallDistanceBase = core.getGMST("fFallDistanceBase"),
    fFallDistanceMult = core.getGMST("fFallDistanceMult"),
    fJumpMoveBase = core.getGMST("fJumpMoveBase"),
    fJumpMoveMult = core.getGMST("fJumpMoveMult"),
    fSwimRunAthleticsMult = core.getGMST("fSwimRunAthleticsMult"),
    fSwimRunBase = core.getGMST("fSwimRunBase"),
    fDamageStrengthBase = core.getGMST("fDamageStrengthBase"),
    fDamageStrengthMult = core.getGMST("fDamageStrengthMult"),
    fMinHandToHandMult = core.getGMST("fMinHandToHandMult"),
    fMaxHandToHandMult = core.getGMST("fMaxHandToHandMult"),
    fCombatInvisoMult = core.getGMST("fCombatInvisoMult"),
    fSwimHeightScale = core.getGMST("fSwimHeightScale"),
}

module.magickaSkills = {
    [Skills.destruction.id] = true,
    [Skills.restoration.id] = true,
    [Skills.conjuration.id] = true,
    [Skills.mysticism.id] = true,
    [Skills.illusion.id] = true,
    [Skills.alteration.id] = true,
}

module.weaponSkills = {
    [Skills.handtohand.id] = true,
    [Skills.axe.id] = true,
    [Skills.bluntweapon.id] = true,
    [Skills.longblade.id] = true,
    [Skills.marksman.id] = true,
    [Skills.shortblade.id] = true,
    [Skills.spear.id] = true,
}

module.armorSkills = {
    [Skills.unarmored.id] = true,
    [Skills.lightarmor.id] = true,
    [Skills.mediumarmor.id] = true,
    [Skills.heavyarmor.id] = true,
}

module.healthEffectIds = {
    [core.magic.EFFECT_TYPE.RestoreHealth] = true,
    [core.magic.EFFECT_TYPE.FortifyHealth] = true,
    [core.magic.EFFECT_TYPE.DrainHealth] = true,
    [core.magic.EFFECT_TYPE.DamageHealth] = true,
    [core.magic.EFFECT_TYPE.AbsorbHealth] = true,
    [core.magic.EFFECT_TYPE.FireDamage] = true,
    [core.magic.EFFECT_TYPE.FrostDamage] = true,
    [core.magic.EFFECT_TYPE.ShockDamage] = true,
    [core.magic.EFFECT_TYPE.Poison] = true,
    [core.magic.EFFECT_TYPE.SunDamage] = true,
}

module.weaponTypeToSkill = {
    [T.Weapon.TYPE.ShortBladeOneHand] = Skills.shortblade.id,
    [T.Weapon.TYPE.LongBladeOneHand] = Skills.longblade.id,
    [T.Weapon.TYPE.LongBladeTwoHand] = Skills.longblade.id,
    [T.Weapon.TYPE.BluntOneHand] = Skills.bluntweapon.id,
    [T.Weapon.TYPE.BluntTwoClose] = Skills.bluntweapon.id,
    [T.Weapon.TYPE.BluntTwoWide] = Skills.bluntweapon.id,
    [T.Weapon.TYPE.SpearTwoWide] = Skills.spear.id,
    [T.Weapon.TYPE.AxeOneHand] = Skills.axe.id,
    [T.Weapon.TYPE.AxeTwoHand] = Skills.axe.id,
    [T.Weapon.TYPE.MarksmanBow] = Skills.marksman.id,
    [T.Weapon.TYPE.MarksmanCrossbow] = Skills.marksman.id,
    [T.Weapon.TYPE.MarksmanThrown] = Skills.marksman.id,
}

module.meleeAttackGroups = {
    handtohand = true,
    weapononehand = true,
    weapontwohand = true,
    weapontwowide = true,
    attack1 = true,
    attack2 = true,
    attack3 = true,
}

module.npcAttackGroups = {
    handtohand = true,
    weapononehand = true,
    weapontwohand = true,
    weapontwowide = true,
    bowandarrow = true,
    crossbow = true,
    throwweapon = true,
}

module.meleeNpcAttackGroups = {
    handtohand = true,
    weapononehand = true,
    weapontwohand = true,
    weapontwowide = true,
}

module.meleeCreatureAttackGroups = {
    attack1 = true,
    attack2 = true,
    attack3 = true,
}

local useAttackGroups = {
    handtohand = true,
    weapononehand = true,
    weapontwohand = true,
    weapontwowide = true,
    spellcast = true,
    pickprobe = true,
}

module.meleeWeaponEndKeys = {
    ["chop hit"] = "chop",
    ["slash hit"] = "slash",
    ["thrust hit"] = "thrust",
    ["hit"] = true,
}

module.getBaseSkillMods = function()
    local baseSkillMods = {}
    for _, spell in pairs(T.Actor.activeSpells(self)) do
        if spell.affectsBaseValues then
            for _, effect in pairs(spell.effects) do
                if effect.affectedSkill and effect.id == core.magic.EFFECT_TYPE.FortifySkill then
                    baseSkillMods[effect.affectedSkill] = (baseSkillMods[effect.affectedSkill] or 0) + effect.magnitudeThisFrame
                end
            end
        end
    end
    if next(baseSkillMods) then
        local baseSkillModsKey = mH.mapToString(baseSkillMods)
        if baseSkillModsKey ~= currBaseSkillModsKey then
            currBaseSkillModsKey = baseSkillModsKey
            log(string.format("Detected new base skills modifiers: %s", baseSkillModsKey))
        end
    end
    return baseSkillMods
end

module.getMaxDamage = function(record, group, key)
    if module.npcAttackGroups[group] then
        local prefix = module.meleeWeaponEndKeys[key]
        return record[prefix .. "MaxDamage"]
    end
    if module.meleeCreatureAttackGroups[group] then
        local index = tonumber(string.sub(group, -1)) * 2
        return record.attack[index]
    end
    error(string.format("Unsupported animation group and key for max damage: (%s, %s)", group, key))
end

module.totalGameTimeInHours = function()
    return core.getGameTime() / (60 * 60)
end

module.getSkillName = function(skillId)
    return core.stats.Skill.records[skillId].name
end

module.agilityTerm = function(actor, skillId, skillValue)
    return (skillValue and skillValue or (skillId and T.NPC.stats.skills[skillId](actor).base or 0))
            + 0.2 * T.Actor.stats.attributes.agility(actor).base
            + 0.1 * T.Actor.stats.attributes.luck(actor).base
end

module.fatigueTerm = function(actor)
    local fatigue = T.Actor.stats.dynamic.fatigue(actor)
    local normalised = math.floor(fatigue.base) == 0 and 1 or math.max(0, fatigue.current / fatigue.base)
    return module.GMSTs.fFatigueBase - module.GMSTs.fFatigueMult * (1 - normalised);
end

local function setSkill(skillId, value, diff, options)
    if diff == 0 then return end
    T.NPC.stats.skills[skillId](self).base = value
    if not options or not options.quiet then
        self:sendEvent(mDef.events.showModSkill, { skillId = skillId, value = value, diff = diff })
    end
end

module.setSkill = function(skillId, value, options)
    return setSkill(skillId, value, value - T.NPC.stats.skills[skillId](self).base, options)
end

module.modSkill = function(skillId, diff, options)
    return setSkill(skillId, T.NPC.stats.skills[skillId](self).base + diff, diff, options)
end

module.modMagicka = function(amount)
    module.self.magicka.current = module.self.magicka.current + amount
end

module.hasJustSpellCasted = function()
    return lastUseAnimation and lastUseAnimation.group == "spellcast" and string.sub(lastUseAnimation.key, -7) == "release"
end

module.isLockPicking = function()
    return lastUseAnimation and lastUseAnimation.group == "pickprobe" and lastUseAnimation.key == "start"
end

I.AnimationController.addTextKeyHandler('', function(group, key)
    if useAttackGroups[group] then
        lastUseAnimation = { group = group, key = key }
    end
end)

return module