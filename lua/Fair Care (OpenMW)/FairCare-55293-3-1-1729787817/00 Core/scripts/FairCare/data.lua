local T = require('openmw.types')

local mCfg = require('scripts.FairCare.configuration')

local module = {}

-- Ids of available touch heal spells provided by the addon
module.selfSpellIds = {
    "fair care heal huge",
    "fair care heal high",
    "fair care heal medium",
    "fair care heal low",
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

local aiModes = {
    Dead = 0,
    Inactive = 1,
    Default = 2,
    HealFriend = 3,
}
module.aiModes = aiModes

for key in pairs(mCfg.chanceImpacts) do
    mCfg.chanceImpacts[key].key = key
end
module.chanceImpacts = mCfg.chanceImpacts

local actions = {
    selfHeal = 0,
    touchHeal = 1,
}
module.actions = actions

local function newChanceType(action, order, impact, monitored)
    return { action = action, order = order, impact = impact, monitored = monitored}
end

local chanceTypes = {
-- WOUNDED
    woundedHealth = newChanceType(actions.selfHeal, 0, mCfg.chanceImpacts.impactNormal),
    woundedCastChances = newChanceType(actions.selfHeal, 1, mCfg.chanceImpacts.impactNormal),
-- HEALER
    healerCastChances = newChanceType(actions.touchHeal, 0, mCfg.chanceImpacts.impactNormal, true),
    healerPartnerHealth = newChanceType(actions.touchHeal, 1, mCfg.chanceImpacts.impactLowest, true),
    healerSpellIntensity = newChanceType(actions.touchHeal, 2, mCfg.chanceImpacts.impactLower, false),
    healerHealth = newChanceType(actions.touchHeal, 3, mCfg.chanceImpacts.impactLow, true),
    healerMagickaCost = newChanceType(actions.touchHeal, 4, mCfg.chanceImpacts.impactLower, true),
    healerDisposition = newChanceType(actions.touchHeal, 5, mCfg.chanceImpacts.impactLow, true),
    healerTravelTime = newChanceType(actions.touchHeal, 6, mCfg.chanceImpacts.impactLow, false),
}
for key in pairs(chanceTypes) do
    chanceTypes[key].key = key
end
module.chanceTypes = chanceTypes

return module
