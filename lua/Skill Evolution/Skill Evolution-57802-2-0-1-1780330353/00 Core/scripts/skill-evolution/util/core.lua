local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')
local I = require('openmw.interfaces')

local mDef = require('scripts.skill-evolution.config.definition')
local mHelpers = require('scripts.skill-evolution.util.helpers')
local log = require('scripts.skill-evolution.util.log')

local skillStatsCaches = {}
local skillRecordCache
local currBaseSkillModsKey
local lastUseAnimation

local module = {
    GravityAcceleration = 69.99125109 * 8.96,
    unitsPerFoot = 21.33333333,
    JumpVelocityFactor = 0.707,
    MaxSlopeAngle = math.rad(46.0),
}

module.self = {
    level = T.Actor.stats.level(self),
    health = T.Actor.stats.dynamic.health(self),
    fatigue = T.Actor.stats.dynamic.fatigue(self),
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
    fHandtoHandHealthPer = core.getGMST("fHandtoHandHealthPer"),
    fCombatInvisoMult = core.getGMST("fCombatInvisoMult"),
    fSwimHeightScale = core.getGMST("fSwimHeightScale"),
    iLevelupTotal = core.getGMST("iLevelupTotal"),
    iLevelupMajorMult = core.getGMST("iLevelupMajorMult"),
    iLevelupMinorMult = core.getGMST("iLevelupMinorMult"),
    iLevelupMajorMultAttribute = core.getGMST("iLevelupMajorMultAttribute"),
    iLevelupMinorMultAttribute = core.getGMST("iLevelupMinorMultAttribute"),
    iLevelupMiscMultAttriubte = core.getGMST("iLevelupMiscMultAttriubte"),
    iAlchemyMod = core.getGMST("iAlchemyMod"),
    fMiscSkillBonus = core.getGMST("fMiscSkillBonus"),
    fMajorSkillBonus = core.getGMST("fMajorSkillBonus"),
    fMinorSkillBonus = core.getGMST("fMinorSkillBonus"),
    fSpecialSkillBonus = core.getGMST("fSpecialSkillBonus"),
}

module.magickaSkills = {
    destruction = true,
    restoration = true,
    conjuration = true,
    mysticism = true,
    illusion = true,
    alteration = true,
}

module.weaponSkills = {
    handtohand = true,
    axe = true,
    bluntweapon = true,
    longblade = true,
    marksman = true,
    shortblade = true,
    spear = true,
}

module.armorSkills = {
    unarmored = true,
    lightarmor = true,
    mediumarmor = true,
    heavyarmor = true,
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
    [T.Weapon.TYPE.ShortBladeOneHand] = "shortblade",
    [T.Weapon.TYPE.LongBladeOneHand] = "longblade",
    [T.Weapon.TYPE.LongBladeTwoHand] = "longblade",
    [T.Weapon.TYPE.BluntOneHand] = "bluntweapon",
    [T.Weapon.TYPE.BluntTwoClose] = "bluntweapon",
    [T.Weapon.TYPE.BluntTwoWide] = "bluntweapon",
    [T.Weapon.TYPE.SpearTwoWide] = "spear",
    [T.Weapon.TYPE.AxeOneHand] = "axe",
    [T.Weapon.TYPE.AxeTwoHand] = "axe",
    [T.Weapon.TYPE.MarksmanBow] = "marksman",
    [T.Weapon.TYPE.MarksmanCrossbow] = "marksman",
    [T.Weapon.TYPE.MarksmanThrown] = "marksman",
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

module.objectId = function(object)
    if object == nil then
        return "<nil object>"
    elseif not object or not object.id or not object.recordId then
        return "<invalid object>"
    else
        return string.format("<%s, %s>", object.id, object.recordId)
    end
end

module.setClass = function(state)
    local playerClass = T.NPC.classes.record(T.NPC.record(self).class)
    state.specialization = playerClass.specialization
    state.skills.major = {}
    for _, skillId in ipairs(playerClass.majorSkills) do
        state.skills.major[skillId] = true
    end
    state.skills.minor = {}
    for _, skillId in ipairs(playerClass.minorSkills) do
        state.skills.minor[skillId] = true
    end
    state.skills.misc = {}
    for _, skill in ipairs(core.stats.Skill.records) do
        if not state.skills.major[skill.id] and not state.skills.minor[skill.id] then
            state.skills.misc[skill.id] = true
        end
    end
    if I.SkillFramework then
        for skillId in pairs(I.SkillFramework.getSkillRecords()) do
            state.skills.misc[skillId] = true
        end
    end
end

module.getSkillProgressRequirement = function(state, skillId, skill)
    local factor = module.GMSTs.fMiscSkillBonus
    if state.skills.major[skillId] then
        factor = module.GMSTs.fMajorSkillBonus
    elseif state.skills.minor[skillId] then
        factor = module.GMSTs.fMinorSkillBonus
    end
    if module.getSkillRecord(skillId).specialization == state.specialization then
        factor = factor * module.GMSTs.fSpecialSkillBonus
    end
    return (skill.base + 1) * factor
end

module.getSkillRecord = function(skillId)
    return module.getSkillRecords()[skillId]
end

module.getSkillRecords = function()
    if skillRecordCache then
        return skillRecordCache
    end
    skillRecordCache = {}
    for i = 1, #core.stats.Skill.records do
        local skill = core.stats.Skill.records[i]
        skillRecordCache[i] = skill
        skillRecordCache[skill.id] = skill
    end
    if I.SkillFramework then
        for skillId, props in pairs(I.SkillFramework.getSkillRecords()) do
            local newProps = {}
            for key, value in pairs(props) do
                newProps[key] = value
            end
            newProps.id = skillId
            newProps.isCustom = true
            skillRecordCache[#skillRecordCache + 1] = newProps
            skillRecordCache[skillId] = newProps
        end
    end
    return skillRecordCache
end

module.clearSkillRecordCache = function()
    skillRecordCache = nil
end

module.getSkillStat = function(skillId, actor)
    return module.getSkillStats(actor or self)[skillId]
end

module.getSkillStats = function(actor)
    actor = actor or self
    if skillStatsCaches[actor] then
        return skillStatsCaches[actor]
    end
    local skills = {}
    for skillId, getter in pairs(T.NPC.stats.skills) do
        skills[skillId] = getter(actor)
    end
    if I.SkillFramework and actor.type == T.Player then
        for skillId in pairs(I.SkillFramework.getSkillRecords()) do
            skills[skillId] = I.SkillFramework.getSkillStat(skillId)
        end
    end
    skillStatsCaches[actor] = skills
    return skills
end

module.clearSkillStatCaches = function()
    skillStatsCaches = {}
end

module.getSkillUpStats = function(skillId)
    local playerClass = T.NPC.classes.record(T.NPC.record(self).class)
    for i = 1, #playerClass.majorSkills do
        if playerClass.majorSkills[i] == skillId then
            return module.GMSTs.iLevelupMajorMult, module.GMSTs.iLevelupMajorMultAttribute
        end
    end
    for i = 1, #playerClass.minorSkills do
        if playerClass.minorSkills[i] == skillId then
            return module.GMSTs.iLevelupMinorMult, module.GMSTs.iLevelupMinorMultAttribute
        end
    end
    return 0, module.GMSTs.iLevelupMiscMultAttriubte
end

module.copyHandlerParams = function(params)
    return { skillGain = params.skillGain, scale = params.scale, useType = params.useType, baseSkillMods = params.baseSkillMods }
end

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
        local baseSkillModsKey = mHelpers.mapToString(baseSkillMods)
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

module.agilityTerm = function(actor, skillId, skillValue)
    return (skillValue and skillValue or (skillId and module.getSkillStat(skillId, actor).base or 0))
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
    module.getSkillStat(skillId).base = value
    if not options or not options.quiet then
        self:sendEvent(mDef.events.showModSkill, { skillId = skillId, value = value, diff = diff, options = options })
    end
end

module.modSkill = function(skillId, diff, options)
    return setSkill(skillId, module.getSkillStat(skillId).base + diff, diff, options)
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

module.getPlayerGold = function()
    return self.type.inventory(self):find("gold_001")
end

local function getEffectKey(e)
    return string.format("%s_%s_%s_%s_%s_%s_%s_%s",
            e.affectedAttribute, e.affectedSkill, e.area, e.duration, e.id, e.magnitudeMax, e.magnitudeMin, e.range)
end

local function isSamePotion(record1, record2)
    if record1.name ~= record2.name
            or record1.value ~= record2.value
            or not mHelpers.areFloatEqual(record1.weight, record2.weight)
            or record1.mwscript ~= record2.mwscript
            or #record1.effects ~= #record2.effects then
        return false
    end
    local keys1 = {}
    for i = 1, #record1.effects do
        keys1[getEffectKey(record1.effects[i])] = true
    end
    for i = 1, #record2.effects do
        if not keys1[getEffectKey(record2.effects[i])] then
            return false
        end
    end
    return true
end

module.findSamePotion = function(record1)
    local potions = module.self.inventory:getAll(T.Potion)
    for i = 1, #potions do
        local potion = potions[i]
        if isSamePotion(record1, potion.type.record(potion)) then
            return potion
        end
    end
end

I.AnimationController.addTextKeyHandler('', function(group, key)
    if useAttackGroups[group] then
        lastUseAnimation = { group = group, key = key }
    end
end)

return module