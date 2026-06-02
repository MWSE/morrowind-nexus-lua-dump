-- This file contains main configuration values and functions that are not configurable from the in-game settings page.
-- You can alter its content to change the mod balance

local config = {
    -- How skills contribute to attribute growth
    skillAttributeImpactFactors = {
        armorer = { strength = 10, intelligence = 15, willpower = 5, agility = 0, speed = 0, endurance = 60, personality = 10 },
        athletics = { strength = 5, intelligence = 0, willpower = 0, agility = 5, speed = 60, endurance = 20, personality = 10 },
        axe = { strength = 60, intelligence = 0, willpower = 0, agility = 15, speed = 20, endurance = 0, personality = 5 },
        block = { strength = 10, intelligence = 5, willpower = 15, agility = 5, speed = 0, endurance = 60, personality = 5 },
        bluntweapon = { strength = 60, intelligence = 5, willpower = 15, agility = 5, speed = 10, endurance = 5, personality = 0 },
        heavyarmor = { strength = 20, intelligence = 5, willpower = 0, agility = 0, speed = 0, endurance = 60, personality = 15 },
        longblade = { strength = 60, intelligence = 5, willpower = 0, agility = 15, speed = 5, endurance = 0, personality = 15 },
        mediumarmor = { strength = 10, intelligence = 10, willpower = 5, agility = 5, speed = 5, endurance = 60, personality = 5 },
        spear = { strength = 5, intelligence = 10, willpower = 60, agility = 15, speed = 0, endurance = 10, personality = 0 },

        alchemy = { strength = 0, intelligence = 60, willpower = 5, agility = 0, speed = 15, endurance = 15, personality = 5 },
        alteration = { strength = 10, intelligence = 15, willpower = 60, agility = 0, speed = 10, endurance = 5, personality = 0 },
        conjuration = { strength = 15, intelligence = 60, willpower = 5, agility = 0, speed = 0, endurance = 5, personality = 15 },
        destruction = { strength = 5, intelligence = 5, willpower = 60, agility = 15, speed = 5, endurance = 0, personality = 10 },
        enchant = { strength = 10, intelligence = 60, willpower = 5, agility = 5, speed = 5, endurance = 10, personality = 5 },
        illusion = { strength = 0, intelligence = 10, willpower = 15, agility = 10, speed = 5, endurance = 0, personality = 60 },
        mysticism = { strength = 0, intelligence = 60, willpower = 20, agility = 0, speed = 0, endurance = 5, personality = 15 },
        restoration = { strength = 5, intelligence = 5, willpower = 60, agility = 5, speed = 0, endurance = 15, personality = 10 },
        unarmored = { strength = 0, intelligence = 0, willpower = 10, agility = 10, speed = 60, endurance = 0, personality = 20 },

        acrobatics = { strength = 10, intelligence = 0, willpower = 0, agility = 10, speed = 60, endurance = 5, personality = 15 },
        handtohand = { strength = 60, intelligence = 0, willpower = 10, agility = 10, speed = 10, endurance = 10, personality = 0 },
        lightarmor = { strength = 5, intelligence = 0, willpower = 0, agility = 15, speed = 60, endurance = 10, personality = 10 },
        marksman = { strength = 10, intelligence = 0, willpower = 0, agility = 60, speed = 15, endurance = 5, personality = 10 },
        mercantile = { strength = 5, intelligence = 20, willpower = 0, agility = 0, speed = 0, endurance = 15, personality = 60 },
        security = { strength = 0, intelligence = 15, willpower = 15, agility = 60, speed = 5, endurance = 5, personality = 0 },
        shortblade = { strength = 0, intelligence = 0, willpower = 0, agility = 60, speed = 20, endurance = 0, personality = 20 },
        sneak = { strength = 10, intelligence = 5, willpower = 5, agility = 60, speed = 15, endurance = 0, personality = 5 },
        speechcraft = { strength = 0, intelligence = 15, willpower = 15, agility = 0, speed = 5, endurance = 5, personality = 60 },
    },

    -- How attributes contribute to total health
    attributeHealthImpactFactors = {
        strength = 1/2, endurance = 1/2
    },

    attributeRetroactiveHealthImpactFactors = {
        endurance = 1
    },
}

config.getImpactFactorSum = function(table)
    local sum = 0
    for _, impactFactor in pairs(table) do
        sum = sum + impactFactor
    end
    return sum
end

config.getSkillAttributeImpactFactorSum = function(skillId)
    return config.getImpactFactorSum(config.skillAttributeImpactFactors[skillId])
end

config.setSkillAttributeImpactFactors = function(skillId, impacts)
    config.skillAttributeImpactFactors[skillId] = impacts
    return true
end

config.getAttributeHealthImpactFactorSum = function()
    return config.getImpactFactorSum(config.attributeHealthImpactFactors)
end

config.setAttributeHealthImpactFactors = function(impacts)
    config.attributeHealthImpactFactors = impacts
    return true
end

config.getAttributeRetroactiveHealthImpactFactorSum = function()
    return config.getImpactFactorSum(config.attributeRetroactiveHealthImpactFactors)
end

config.setAttributeRetroactiveHealthImpactFactors = function(impacts)
    config.attributeRetroactiveHealthImpactFactors = impacts
    return true
end

return config