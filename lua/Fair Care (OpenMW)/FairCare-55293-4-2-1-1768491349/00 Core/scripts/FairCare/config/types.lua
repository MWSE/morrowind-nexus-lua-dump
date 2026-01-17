local T = require('openmw.types')

local mCfg = require('scripts.FairCare.config.config')

local module = {}

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

for key in pairs(mCfg.chanceImpacts) do
    mCfg.chanceImpacts[key].key = key
end
module.chanceImpacts = mCfg.chanceImpacts

local actions = {
    selfHeal = 0,
    touchHeal = 1,
}
module.actions = actions

local function newChanceType(action, order, impact)
    return { action = action, order = order, impact = impact }
end

local chanceTypes = {
    -- WOUNDED
    woundedHealth = newChanceType(actions.selfHeal, 0, mCfg.chanceImpacts.impactNormal),
    woundedCastChances = newChanceType(actions.selfHeal, 1, mCfg.chanceImpacts.impactNormal),
    -- HEALER
    healerPartnerHealth = newChanceType(actions.touchHeal, 0, mCfg.chanceImpacts.impactLowest),
    healerCastChances = newChanceType(actions.touchHeal, 1, mCfg.chanceImpacts.impactNormal),
    healerSpellIntensity = newChanceType(actions.touchHeal, 2, mCfg.chanceImpacts.impactLower),
    healerMagickaCost = newChanceType(actions.touchHeal, 4, mCfg.chanceImpacts.impactLower),
    healerHealth = newChanceType(actions.touchHeal, 3, mCfg.chanceImpacts.impactLow),
    healerDisposition = newChanceType(actions.touchHeal, 5, mCfg.chanceImpacts.impactLow),
    healerTravelTime = newChanceType(actions.touchHeal, 6, mCfg.chanceImpacts.impactLow),
}
for key in pairs(chanceTypes) do
    chanceTypes[key].key = key
end
module.chanceTypes = chanceTypes

return module
