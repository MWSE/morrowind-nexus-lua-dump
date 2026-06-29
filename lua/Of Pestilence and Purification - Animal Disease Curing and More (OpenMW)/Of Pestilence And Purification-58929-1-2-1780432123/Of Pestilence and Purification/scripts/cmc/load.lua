local content = require('openmw.content')
local cfg = require('scripts.cmc.config')

local Spell = content.spells.TYPE.Spell
local Ability = content.spells.TYPE.Ability or Spell
local Self = content.RANGE.Self
local Target = content.RANGE.Target
local Touch = content.RANGE.Touch
local carrierDuration = tonumber(cfg.thresholds.effectCarrierDuration or 2) or 2

local function defineMagicEffect(id, templateId, fields)
    if content.magicEffects.records[id] then return end
    local template = content.magicEffects.records[templateId]
    if not template then return end
    local rec = { template = template }
    for k, v in pairs(fields or {}) do rec[k] = v end
    content.magicEffects.records[id] = rec
end

local function eff(id, range, area, duration, magnitudeMin, magnitudeMax, affectedAttribute, affectedSkill)
    return {
        id = id,
        range = range,
        area = area or 0,
        duration = duration or 0,
        magnitudeMin = magnitudeMin or 1,
        magnitudeMax = magnitudeMax or magnitudeMin or 1,
        affectedAttribute = affectedAttribute,
        affectedSkill = affectedSkill,
    }
end

local function defineSpell(id, record)
    if content.spells.records[id] then return end
    if record.isAutocalc == nil then record.isAutocalc = false end
    content.spells.records[id] = record
end

-- Spell tomes are defined in OfPestilenceAndPurification.omwaddon.

local function defineTome(def)
    -- Tomes are authored in OfPestilenceAndPurification.omwaddon so they can use
    -- ordinary vanilla book mesh/icon records. This no-op keeps Lua loading safe
    -- when cfg.tomeDefs is iterated below.
    return def ~= nil
end

-- Custom OpenMW magic effects. The engine applies the effects normally; local
-- actor scripts observe them and request animal swaps, NPC blight marks,
-- or script-resolved damage from the global script.

defineMagicEffect(cfg.effects.cureCommon, cfg.effects.nativeCureCommon, {
    name = 'Purify Common Disease',
    description = 'Cleanses common disease from afflicted animals when a healthy form exists.',
    baseCost = 10,
    onSelf = false,
    onTouch = true,
    onTarget = false,
    harmful = false,
    hasDuration = true,
    hasMagnitude = false,
    isAppliedOnce = false,
})

defineMagicEffect(cfg.effects.cureBlight, cfg.effects.nativeCureBlight, {
    name = 'Purify Blight Disease',
    description = 'Cleanses blight from afflicted animals when a healthy form exists.',
    baseCost = 14,
    onSelf = false,
    onTouch = true,
    onTarget = false,
    harmful = false,
    hasDuration = true,
    hasMagnitude = false,
    isAppliedOnce = false,
})

defineMagicEffect(cfg.effects.spreadCommon, cfg.effects.nativeCureCommon, {
    name = 'Spread Common Disease',
    description = 'Infects healthy animals with common disease if a diseased variant exists.',
    baseCost = 8,
    onSelf = false,
    onTouch = true,
    onTarget = true,
    harmful = true,
    hasDuration = true,
    hasMagnitude = false,
    isAppliedOnce = false,
})

defineMagicEffect(cfg.effects.spreadBlight, cfg.effects.nativeCureBlight, {
    name = 'Spread Blight Disease',
    description = 'Infects healthy animals with blight if a blighted variant exists.',
    baseCost = 18,
    onSelf = false,
    onTouch = true,
    onTarget = true,
    harmful = true,
    hasDuration = true,
    hasMagnitude = false,
    isAppliedOnce = false,
})

defineMagicEffect(cfg.effects.contagionResistDamage, 'damagehealth', {
    name = 'Disease Damage',
    description = 'Common disease-aligned damage that hits harder against targets with lower common disease resistance.',
    baseCost = 14,
    onSelf = false,
    onTouch = true,
    onTarget = true,
    harmful = true,
    hasDuration = true,
    hasMagnitude = true,
    isAppliedOnce = true,
})

defineMagicEffect(cfg.effects.blightResistDamage, 'damagehealth', {
    name = 'Blight Damage',
    description = 'Blight-aligned damage that hits harder against targets with lower blight disease resistance.',
    baseCost = 20,
    onSelf = false,
    onTouch = true,
    onTarget = true,
    harmful = true,
    hasDuration = true,
    hasMagnitude = true,
    isAppliedOnce = true,
})

defineMagicEffect(cfg.effects.antiBlight, 'damagehealth', {
    name = 'Scourge Blight',
    description = 'Cleansing damage against blighted animals, marked NPCs, corprus beasts, and lesser Sixth House abominations.',
    baseCost = 12,
    onSelf = false,
    onTouch = true,
    onTarget = true,
    harmful = true,
    hasDuration = true,
    hasMagnitude = true,
    isAppliedOnce = true,
})

-- World spells; these are available through world integration and tomes rather
-- than counter rewards.
defineSpell(cfg.spells.purifyBeast, {
    name = 'Purify Beast',
    type = Spell,
    cost = 30,
    starterSpellFlag = false,
    effects = {
        eff(cfg.effects.cureCommon, Touch, 0, carrierDuration, 1, 1),
        eff(cfg.effects.cureBlight, Touch, 0, carrierDuration, 1, 1),
    },
})

defineSpell(cfg.spells.spreadCommon, {
    name = 'Spread Common Disease',
    type = Spell,
    cost = 8,
    starterSpellFlag = false,
    effects = { eff(cfg.effects.spreadCommon, Target, 0, carrierDuration, 1, 1) },
})

defineSpell(cfg.spells.peryiteGift, {
    name = "Peryite's Gift",
    type = Spell,
    cost = 8,
    starterSpellFlag = false,
    effects = { eff(cfg.effects.spreadCommon, Target, 0, carrierDuration, 1, 1) },
})

defineSpell(cfg.spells.spreadBlight, {
    name = 'Spread Blight Disease',
    type = Spell,
    cost = 18,
    starterSpellFlag = false,
    effects = { eff(cfg.effects.spreadBlight, Target, 0, carrierDuration, 1, 1) },
})

defineSpell(cfg.spells.dagothCompassion, {
    name = "Dagoth's Compassion",
    type = Spell,
    cost = 18,
    starterSpellFlag = false,
    effects = { eff(cfg.effects.spreadBlight, Target, 0, carrierDuration, 1, 1) },
})

defineSpell(cfg.spells.contagionFeverbite, {
    name = 'Contagion: Feverbite',
    type = Spell,
    cost = 16,
    starterSpellFlag = false,
    effects = { eff(cfg.effects.spreadCommon, Target, 0, carrierDuration, 1, 1), eff(cfg.effects.contagionResistDamage, Target, 0, carrierDuration, 10, 10) },
})

defineSpell(cfg.spells.contagionDamage, {
    name = 'Contagion',
    type = Spell,
    cost = 32,
    starterSpellFlag = false,
    effects = { eff(cfg.effects.contagionResistDamage, Target, 0, carrierDuration, 35, 35) },
})

defineSpell(cfg.spells.contagionPlagueburst, {
    name = 'Contagion: Plagueburst',
    type = Spell,
    cost = 48,
    starterSpellFlag = false,
    effects = { eff(cfg.effects.spreadCommon, Target, 10, carrierDuration, 1, 1), eff(cfg.effects.contagionResistDamage, Target, 10, carrierDuration, 20, 20) },
})

defineSpell(cfg.spells.mercyBlightBane, {
    name = "Mercy's Rebuke",
    type = Spell,
    cost = 18,
    effects = { eff(cfg.effects.antiBlight, Target, 0, carrierDuration, 25, 25) },
})

defineSpell(cfg.spells.mercyCleansingRay, {
    name = 'Cleansing Ray',
    type = Spell,
    cost = 35,
    effects = { eff(cfg.effects.antiBlight, Target, 0, carrierDuration, 50, 50) },
})

defineSpell(cfg.spells.mercyPurifyingStorm, {
    name = 'Purifying Storm',
    type = Spell,
    cost = 70,
    effects = { eff(cfg.effects.antiBlight, Target, 20, carrierDuration, 80, 80) },
})

defineSpell(cfg.spells.peryiteOrderedPestilence, {
    name = "Peryite's Ordered Pestilence",
    type = Spell,
    cost = 35,
    effects = { eff(cfg.effects.spreadCommon, Target, 15, carrierDuration, 1, 1) },
})



defineSpell(cfg.spells.ashPlume, {
    name = 'Ash Plume',
    type = Spell,
    cost = 78,
    effects = { eff(cfg.effects.blightResistDamage, Target, 0, carrierDuration, 70, 70) },
})

defineSpell(cfg.spells.ashstormCommunion, {
    name = 'Ashstorm Communion',
    type = Spell,
    cost = 125,
    effects = { eff(cfg.effects.spreadBlight, Target, 25, carrierDuration, 1, 1), eff(cfg.effects.blightResistDamage, Target, 25, carrierDuration, 40, 40) },
})

-- Counter reward traits. Each path now ranks up the same selected package
-- rather than granting unrelated bonuses at each tier. Disease/blight routes
-- trade immunity to the opposite infection for weakness to the embraced one;
-- disease adaptation then converts compatible infections into beneficial effects.
defineSpell(cfg.spells.mercyKindred, {
    name = 'Kindred of the Afflicted',
    type = Ability,
    cost = 0,
    effects = {
        eff('resistcommondisease', Self, 0, 0, 34, 34),
        eff('resistblightdisease', Self, 0, 0, 34, 34),
        eff('fortifyattribute', Self, 0, 0, 3, 3, 'willpower'),
        eff('fortifyattribute', Self, 0, 0, 3, 3, 'personality'),
        eff('fortifyskill', Self, 0, 0, 3, 3, nil, 'restoration'),
    },
})

defineSpell(cfg.spells.mercyWarden, {
    name = 'Warden of the Stricken',
    type = Ability,
    cost = 0,
    effects = {
        eff('resistcommondisease', Self, 0, 0, 67, 67),
        eff('resistblightdisease', Self, 0, 0, 67, 67),
        eff('fortifyattribute', Self, 0, 0, 7, 7, 'willpower'),
        eff('fortifyattribute', Self, 0, 0, 7, 7, 'personality'),
        eff('fortifyskill', Self, 0, 0, 7, 7, nil, 'restoration'),
    },
})

defineSpell(cfg.spells.mercyPlaguebreaker, {
    name = 'Plaguebreaker',
    type = Ability,
    cost = 0,
    effects = {
        eff('resistcommondisease', Self, 0, 0, 100, 100),
        eff('resistblightdisease', Self, 0, 0, 100, 100),
        eff('fortifyattribute', Self, 0, 0, 10, 10, 'willpower'),
        eff('fortifyattribute', Self, 0, 0, 10, 10, 'personality'),
        eff('fortifyskill', Self, 0, 0, 10, 10, nil, 'restoration'),
    },
})

defineSpell(cfg.spells.peryiteCarrier, {
    name = 'Vector of Peryite',
    type = Ability,
    cost = 0,
    effects = {
        eff('resistblightdisease', Self, 0, 0, 34, 34),
        eff(cfg.effects.weaknessCommon, Self, 0, 0, 25, 25),
        eff('resistpoison', Self, 0, 0, 15, 15),
        eff('fortifyattribute', Self, 0, 0, 5, 5, 'endurance'),
        eff('fortifyattribute', Self, 0, 0, 5, 5, 'willpower'),
        eff('drainattribute', Self, 0, 0, 15, 15, 'personality'),
    },
})

defineSpell(cfg.spells.peryiteVotary, {
    name = "Harbinger of Plague",
    type = Ability,
    cost = 0,
    effects = {
        eff('resistblightdisease', Self, 0, 0, 67, 67),
        eff(cfg.effects.weaknessCommon, Self, 0, 0, 50, 50),
        eff('resistpoison', Self, 0, 0, 30, 30),
        eff('fortifyattribute', Self, 0, 0, 10, 10, 'endurance'),
        eff('fortifyattribute', Self, 0, 0, 10, 10, 'willpower'),
        eff('fortifyskill', Self, 0, 0, 5, 5, nil, 'restoration'),
        eff('drainattribute', Self, 0, 0, 30, 30, 'personality'),
    },
})

defineSpell(cfg.spells.peryiteVector, {
    name = "Peryite's Herald",
    type = Ability,
    cost = 0,
    effects = {
        eff('resistblightdisease', Self, 0, 0, 100, 100),
        eff(cfg.effects.weaknessCommon, Self, 0, 0, 75, 75),
        eff('resistpoison', Self, 0, 0, 50, 50),
        eff('fortifyattribute', Self, 0, 0, 15, 15, 'endurance'),
        eff('fortifyattribute', Self, 0, 0, 15, 15, 'willpower'),
        eff('fortifyskill', Self, 0, 0, 10, 10, nil, 'restoration'),
        eff('drainattribute', Self, 0, 0, 45, 45, 'personality'),
    },
})

defineSpell(cfg.spells.blightCarrier, {
    name = 'Blighted Advocate',
    type = Ability,
    cost = 0,
    effects = {
        eff('resistcommondisease', Self, 0, 0, 34, 34),
        eff(cfg.effects.weaknessBlight, Self, 0, 0, 25, 25),
        eff('resistfire', Self, 0, 0, 10, 10),
        eff('fortifyattribute', Self, 0, 0, 5, 5, 'strength'),
        eff('fortifyattribute', Self, 0, 0, 5, 5, 'willpower'),
        eff('drainattribute', Self, 0, 0, 15, 15, 'personality'),
    },
})

defineSpell(cfg.spells.redDreamer, {
    name = 'Miasmatist of Blight',
    type = Ability,
    cost = 0,
    effects = {
        eff('resistcommondisease', Self, 0, 0, 67, 67),
        eff(cfg.effects.weaknessBlight, Self, 0, 0, 50, 50),
        eff('resistfire', Self, 0, 0, 20, 20),
        eff('fortifyattribute', Self, 0, 0, 10, 10, 'strength'),
        eff('fortifyattribute', Self, 0, 0, 10, 10, 'willpower'),
        eff('fortifyskill', Self, 0, 0, 5, 5, nil, 'destruction'),
        eff('drainattribute', Self, 0, 0, 30, 30, 'personality'),
    },
})

defineSpell(cfg.spells.ashstormApostle, {
    name = 'Apostle of the Blessed Ashstorm',
    type = Ability,
    cost = 0,
    effects = {
        eff('resistcommondisease', Self, 0, 0, 100, 100),
        eff(cfg.effects.weaknessBlight, Self, 0, 0, 75, 75),
        eff('resistfire', Self, 0, 0, 30, 30),
        eff('fortifyattribute', Self, 0, 0, 15, 15, 'strength'),
        eff('fortifyattribute', Self, 0, 0, 15, 15, 'willpower'),
        eff('fortifyskill', Self, 0, 0, 10, 10, nil, 'destruction'),
        eff('drainattribute', Self, 0, 0, 45, 45, 'personality'),
    },
})

local function inverseAfflictionEffect(def)
    if def.kind == 'attribute' then
        return eff('fortifyattribute', Self, 0, 0, def.min, def.max, def.name)
    elseif def.kind == 'skill' then
        return eff('fortifyskill', Self, 0, 0, def.min, def.max, nil, def.name)
    elseif def.kind == 'fatigue' then
        return eff('fortifyfatigue', Self, 0, 0, def.min, def.max)
    elseif def.kind == 'resistparalysis' then
        return eff('resistparalysis', Self, 0, 0, def.min, def.max)
    end
    return nil
end

for _, defs in pairs(cfg.playerAfflictionBoostDefs or {}) do
    for _, def in ipairs(defs) do
        local effects = {}
        for _, effectDef in ipairs(def.effects or {}) do
            local effect = inverseAfflictionEffect(effectDef)
            if effect then effects[#effects + 1] = effect end
        end
        defineSpell(def.boostId, {
            name = def.title,
            type = Ability,
            cost = 0,
            effects = effects,
        })
    end
end

for _, tome in ipairs(cfg.tomeDefs) do
    defineTome(tome)
end

return {}
