local T = require('openmw.types')

local module = {}

module.healthRegenRatios = { VeryLow = 1 / 4, Low = 1 / 2, Medium = 1, High = 2, VeryHigh = 4 }

module.cfgStates = {
    unset = "unset",
    reset = "reset",
    delay = "delay",
}

-- Ids of available self healing spells provided by the addon
module.selfHealSpellIds = {
    "fair care self heal lower",
    "fair care self heal low",
    "fair care self heal medium",
    "fair care self heal high",
    "fair care self heal higher",
}

-- Ids of available touch healing spells provided by the addon
module.selfTouchSpellIds = {
    "fair care touch heal lower",
    "fair care touch heal low",
    "fair care touch heal medium",
    "fair care touch heal high",
    "fair care touch heal higher",
}

-- Names of creature types
module.creatureTypes = {
    [T.Creature.TYPE.Creatures] = "Creature",
    [T.Creature.TYPE.Daedra] = "Daedra",
    [T.Creature.TYPE.Humanoid] = "Humanoid",
    [T.Creature.TYPE.Undead] = "Undead",
}

-- Names of actor stances
module.stances = {
    [T.Actor.STANCE.Nothing] = "Nothing",
    [T.Actor.STANCE.Weapon] = "Weapon",
    [T.Actor.STANCE.Spell] = "Spell",
}

module.itemTypes = {
    [T.Armor] = "Armor",
    [T.Book] = "Book",
    [T.Clothing] = "Clothing",
    [T.Potion] = "Potion",
    [T.Weapon] = "Weapon",
}

module.restoreHealthPotions = {
    "p_restore_health_e",
    "p_restore_health_q",
    "p_restore_health_s",
    "p_restore_health_c",
    "p_restore_health_b",
}

module.potentialAttackGroups = {
    "spellcast",
    "handtohand",
    "weapononehand",
    "weapontwohand",
    "weapontwowide",
    "throwweapon",
    "bowandarrow",
    "crossbow"
}
for i = 1, 3 do
    table.insert(module.potentialAttackGroups, "attack" .. i)
    table.insert(module.potentialAttackGroups, "swimattack" .. i)
end

module.spellcastKeys = { self = "self", touch = "touch", target = "target" }

module.requiredSpellcastSubKeys = { "start", "release", "stop" }

module.newAnimState = function()
    return {
        hasHealingAnimations = false,
        spellcastAttackGroups = {},
        spellcastAnimKeys = {},
        noSpellStanceAttackGroups = nil,
        isPlayingAttackGroup = nil,
        lastAttackGroup = nil,
        lastAttackGroupReleased = false,
    }
end

module.aiModes = {
    Dead = 0,
    Inactive = 1,
    Default = 2,
    Healing = 3,
}

module.globalDataTypes = {
    potions = "potions",
}

local actions = {
    selfHeal = 0,
    touchHeal = 1,
}
module.actions = actions

-- Healing acceptance condition can be configured to have more or less impact
-- A power is applied to the chance value (value is between 0 and 1)
local chanceImpacts = {
    ImpactNone = 0,
    ImpactLowest = 1 / 8,
    ImpactLower = 1 / 4,
    ImpactLow = 1 / 2,
    ImpactNormal = 1,
}
module.chanceImpacts = chanceImpacts

local function newChanceType(action, order, impact)
    return { action = action, order = order, impact = impact }
end

module.chanceTypes = {
    -- WOUNDED
    woundedHealth = newChanceType(actions.selfHeal, 0, chanceImpacts.ImpactNormal),
    woundedCastChances = newChanceType(actions.selfHeal, 1, chanceImpacts.ImpactNormal),
    -- HEALER
    healerPartnerHealth = newChanceType(actions.touchHeal, 0, chanceImpacts.ImpactLowest),
    healerCastChances = newChanceType(actions.touchHeal, 1, chanceImpacts.ImpactNormal),
    healerSpellIntensity = newChanceType(actions.touchHeal, 2, chanceImpacts.ImpactLower),
    healerMagickaCost = newChanceType(actions.touchHeal, 4, chanceImpacts.ImpactLower),
    healerHealth = newChanceType(actions.touchHeal, 3, chanceImpacts.ImpactLow),
    healerDisposition = newChanceType(actions.touchHeal, 5, chanceImpacts.ImpactLow),
    healerTravelTime = newChanceType(actions.touchHeal, 6, chanceImpacts.ImpactLow),
}
for key in pairs(module.chanceTypes) do
    module.chanceTypes[key].key = key
end

return module
