local core = require('openmw.core')
local T = require('openmw.types')

local Skills = core.stats.Skill.records

local module = {}

module.GravityAcceleration = 69.99125109 * 8.96
module.JumpVelocityFactor = 0.707
module.MaxSlopeAngle = math.rad(46.0)

module.GMSTs = {
    fFatigueBase = core.getGMST("fFatigueBase"),
    fFatigueMult = core.getGMST("fFatigueMult"),
    fPickLockMult = core.getGMST("fPickLockMult"),
    fTrapCostMult = core.getGMST("fTrapCostMult"),
    fAutoPCSpellChance = core.getGMST("fAutoPCSpellChance"),
    fEffectCostMult = core.getGMST("fEffectCostMult"),
    iAutoSpellAttSkillMin = core.getGMST("iAutoSpellAttSkillMin"),
    iAutoPCSpellMax = core.getGMST("iAutoPCSpellMax"),
    fPCbaseMagickaMult = core.getGMST("fPCbaseMagickaMult"),
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

module.useAttackGroups = {
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

module.isStarwindMode = function()
    return core.contentFiles.has('Starwind.omwaddon') or core.contentFiles.has('StarwindRemasteredPatch.esm')
end

module.totalGameTimeInHours = function()
    return core.getGameTime() / (60 * 60)
end

module.getStatName = function(kind, statId)
    if kind == "attributes" then
        return core.stats.Attribute.records[statId].name
    else
        return core.stats.Skill.records[statId].name
    end
end

module.getMaxHealthModifier = function(actor)
    local healthMod = 0
    for _, spell in pairs(T.Actor.activeSpells(actor)) do
        if spell.affectsBaseValues then
            for _, effect in pairs(spell.effects) do
                if effect.id == core.magic.EFFECT_TYPE.FortifyHealth then
                    healthMod = healthMod + effect.magnitudeThisFrame
                end
            end
        end
    end
    return healthMod
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

return module