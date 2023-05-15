---@class DPS
---@field config Config
---@field fFatigueBase number
---@field fFatigueMult number
---@field fCombatInvisoMult number
---@field fSwingBlockBase number
---@field fSwingBlockMult number
---@field fBlockStillBonus number
---@field iBlockMinChance number
---@field iBlockMaxChance number
---@field fCombatArmorMinMult number
---@field fDifficultyMult number
---@field fDamageStrengthBase number
---@field fDamageStrengthMult number
---@field restoreDrainAttributesFix boolean
---@field blindFix integer
---@field rangedWeaponCanCastOnSTrike boolean
---@field throwWeaponAlreadyModified boolean
---@field poisonCrafting PoisonCrafting
local DPS = {}

---@param cfg Config?
---@return DPS
function DPS.new(cfg)
    local dps = {
        config = cfg and cfg or require("longod.DPSTooltips.config").Load()
    }
    setmetatable(dps, { __index = DPS })
    return dps
end

local logger = require("longod.DPSTooltips.logger")
local combat = require("longod.DPSTooltips.combat")
local resolver = require("longod.DPSTooltips.effect")

---@class Icons
---@field [tes3.effect] {[integer]: string[]} or [tes3.effect] string[]

---@param data ScratchData
---@param icons Icons
---@param effects tes3effect[]
---@param weaponSpeed number
---@param weaponSkillId tes3.skill
---@param forceTargetEffects boolean
---@return ScratchData
---@return Icons
local function CollectEffects(data, icons, effects, weaponSpeed, weaponSkillId, forceTargetEffects)
    for _, effect in ipairs(effects) do
        if effect ~= nil and effect.id >= 0 then
            local id = effect.id
            local r = resolver.Get(id)
            if r then
                local value = (effect.max + effect.min) * 0.5 -- uniform RNG average
                local isSelf = effect.rangeType == tes3.effectRange.self
                if forceTargetEffects then
                    isSelf = false
                end
                ---@type Params
                local params = {
                    data = data,
                    key = id,
                    value = value,
                    speed = weaponSpeed,
                    isSelf = isSelf,
                    attacker = r.attacker,
                    target = r.target,
                    attribute = effect.attribute, -- if invalid it returns -1. not nil.
                    skill = effect.skill,         -- if invalid it returns -1. not nil.
                    weaponSkillId = weaponSkillId,
                    actived = false
                }
                local affect = r.func(params)
                if affect and id ~= nil then
                    -- adding own key, then merge on resolve phase
                    if not icons[id] then
                        icons[id] = {}
                    end
                    if effect.attribute ~= nil and effect.attribute >= 0 then
                        if not icons[id][effect.attribute] then
                            icons[id][effect.attribute] = {}
                        end
                        table.insert(icons[id][effect.attribute], effect.object.icon)
                    elseif effect.skill ~= nil and effect.skill >= 0 then
                        if not icons[id][effect.skill] then
                            icons[id][effect.skill] = {}
                        end
                        table.insert(icons[id][effect.skill], effect.object.icon)
                    else
                        table.insert(icons[id], effect.object.icon)
                    end
                end
            end
        end
    end
    return data, icons
end

---@param data ScratchData
---@param icons Icons
---@param enchantment tes3enchantment
---@param weaponSpeed number
---@param canCastOnStrike boolean
---@param weaponSkillId tes3.skill
---@return ScratchData
---@return Icons
local function CollectEnchantmentEffect(data, icons, enchantment, weaponSpeed, canCastOnStrike, weaponSkillId)
    if enchantment then
        -- better is on strike effect consider charge cost
        local onStrike = canCastOnStrike and enchantment.castType == tes3.enchantmentType.onStrike
        local constant = enchantment.castType == tes3.enchantmentType.constant
        if onStrike or constant then
            CollectEffects(data, icons, enchantment.effects, weaponSpeed, weaponSkillId, false)
        end
    end

    return data, icons
end

-- avoid double applied
---@param data ScratchData
---@param activeMagicEffectList tes3activeMagicEffect[]
---@param weapon tes3weapon
---@param canCastOnStrike boolean
---@return ScratchData
local function CollectActiveMagicEffect(data, activeMagicEffectList, weapon, canCastOnStrike)
    if weapon.enchantment and activeMagicEffectList then
        local onStrike = canCastOnStrike and weapon.enchantment.castType == tes3.enchantmentType.onStrike
        local constant = weapon.enchantment.castType == tes3.enchantmentType.constant
        if onStrike or constant then -- no on use
            for _, a in ipairs(activeMagicEffectList) do
                if a.instance.sourceType == tes3.magicSourceType.enchantment and
                    a.instance.item and a.instance.item.objectType == tes3.objectType.weapon then
                    -- only tooltip weapon, possible enemy attacked using same weapon?
                    if a.instance.item.id == weapon.id and a.instance.magicID == weapon.enchantment.id and a.effectId >= 0 then
                        -- logger:debug(weapon.id .. " " .. weapon.enchantment.id)
                        local id = a.effectId
                        local r = resolver.Get(id)
                        if r then
                            ---@type Params
                            local params = {
                                data = data,
                                key = id,
                                value = -a.effectInstance.effectiveMagnitude, -- counter resisted value
                                speed = 1.0,
                                isSelf = true,
                                attacker = r.attacker,
                                target = r.target,
                                attribute = a.attributeId,
                                skill = a.skillId,
                                weaponSkillId = weapon.skillId,
                                actived = true
                            }
                            r.func(params)
                        end
                    end
                end
            end
        end
    end
    return data
end

-- from Accurate Tooltip Stats (https://www.nexusmods.com/morrowind/mods/51354) by Necrolesian
---@param weapon tes3weapon
---@param itemData tes3itemData
---@return number
local function GetConditionModifier(weapon, itemData)
    -- Projectiles (thrown weapons, arrows, bolts) have no condition data.
    local hasDurability = weapon.hasDurability
    local maximumCondition = (hasDurability and weapon.maxCondition) or 1.0
    local currentCondition = (hasDurability and itemData and itemData.condition) or maximumCondition
    return currentCondition / maximumCondition
end

-- from Accurate Tooltip Stats (https://www.nexusmods.com/morrowind/mods/51354) by Necrolesian
---@param strength number
---@param fDamageStrengthBase number
---@param fDamageStrengthMult number
---@return number
local function GetStrengthModifier(strength, fDamageStrengthBase, fDamageStrengthMult)
    -- how capped value without mcp patch?
    local currentStrength = math.max(strength, 0)
    -- resolved base and mult on initialize
    return fDamageStrengthBase + (fDamageStrengthMult * currentStrength)
end

---@class DamageRange
---@field min number
---@field max number

-- from Accurate Tooltip Stats (https://www.nexusmods.com/morrowind/mods/51354) by Necrolesian
---@param weapon tes3weapon
---@param marksman boolean
---@param useBestAttack boolean
---@param needModifyThrowWeapon boolean
---@return { [tes3.physicalAttackType]: DamageRange }
local function GetWeaponBaseDamage(weapon, marksman, useBestAttack, needModifyThrowWeapon)
    local baseDamage = {} ---@type { [tes3.physicalAttackType]: DamageRange }
    if marksman then
        baseDamage[tes3.physicalAttackType.projectile] = { min = weapon.chopMin, max = weapon.chopMax }

        -- The vanilla game doubles the official damage values for thrown weapons. The mod Thrown Projectiles Revamped
        -- halves the actual damage done, so don't double the displayed damage if that mod is in use.
        if needModifyThrowWeapon then
            baseDamage[tes3.physicalAttackType.projectile].min = 2 * baseDamage[tes3.physicalAttackType.projectile].min
            baseDamage[tes3.physicalAttackType.projectile].max = 2 * baseDamage[tes3.physicalAttackType.projectile].max
        end
    else
        if useBestAttack then
            -- pick highest average damage
            local slash = weapon.slashMin + weapon.slashMax
            local thrust = weapon.thrustMin + weapon.thrustMax
            local chop = weapon.chopMin + weapon.chopMax
            -- order is slash, thrust then chop
            if slash >= thrust and slash >= chop then
                baseDamage[tes3.physicalAttackType.slash] = { min = weapon.slashMin, max = weapon.slashMax }
            elseif thrust >= slash and thrust >= chop then
                baseDamage[tes3.physicalAttackType.thrust] = { min = weapon.thrustMin, max = weapon.thrustMax }
            else
                baseDamage[tes3.physicalAttackType.chop] = { min = weapon.chopMin, max = weapon.chopMax }
            end
        else
            baseDamage[tes3.physicalAttackType.slash] = { min = weapon.slashMin, max = weapon.slashMax }
            baseDamage[tes3.physicalAttackType.thrust] = { min = weapon.thrustMin, max = weapon.thrustMax }
            baseDamage[tes3.physicalAttackType.chop] = { min = weapon.chopMin, max = weapon.chopMax }
        end
    end

    return baseDamage
end

---@param weaponDamages { [tes3.physicalAttackType]: DamageRange }
---@param minmaxRange boolean
---@return DamageRange
---@return { [tes3.physicalAttackType] :boolean }
local function ResolveWeaponDPS(weaponDamages, minmaxRange)
    local damageRange = { min = 0, max = 0 } ---@type DamageRange
    local highestType = {}
    local typeDamages = {}
    local highest = 0
    for k, v in pairs(weaponDamages) do
        damageRange.min = math.max(damageRange.min, v.min)
        damageRange.max = math.max(damageRange.max, v.max)
        local typeDamage = v.max
        if minmaxRange then
            typeDamage = (v.max + v.min) -- average
        end
        highest = math.max(highest, typeDamage)
        typeDamages[k] = typeDamage
    end
    for k, v in pairs(typeDamages) do
        if combat.NearyEqual(highest, v) then
            highestType[k] = true
        end
    end
    return damageRange, highestType
end

---@param icons Icons
---@param dest tes3.effect|tes3.physicalAttackType
---@param src tes3.effect
---@param attribute tes3.attribute?
---@param skill tes3.skill?
local function MergeIcons(icons, dest, src, attribute, skill)
    if dest ~= src and icons[src] then
        if not icons[dest] then
            icons[dest] = {}
        end
        if attribute then
            if icons[src][attribute] then
                for _, path in ipairs(icons[src][attribute]) do
                    table.insert(icons[dest], path)
                end
            end
        elseif skill then
            if icons[src][skill] then
                for _, path in ipairs(icons[src][skill]) do
                    table.insert(icons[dest], path)
                end
            end
        else
            for _, path in ipairs(icons[src]) do
                table.insert(icons[dest], path)
            end
        end
    end
end

---@param effect ScratchData
---@param difficultyMultiply number
---@return number
---@return {[tes3.effect]: number}
local function ResolveEffectDPS(effect, difficultyMultiply)
    local effectDamages = {}
    local effectTotal = 0

    -- damage
    for k, v in pairs(effect.target.damages) do
        local damage = v
        damage = damage * difficultyMultiply
        effectDamages[k] = damage
        effectTotal = effectTotal + damage
    end

    -- healing
    local healing = {
        tes3.effect.restoreHealth,
        tes3.effect.fortifyHealth,
    }
    for _, v in ipairs(healing) do
        local h = resolver.GetValue(effect.target.positives, v, 0)
        effectDamages[v] = -h -- display value is negative
        effectTotal = effectTotal - h
    end

    return effectTotal, effectDamages
end

---@param effect ScratchData
---@param icons Icons
---@param resistMagicka number
local function ResolveModifiers(effect, icons, resistMagicka)
    -- resist/weakness magicka
    local rm = tes3.effect.resistMagicka
    local wm = tes3.effect.weaknesstoMagicka
    -- Once Resist Magicka reaches 100%, it's the only type of resistance that can't be broken by a Weakness effect, since Weakness is itself a magicka type spell.
    -- so if both apply, above works?
    local targetResistMagicka = combat.InverseNormalize(resolver.GetValue(effect.target.positives, rm, 0))
    targetResistMagicka = combat.InverseNormalize(resolver.GetValue(effect.target.negatives, wm, 0)) *
        targetResistMagicka
    local attackerResistMagicka = combat.InverseNormalize(resolver.GetValue(effect.attacker.positives, rm, 0) +
        resistMagicka)
    attackerResistMagicka = combat.InverseNormalize(resolver.GetValue(effect.attacker.negatives, wm, 0)) *
        attackerResistMagicka
    effect.target.resists[rm] = targetResistMagicka
    effect.attacker.resists[rm] = attackerResistMagicka
    -- apply resist magicka to negative effects
    -- TODO perhaps resist magicka does not just multiply. more complex. willpower, luck and fatigue, fully resist is treat as probability
    for k, v in pairs(effect.target.negatives) do
        if k ~= tes3.effect.weaknesstoMagicka then
            effect.target.negatives[k] = v * targetResistMagicka
        end
    end
    for k, v in pairs(effect.attacker.negatives) do
        if k ~= tes3.effect.weaknesstoMagicka then
            effect.attacker.negatives[k] = v * attackerResistMagicka
        end
    end

    -- probability reflect, spellAbsorption, dispel..
    -- but it seems not apply the same item effects. if effects already applied, it can be dispeled.

    -- merge resist/weakness elemental and shield
    local resistweakness = {
        [tes3.effect.resistFire]          = { tes3.effect.weaknesstoFire, tes3.effect.fireShield },
        [tes3.effect.resistFrost]         = { tes3.effect.weaknesstoFrost, tes3.effect.frostShield },
        [tes3.effect.resistShock]         = { tes3.effect.weaknesstoShock, tes3.effect.lightningShield },
        -- [tes3.effect.resistMagicka]       = {tes3.effect.weaknesstoMagicka}, -- pre calculated
        [tes3.effect.resistPoison]        = { tes3.effect.weaknesstoPoison },
        [tes3.effect.resistNormalWeapons] = { tes3.effect.weaknesstoNormalWeapons },
    }
    for k, v in pairs(resistweakness) do
        local resist = resolver.GetValue(effect.target.positives, k, 0)
        if v[2] then -- shield
            resist = resist + resolver.GetValue(effect.target.positives, v[2], 0)
            MergeIcons(icons, k, v[2])
        end
        resist = resist - resolver.GetValue(effect.target.negatives, v[1], 0)
        effect.target.resists[k] = combat.InverseNormalize(resist)

        MergeIcons(icons, k, v[1])
    end

    -- negative attrib, skill
    ---@param modifiers AttributeModifier|SkillModifier
    ---@param mod number
    local function ApplyResistMagicka(modifiers, mod)
        for k, v in pairs(modifiers.damage) do
            modifiers.damage[k] = v * mod
        end
        for k, v in pairs(modifiers.drain) do
            modifiers.drain[k] = v * mod
        end
        for k, v in pairs(modifiers.absorb) do
            modifiers.absorb[k] = v * mod
        end
    end
    ApplyResistMagicka(effect.target.attributes, targetResistMagicka)
    ApplyResistMagicka(effect.target.skills, targetResistMagicka)
    ApplyResistMagicka(effect.attacker.attributes, attackerResistMagicka)
    ApplyResistMagicka(effect.attacker.skills, attackerResistMagicka)
    -- absorb values from target to attacker
    for k, v in pairs(effect.target.attributes.absorb) do
        effect.attacker.attributes.absorb[k] = -v -- invert for GetModified
    end
    for k, v in pairs(effect.target.skills.absorb) do
        effect.attacker.skills.absorb[k] = -v -- invert for GetModified
    end

    -- damage
    local e = effect.target
    local pair = {
        [tes3.effect.fireDamage] = tes3.effect.resistFire,
        [tes3.effect.frostDamage] = tes3.effect.resistFrost,
        [tes3.effect.shockDamage] = tes3.effect.resistShock,
        [tes3.effect.poison] = tes3.effect.resistPoison,
        [tes3.effect.absorbHealth] = tes3.effect.resistMagicka,
        [tes3.effect.damageHealth] = tes3.effect.resistMagicka,
        [tes3.effect.drainHealth] = tes3.effect.resistMagicka, -- temporary down
        [tes3.effect.sunDamage] = nil,                         -- only vampire
    }

    for k, v in pairs(pair) do
        if v then
            local damage = resolver.GetValue(e.damages, k, 0) * resolver.GetValue(e.resists, v, 1.0)
            e.damages[k] = damage
            MergeIcons(icons, k, v)
        end
    end

    -- cure poison
    if resolver.GetValue(e.positives, tes3.effect.curePoison, 0) > 0 and e.damages[tes3.effect.poison] then
        e.damages[tes3.effect.poison] = 0
        MergeIcons(icons, tes3.effect.poison, tes3.effect.curePoison)
    end
end

---@param e Modifier
---@param t tes3.attribute
---@param attributes tes3statistic[]?
---@param restoreDrainAttributesFix boolean
---@return number
local function GetModifiedAttribute(e, t, attributes, restoreDrainAttributesFix)
    local current = 0
    local base = 0
    if attributes then
        current = current + attributes[t + 1].current
        base = attributes[t + 1].base
    end

    -- avoid double applied
    if e.actived then
        current = current + GetModifiedAttribute(e.actived, t, nil, restoreDrainAttributesFix)
    end

    if e.attributes.damage[t] then
        current = current - e.attributes.damage[t]
    end

    if restoreDrainAttributesFix then
        if e.attributes.restore[t] then -- can restore drained value?
            local decreased = math.max(base - current, 0)
            current = current + math.min(e.attributes.restore[t], decreased)
        end
        if e.attributes.fortify[t] then
            current = current + e.attributes.fortify[t]
        end
    else
        if e.attributes.fortify[t] then
            current = current + e.attributes.fortify[t]
        end
        if e.attributes.restore[t] then -- can restore drained value?
            local decreased = math.max(base - current, 0)
            current = current + math.min(e.attributes.restore[t], decreased)
        end
    end

    if e.attributes.drain[t] then
        current = current - e.attributes.drain[t] -- at once
    end
    if e.attributes.absorb[t] then
        current = current - e.attributes.absorb[t] -- attacker's sign must be negative
    end
    return current
end

---@param e Modifier
---@param t tes3.skill
---@param skills tes3statisticSkill[]?
---@param restoreDrainAttributesFix boolean
---@return number
local function GetModifiedSkill(e, t, skills, restoreDrainAttributesFix)
    local current = 0
    local base = 0
    if skills then
        current = current + skills[t + 1].current
        base = skills[t + 1].base
    end

    -- avoid double applied
    if e.actived then
        current = current + GetModifiedSkill(e.actived, t, nil, restoreDrainAttributesFix)
    end

    if e.skills.damage[t] then
        current = current - e.skills.damage[t]
    end

    if restoreDrainAttributesFix then
        if e.skills.restore[t] then -- can restore drained value?
            local decreased = math.max(base - current, 0)
            current = current + math.min(e.skills.restore[t], 0)
        end
        if e.skills.fortify[t] then
            current = current + e.skills.fortify[t]
        end
    else
        if e.skills.fortify[t] then
            current = current + e.skills.fortify[t]
        end
        if e.skills.restore[t] then -- can restore drained value?
            local decreased = math.max(base - current, 0)
            current = current + math.min(e.skills.restore[t], 0)
        end
    end

    if e.skills.drain[t] then
        current = current - e.skills.drain[t] -- at once
    end
    if e.skills.absorb[t] then
        current = current - e.skills.absorb[t] -- attacker's sign must be negative
    end
    return current
end

---@param e Modifier
---@param t tes3.effectAttribute
---@param effects number[]?
---@return number
local function GetModifiedEffects(e, t, effects)
    local current = 0
    if effects then
        current = current + effects[t + 1]
    end

    -- avoid double applied
    if e.actived then
        current = current + GetModifiedEffects(e.actived, t, nil)
    end

    -- map tes3.effectAttribute to tes3.effect
    local map = {
        [tes3.effectAttribute.attackBonus] = tes3.effect.fortifyAttack,
        [tes3.effectAttribute.sanctuary] = tes3.effect.sanctuary,
        [tes3.effectAttribute.resistMagicka] = tes3.effect.resistMagicka,
        [tes3.effectAttribute.resistFire] = tes3.effect.resistFire,     -- and fire shield, weakness in .resists
        [tes3.effectAttribute.resistFrost] = tes3.effect.resistFrost,   -- and frost shield, weakness in .resists
        [tes3.effectAttribute.resistShock] = tes3.effect.resistShock,   -- and lighting shield, weakness in .resists
        [tes3.effectAttribute.resistPoison] = tes3.effect.resistPoison, -- and weakness in .resists
        [tes3.effectAttribute.resistParalysis] = tes3.effect.resistParalysis,
        [tes3.effectAttribute.chameleon] = tes3.effect.chameleon,
        [tes3.effectAttribute.resistNormalWeapons] = tes3.effect.resistNormalWeapons,
        [tes3.effectAttribute.shield] = tes3.effect.shield,
        [tes3.effectAttribute.blind] = tes3.effect.blind,
        [tes3.effectAttribute.paralyze] = tes3.effect.paralyze,
        [tes3.effectAttribute.invisibility] = tes3.effect.invisibility,
    }

    local id = map[t];
    if id then
        if e.resists and e.resists[id] then -- prior
            -- including resist, shield, weakness (effective)
            current = current + resolver.GetValue(e.resists, id, 0);
        else
            current = current + resolver.GetValue(e.positives, id, 0);
            current = current - resolver.GetValue(e.negatives, id, 0);
        end
    end
    return current
end

-- local function GetModifiedCurrentFatigue(e, t, fatigue)
-- end
-- local function GetModifiedMaxFatigue(e, t, fatigue)
-- end

---@param effect ScratchData
local function GetTargetArmorRating(effect)
    -- currently only shield effect
    local shield = GetModifiedEffects(effect.target, tes3.effectAttribute.shield, nil)
    return shield
end

---@param self DPS
function DPS.Initialize(self)
    -- move gmst values to combat?
    self.fFatigueBase = tes3.findGMST(tes3.gmst.fFatigueBase).value ---@diagnostic disable-line: assign-type-mismatch
    self.fFatigueMult = tes3.findGMST(tes3.gmst.fFatigueMult).value ---@diagnostic disable-line: assign-type-mismatch
    self.fCombatInvisoMult = tes3.findGMST(tes3.gmst.fCombatInvisoMult).value ---@diagnostic disable-line: assign-type-mismatch
    self.fSwingBlockBase = tes3.findGMST(tes3.gmst.fSwingBlockBase).value ---@diagnostic disable-line: assign-type-mismatch
    self.fSwingBlockMult = tes3.findGMST(tes3.gmst.fSwingBlockMult).value ---@diagnostic disable-line: assign-type-mismatch
    self.fBlockStillBonus = 1.25 -- tes3.findGMST(tes3.gmst.fBlockStillBonus).value -- hardcoded, OpenMW uses gmst
    self.iBlockMinChance = tes3.findGMST(tes3.gmst.iBlockMinChance).value ---@diagnostic disable-line: assign-type-mismatch
    self.iBlockMaxChance = tes3.findGMST(tes3.gmst.iBlockMaxChance).value ---@diagnostic disable-line: assign-type-mismatch
    self.fCombatArmorMinMult = tes3.findGMST(tes3.gmst.fCombatArmorMinMult).value ---@diagnostic disable-line: assign-type-mismatch
    self.fDifficultyMult = tes3.findGMST(tes3.gmst.fDifficultyMult).value ---@diagnostic disable-line: assign-type-mismatch

    -- resolve MCP or mod
    self.fDamageStrengthBase = 0.5
    self.fDamageStrengthMult = 0.01
    -- This MCP feature causes the game to use these GMSTs in its weapon damage calculations instead of the hardcoded
    -- values used by the vanilla game. With default values for the GMSTs the outcome is the same.
    if tes3.hasCodePatchFeature(tes3.codePatchFeature.gameFormulaRestoration) then
        -- maybe require restart when to get initialing
        logger:info("Enabled MCP GameFormulaRestoration")
        self.fDamageStrengthBase = tes3.findGMST(tes3.gmst.fDamageStrengthBase).value ---@diagnostic disable-line: assign-type-mismatch
        self.fDamageStrengthMult = 0.1 * tes3.findGMST(tes3.gmst.fDamageStrengthMult).value ---@diagnostic disable-line: assign-type-mismatch
    end

    self.restoreDrainAttributesFix = false
    if tes3.hasCodePatchFeature(tes3.codePatchFeature.restoreDrainAttributesFix) then
        logger:info("Enabled MCP RestoreDrainAttributesFix")
        self.restoreDrainAttributesFix = true
    end

    -- sign
    self.blindFix = -1
    if tes3.hasCodePatchFeature(tes3.codePatchFeature.blindFix) then
        logger:info("Enabled MCP BlindFix")
        self.blindFix = 1
    end

    -- https://www.nexusmods.com/morrowind/mods/45913
    self.rangedWeaponCanCastOnSTrike = false
    if tes3.isModActive("Cast on Strike Bows.esp") then
        -- this MCP fix seems, deny on strile option when enchaning, exsisting ranged weapons on strike dont require this fix to torigger.
        -- ~tes3.hasCodePatchFeature(tes3.codePatchFeature.fixEnchantOptionsOnRanged)
        logger:info("Enabled Cast on Strike Bows")
        self.rangedWeaponCanCastOnSTrike = true
    end

    -- https://www.nexusmods.com/morrowind/mods/49609
    -- The vanilla game doubles the official damage values for thrown weapons. The mod Thrown Projectiles Revamped
    -- halves the actual damage done, so don't double the displayed damage if that mod is in use.
    self.throwWeaponAlreadyModified = false
    if tes3.isLuaModActive("DQ.ThroProjRev") then
        logger:info("Enabled Thrown Projectiles Revamped")
        self.throwWeaponAlreadyModified = true
    end

    self.poisonCrafting = nil
    if tes3.isLuaModActive("poisonCrafting") then
        logger:info("Enabled Poison Crafting")
        self.poisonCrafting = require("longod.DPSTooltips.poison")
    end
end

---@param self DPS
---@param weapon tes3weapon
---@return boolean
function DPS.CanCastOnStrike(self, weapon)
    return self.rangedWeaponCanCastOnSTrike or weapon.isMelee or weapon.isProjectile
end

---@param self DPS
---@param weapon tes3weapon
---@return boolean
function DPS.NeedModifyThrowWeapon(self, weapon)
    return weapon.type == tes3.weaponType.marksmanThrown and not self.throwWeaponAlreadyModified
end

---@param self DPS
---@param currentFatigue number
---@param baseFatigue number
---@return number
function DPS.GetFatigueTerm(self, currentFatigue, baseFatigue)
    return combat.CalculateFatigueTerm(currentFatigue, baseFatigue, self.fFatigueBase, self.fFatigueMult)
end

---@param self DPS
---@param weapon tes3weapon
---@param itemData tes3itemData
---@param speed number
---@param strength number
---@param armorRating number
---@param difficultyMultiply number
---@param marksman boolean
---@param useBestAttack boolean
---@return { [tes3.physicalAttackType]: DamageRange }
function DPS.CalculateWeaponDamage(self, weapon, itemData, speed, strength, armorRating, difficultyMultiply, marksman, useBestAttack)
    local baseDamage = GetWeaponBaseDamage(weapon, marksman, useBestAttack, self:NeedModifyThrowWeapon(weapon))
    local damageMultStr = 0
    local damageMultCond = 1.0
    if self.config.accurateDamage then
        damageMultStr = GetStrengthModifier(strength, self.fDamageStrengthBase, self.fDamageStrengthMult)
        if not self.config.maxDurability then
            damageMultCond = GetConditionModifier(weapon, itemData)
        end
    end
    local minSpeed = speed -- TODO maybe more quickly, it seems depends animation frame
    local maxSpeed = speed -- same as animation frame?
    for _, v in pairs(baseDamage) do
        if self.config.accurateDamage then
            v.min = combat.CalculateAcculateWeaponDamage(v.min, damageMultStr, damageMultCond, 1);
            v.max = combat.CalculateAcculateWeaponDamage(v.max, damageMultStr, damageMultCond, 1);

            v.min = v.min * difficultyMultiply
            v.max = v.max * difficultyMultiply

            -- The reduction occurs only after all the multipliers are applied to the damage.
            if armorRating > 0 then
                v.min = combat.CalculateDamageReductionFromArmorRating(v.min, armorRating, self.fCombatArmorMinMult)
                v.max = combat.CalculateDamageReductionFromArmorRating(v.max, armorRating, self.fCombatArmorMinMult)
            end
        end
        v.min = combat.CalculateDPS(v.min, minSpeed)
        v.max = combat.CalculateDPS(v.max, maxSpeed)
    end
    return baseDamage
end

---@class DPSData
---@field weaponDamageRange DamageRange
---@field weaponDamages { [tes3.physicalAttackType]: DamageRange }
---@field highestType { [tes3.physicalAttackType]: boolean }
---@field effectTotal number
---@field effectDamages { [tes3.effect]: number }
---@field icons Icons tes3.physicalAttackType is negative numbers to avoid duplicate keys for tes3.effect and tes3.physicalAttackType

--- I'm not sure how to resolve Morrowind's effect strictly.
--- If it was to apply them in order from the top, each time, then when the order is Damage, Weakness, so Weakness would have no effect at all.
--- It is indeed possible to do so, but here it resolves all modifiers once and then apply them.
--- And Why do I not use tes3.getEffectMagnitude() or other useful functions? That's because it works for players, but cannot be used against a notional, nonexistent enemy.
---@param self DPS
---@param weapon tes3weapon
---@param itemData tes3itemData
---@param useBestAttack boolean
---@param difficulty number
---@return DPSData
function DPS.CalculateDPS(self, weapon, itemData, useBestAttack, difficulty)
    local marksman = weapon.isRanged or weapon.isProjectile
    local speed = weapon.speed -- TODO perhaps speed is scale factor, not acutal length
    local canCastOnStrike = self:CanCastOnStrike(weapon)
    local effect = resolver.CreateScratchData()
    local icons = {} ---@type {[tes3.effect]: string[]}

    CollectEnchantmentEffect(effect, icons, weapon.enchantment, speed, canCastOnStrike, weapon.skillId)
    CollectActiveMagicEffect(effect, tes3.mobilePlayer.activeMagicEffectList, weapon, canCastOnStrike)

    if self.poisonCrafting then
        local poison = self.poisonCrafting.GetPoison(weapon, itemData)
        if poison then
            -- poison effect is only once, so speed is 1
            -- Also in vanilla, potion's effectRange is always self, because of it cannot be applied to weapons. Therefore, it is forced to be touch effect
            CollectEffects(effect, icons, poison.effects, 1, weapon.skillId, true)
        end
    end

    local resistMagicka = GetModifiedEffects(effect.attacker, tes3.effectAttribute.resistMagicka, tes3.mobilePlayer.effectAttributes)
    ResolveModifiers(effect, icons, resistMagicka)

    -- merge icon to weapon damage
    if self.config.accurateDamage then
        ---@param e tes3.effect
        ---@param a tes3.attribute?
        ---@param s tes3.skill?
        local function MergePhysicalIcons(e, a, s)
            local physical = {
                tes3.physicalAttackType.slash,
                tes3.physicalAttackType.chop,
                tes3.physicalAttackType.thrust,
                tes3.physicalAttackType.projectile,
            }
            for _, i in ipairs(physical) do
                MergeIcons(icons, -i, e, a, s)
            end
        end
        -- TODO data orientation
        if resolver.GetValue(effect.target.positives, tes3.effect.shield, 0) ~= 0 then
            MergePhysicalIcons(tes3.effect.shield)
        end
        -- TODO not zero check is better?
        -- for k, v in pairs(effect.attacker.attributes) do
        --     if resolver.GetValue(v, tes3.attribute.strength, 0) ~= 0 then
        --     end
        -- end
        MergePhysicalIcons(tes3.effect.drainAttribute, tes3.attribute.strength, nil)
        MergePhysicalIcons(tes3.effect.absorbAttribute, tes3.attribute.strength, nil)
        MergePhysicalIcons(tes3.effect.damageAttribute, tes3.attribute.strength, nil)
        MergePhysicalIcons(tes3.effect.fortifyAttribute, tes3.attribute.strength, nil)
        MergePhysicalIcons(tes3.effect.restoreAttribute, tes3.attribute.strength, nil)
    end

    local strength = GetModifiedAttribute(effect.attacker, tes3.attribute.strength, tes3.mobilePlayer.attributes, self.restoreDrainAttributesFix)
    local armorRating = GetTargetArmorRating(effect);
    local difficultyMultiply = self.config.difficulty and combat.CalculateDifficultyMultiplier(difficulty, self.fDifficultyMult) or 1.0;

    local weaponDamages = self:CalculateWeaponDamage(weapon, itemData, speed, strength, armorRating, difficultyMultiply, marksman, useBestAttack)
    local weaponDamageRange, highestType = ResolveWeaponDPS(weaponDamages, self.config.minmaxRange)
    local effectTotal, effectDamages = ResolveEffectDPS(effect, difficultyMultiply)

    return {
        weaponDamageRange = weaponDamageRange,
        weaponDamages = weaponDamages,
        highestType = highestType,
        effectTotal = effectTotal,
        effectDamages = effectDamages,
        icons = icons,
    }
end

---@param self DPS
---@param unitwind MyUnitWind
function DPS.RunTest(self, unitwind)
    unitwind:start("DPSTooltips.effect")

    -- mock
    unitwind:mock(tes3, "findGMST", function(id)
        local gmst = {
            [tes3.gmst.fDamageStrengthBase] = { value = 0.5 },
            [tes3.gmst.fDamageStrengthMult] = { value = 0.1 },
            [tes3.gmst.fFatigueBase] = { value = 1.25 },
            [tes3.gmst.fFatigueMult] = { value = 0.5 },
            [tes3.gmst.fCombatInvisoMult] = { value = 0.2 },
            [tes3.gmst.fSwingBlockBase] = { value = 1.0 },
            [tes3.gmst.fSwingBlockMult] = { value = 1.0 },
            [tes3.gmst.fBlockStillBonus] = { value = 1.25 },
            [tes3.gmst.iBlockMinChance] = { value = 10 },
            [tes3.gmst.iBlockMaxChance] = { value = 50 },
            [tes3.gmst.fCombatArmorMinMult] = { value = 0.25 },
            [tes3.gmst.fDifficultyMult] = { value = 5.0 },
        }
        if gmst[id] then
            return gmst[id]
        end
        return { value = tostring(id) } -- temp
    end)
    unitwind:mock(tes3, "hasCodePatchFeature", function(id)
        return false
    end)
    unitwind:mock(tes3, "isModActive", function(filename)
        return false
    end)
    unitwind:mock(tes3, "isLuaModActive", function(key)
        return false
    end)
    unitwind:mock(tes3, "mobilePlayer", {
        activeMagicEffectList = {},
        attributes = {
            { base = 100, current = 100 }, -- strength
            { base = 100, current = 100 }, -- intelligence
            { base = 100, current = 100 }, -- willpower
            { base = 100, current = 100 }, -- agility
            { base = 100, current = 100 }, -- speed
            { base = 100, current = 100 }, -- endurance
            { base = 100, current = 100 }, -- personality
            { base = 100, current = 100 }, -- luck
        },
        effectAttributes = {
            0, -- attackBonus
            0, -- sanctuary
            0, -- resistMagicka
            0, -- resistFire
            0, -- resistFrost
            0, -- resistShock
            0, -- resistCommonDisease
            0, -- resistBlightDisease
            0, -- resistCorprus
            0, -- resistPoison
            0, -- resistParalysis
            0, -- chameleon
            0, -- resistNormalWeapons
            0, -- waterBreathing
            0, -- waterWalking
            0, -- swiftSwim
            0, -- jump
            0, -- levitate
            0, -- shield
            0, -- sound
            0, -- silence
            0, -- blind
            0, -- paralyze
            0, -- invisibility
            0, -- fight
            0, -- flee
            0, -- hello
            0, -- alarm
            0, -- nonResistable
        },
        skills = {
            { base = 100, current = 100 }, -- block
            { base = 100, current = 100 }, -- armorer
            { base = 100, current = 100 }, -- mediumArmor
            { base = 100, current = 100 }, -- heavyArmor
            { base = 100, current = 100 }, -- bluntWeapon
            { base = 100, current = 100 }, -- longBlade
            { base = 100, current = 100 }, -- axe
            { base = 100, current = 100 }, -- spear
            { base = 100, current = 100 }, -- athletics
            { base = 100, current = 100 }, -- enchant
            { base = 100, current = 100 }, -- destruction
            { base = 100, current = 100 }, -- alteration
            { base = 100, current = 100 }, -- illusion
            { base = 100, current = 100 }, -- conjuration
            { base = 100, current = 100 }, -- mysticism
            { base = 100, current = 100 }, -- restoration
            { base = 100, current = 100 }, -- alchemy
            { base = 100, current = 100 }, -- unarmored
            { base = 100, current = 100 }, -- security
            { base = 100, current = 100 }, -- sneak
            { base = 100, current = 100 }, -- acrobatics
            { base = 100, current = 100 }, -- lightArmor
            { base = 100, current = 100 }, -- shortBlade
            { base = 100, current = 100 }, -- marksman
            { base = 100, current = 100 }, -- mercantile
            { base = 100, current = 100 }, -- speechcraft
            { base = 100, current = 100 }, -- handToHand
        },
    })

    local config = require("longod.DPSTooltips.config").Default() -- use non-persisitent config for testing
    local dps = require("longod.DPSTooltips.dps").new(config)
    dps:Initialize()

    unitwind:test("GetConditionModifier", function()
        ---@type tes3weapon
        local weapon = {
            hasDurability = false,
            maxCondition = 100,
        }
        ---@type tes3itemData
        local itemData ={
            condition = 50,
        }
        unitwind:approxExpect(GetConditionModifier(weapon, nil)).toBe(1.0) ---@diagnostic disable-line: param-type-mismatch
        unitwind:approxExpect(GetConditionModifier(weapon, itemData)).toBe(1.0)
        weapon.hasDurability = true
        unitwind:approxExpect(GetConditionModifier(weapon, nil)).toBe(1.0) ---@diagnostic disable-line: param-type-mismatch
        unitwind:approxExpect(GetConditionModifier(weapon, itemData)).toBe(0.5)
    end)

    unitwind:test("GetStrengthModifier", function()
        unitwind:approxExpect(GetStrengthModifier(100, 0.5, 0.01)).toBe(1.5)
        unitwind:approxExpect(GetStrengthModifier(0, 0.5, 0.01)).toBe(0.5)
        unitwind:approxExpect(GetStrengthModifier(-100, 0.5, 0.01)).toBe(0.5) -- capped
    end)

    unitwind:test("GetWeaponBaseDamage", function()
        ---@type tes3weapon
        local weapon = {
            slashMin = 1,
            slashMax = 2,
            thrustMin = 3,
            thrustMax = 4,
            chopMin = 5,
            chopMax = 6,
        }
        local actual = GetWeaponBaseDamage(weapon, false, false, false)
        unitwind:approxExpect(actual[tes3.physicalAttackType.slash].min).toBe(weapon.slashMin)
        unitwind:approxExpect(actual[tes3.physicalAttackType.slash].max).toBe(weapon.slashMax)
        unitwind:approxExpect(actual[tes3.physicalAttackType.thrust].min).toBe(weapon.thrustMin)
        unitwind:approxExpect(actual[tes3.physicalAttackType.thrust].max).toBe(weapon.thrustMax)
        unitwind:approxExpect(actual[tes3.physicalAttackType.chop].min).toBe(weapon.chopMin)
        unitwind:approxExpect(actual[tes3.physicalAttackType.chop].max).toBe(weapon.chopMax)
        unitwind:approxExpect(actual[tes3.physicalAttackType.projectile]).toBe(nil)
        actual = GetWeaponBaseDamage(weapon, false, false, true)
        unitwind:approxExpect(actual[tes3.physicalAttackType.slash].min).toBe(weapon.slashMin)
        unitwind:approxExpect(actual[tes3.physicalAttackType.slash].max).toBe(weapon.slashMax)
        unitwind:approxExpect(actual[tes3.physicalAttackType.projectile]).toBe(nil)
        actual = GetWeaponBaseDamage(weapon, false, true, false)
        unitwind:approxExpect(actual[tes3.physicalAttackType.slash]).toBe(nil)
        unitwind:approxExpect(actual[tes3.physicalAttackType.thrust]).toBe(nil)
        unitwind:approxExpect(actual[tes3.physicalAttackType.chop].min).toBe(weapon.chopMin)
        unitwind:approxExpect(actual[tes3.physicalAttackType.chop].max).toBe(weapon.chopMax)
        unitwind:approxExpect(actual[tes3.physicalAttackType.projectile]).toBe(nil)
        actual = GetWeaponBaseDamage(weapon, false, true, true)
        unitwind:approxExpect(actual[tes3.physicalAttackType.chop].min).toBe(weapon.chopMin)
        unitwind:approxExpect(actual[tes3.physicalAttackType.chop].max).toBe(weapon.chopMax)
        unitwind:approxExpect(actual[tes3.physicalAttackType.projectile]).toBe(nil)
        actual = GetWeaponBaseDamage(weapon, true, false, false)
        unitwind:approxExpect(actual[tes3.physicalAttackType.slash]).toBe(nil)
        unitwind:approxExpect(actual[tes3.physicalAttackType.thrust]).toBe(nil)
        unitwind:approxExpect(actual[tes3.physicalAttackType.chop]).toBe(nil)
        unitwind:approxExpect(actual[tes3.physicalAttackType.projectile].min).toBe(weapon.chopMin)
        unitwind:approxExpect(actual[tes3.physicalAttackType.projectile].max).toBe(weapon.chopMax)
        actual = GetWeaponBaseDamage(weapon, true, false, true)
        unitwind:approxExpect(actual[tes3.physicalAttackType.slash]).toBe(nil)
        unitwind:approxExpect(actual[tes3.physicalAttackType.thrust]).toBe(nil)
        unitwind:approxExpect(actual[tes3.physicalAttackType.chop]).toBe(nil)
        unitwind:approxExpect(actual[tes3.physicalAttackType.projectile].min).toBe(weapon.chopMin * 2)
        unitwind:approxExpect(actual[tes3.physicalAttackType.projectile].max).toBe(weapon.chopMax* 2)
        actual = GetWeaponBaseDamage(weapon, true, true, false)
        unitwind:approxExpect(actual[tes3.physicalAttackType.chop]).toBe(nil)
        unitwind:approxExpect(actual[tes3.physicalAttackType.projectile].min).toBe(weapon.chopMin)
        unitwind:approxExpect(actual[tes3.physicalAttackType.projectile].max).toBe(weapon.chopMax)
        actual = GetWeaponBaseDamage(weapon, true, true, true)
        unitwind:approxExpect(actual[tes3.physicalAttackType.chop]).toBe(nil)
        unitwind:approxExpect(actual[tes3.physicalAttackType.projectile].min).toBe(weapon.chopMin * 2)
        unitwind:approxExpect(actual[tes3.physicalAttackType.projectile].max).toBe(weapon.chopMax* 2)
    end)

    unitwind:test("CanCastOnStrike", function()
        ---@type tes3weapon
        local weapon = {
            isMelee = true,
            isProjectile = false,
        }
        unitwind:unmock(tes3, "isModActive")
        unitwind:mock(tes3, "isModActive", function(filename)
            if filename == "Cast on Strike Bows.esp" then
                return true
            end
            return false
        end)
        dps:Initialize()
        weapon.isMelee = true
        weapon.isProjectile = false
        unitwind:expect(dps:CanCastOnStrike(weapon)).toBe(true) -- melee
        weapon.isMelee = false
        unitwind:expect(dps:CanCastOnStrike(weapon)).toBe(true) -- ranged
        weapon.isProjectile = true
        unitwind:expect(dps:CanCastOnStrike(weapon)).toBe(true) -- throw

        unitwind:unmock(tes3, "isModActive")
        unitwind:mock(tes3, "isModActive", function(filename)
            return false
        end)
        dps:Initialize()
        weapon.isMelee = true
        weapon.isProjectile = false
        unitwind:expect(dps:CanCastOnStrike(weapon)).toBe(true) -- melee
        weapon.isMelee = false
        unitwind:expect(dps:CanCastOnStrike(weapon)).toBe(false) -- ranged
        weapon.isProjectile = true
        unitwind:expect(dps:CanCastOnStrike(weapon)).toBe(true) -- throw
    end)

    unitwind:test("NeedModifyThrowWeapon", function()
        ---@type tes3weapon
        local weapon = {
            type = tes3.weaponType.arrow,
        }

        unitwind:unmock(tes3, "isLuaModActive")
        unitwind:mock(tes3, "isLuaModActive", function(filename)
            if filename == "DQ.ThroProjRev" then
                return true
            end
            return false
        end)
        dps:Initialize()
        weapon.type = tes3.weaponType.arrow
        unitwind:expect(dps:NeedModifyThrowWeapon(weapon)).toBe(false)
        weapon.type = tes3.weaponType.marksmanThrown
        unitwind:expect(dps:NeedModifyThrowWeapon(weapon)).toBe(false)

        unitwind:unmock(tes3, "isLuaModActive")
        unitwind:mock(tes3, "isLuaModActive", function(filename)
            return false
        end)
        dps:Initialize()
        weapon.type = tes3.weaponType.arrow
        unitwind:expect(dps:NeedModifyThrowWeapon(weapon)).toBe(false)
        weapon.type = tes3.weaponType.marksmanThrown
        unitwind:expect(dps:NeedModifyThrowWeapon(weapon)).toBe(true)
    end)

    unitwind:test("GetFatigueTerm", function()
        unitwind:approxExpect(dps:GetFatigueTerm(100, 200)).toBe(combat.CalculateFatigueTerm(100, 200, 1.25, 0.5))
    end)

    unitwind:finish()

end

return DPS
