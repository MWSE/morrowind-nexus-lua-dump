-- This file contains main configuration values and functions that are not configurable from the in-game settings page.
-- You can alter its content to change the mod balance
local config = {
    -- How skill levels up make attributes grow with the slow setting
    attributeGrowthFactor = 0.5,

    -- How attributes growth setting increases (normal += 50% , fast += 100%)
    attributeGrowthFactorIncrease = 0.5,

    -- How skills contribute to attributes growth
    skillsImpactOnAttributes = {
        heavyarmor = { strength = 3, endurance = 4 },
        mediumarmor = { strength = 2, agility = 1, endurance = 3, speed = 1 },
        lightarmor = { agility = 3, endurance = 2, speed = 2 },
        unarmored = { agility = 2, endurance = 1, speed = 3, personality = 1 },
        block = { strength = 1, agility = 3, endurance = 3 },
        armorer = { strength = 4, endurance = 2, personality = 1 },

        axe = { strength = 5, agility = 1, speed = 1 },
        bluntweapon = { strength = 4, agility = 1, endurance = 1, speed = 1 },
        longblade = { strength = 3, agility = 3, speed = 1 },
        spear = { strength = 3, endurance = 4 },
        shortblade = { strength = 1, agility = 3, speed = 3 },
        handtohand = { strength = 2, agility = 1, speed = 3, personality = 1 },
        marksman = { strength = 2, agility = 3, speed = 2 },

        sneak = { agility = 4, speed = 2, personality = 1 },
        athletics = { strength = 1, endurance = 1, speed = 5 },
        acrobatics = { strength = 4, speed = 3 },
        security = { agility = 3, speed = 1, intelligence = 3 },
        mercantile = { intelligence = 2, personality = 5 },
        speechcraft = { intelligence = 1, willpower = 1, personality = 5 },

        illusion = { intelligence = 2, willpower = 1, personality = 4 },
        restoration = { willpower = 5, personality = 2 },
        mysticism = { intelligence = 1, willpower = 6 },
        destruction = { intelligence = 2, willpower = 5 },
        conjuration = { intelligence = 2, willpower = 4, personality = 1 },
        alteration = { intelligence = 4, willpower = 3 },
        enchant = { intelligence = 5, willpower = 2 },
        alchemy = { intelligence = 6, willpower = 1 },
    },

    skillsImpactSums = {},

    -- How attributes contribute to total health
    healthAttributeFactors = {
        endurance = 4 / 7,
        strength = 2 / 7,
        willpower = 1 / 7,
    },
}

for skillId, factors in pairs(config.skillsImpactOnAttributes) do
    config.skillsImpactSums[skillId] = 0
    for _, factor in pairs(factors) do
        config.skillsImpactSums[skillId] = config.skillsImpactSums[skillId] + factor
    end
end

config.setSkillsImpactOnAttributes = function(skillId, attrImpacts)
    config.skillsImpactOnAttributes[skillId] = attrImpacts
end

return config