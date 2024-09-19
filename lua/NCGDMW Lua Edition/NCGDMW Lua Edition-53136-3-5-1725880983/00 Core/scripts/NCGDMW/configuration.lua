-- This file contains main configuration values and functions that are not configurable from the in-game settings page.
-- You can alter its content to change the mod balance

local H = require('scripts.NCGDMW.helpers')

local config = {
    -- How skills contribute to attributes growth
    skillsImpactOnAttributes = {
        block = { strength = 2, agility = 1, endurance = 4 },
        armorer = { strength = 1, endurance = 4, personality = 2 },
        mediumarmor = { endurance = 4, speed = 2, willpower = 1 },
        heavyarmor = { strength = 1, endurance = 4, speed = 2 },
        bluntweapon = { strength = 4, endurance = 1, willpower = 2 },
        longblade = { strength = 2, agility = 4, speed = 1 },
        axe = { strength = 4, agility = 2, willpower = 1 },
        spear = { strength = 4, endurance = 2, speed = 1 },
        athletics = { endurance = 2, speed = 4, willpower = 1 },

        enchant = { intelligence = 4, willpower = 2, personality = 1 },
        destruction = { intelligence = 2, willpower = 4, personality = 1 },
        alteration = { speed = 1, intelligence = 2, willpower = 4 },
        illusion = { agility = 1, intelligence = 2, personality = 4 },
        conjuration = { intelligence = 4, willpower = 1, personality = 2 },
        mysticism = { intelligence = 4, willpower = 2, personality = 1 },
        restoration = { endurance = 1, willpower = 4, personality = 2 },
        alchemy = { endurance = 1, intelligence = 4, personality = 2 },
        unarmored = { endurance = 1, speed = 4, willpower = 2 },

        security = { agility = 4, intelligence = 2, personality = 1 },
        sneak = { agility = 4, speed = 1, personality = 2 },
        acrobatics = { strength = 1, agility = 2, speed = 4 },
        lightarmor = { agility = 1, endurance = 2, speed = 4 },
        shortblade = { agility = 4, speed = 2, personality = 1 },
        marksman = { strength = 4, agility = 2, speed = 1 },
        mercantile = { intelligence = 2, willpower = 1, personality = 4 },
        speechcraft = { intelligence = 1, willpower = 2, personality = 4 },
        handtohand = { strength = 4, agility = 2, endurance = 1 }
    },

    -- How attributes contribute to total health
    healthAttributeFactors = {
        endurance = 4 / 7,
        strength = 2 / 7,
        willpower = 1 / 7,
    },

    -- Skills won't decay below that value
    -- skillMaxLevel is the highest level the skill reached before decay
    decayMinSkill = function(skillMaxLevel)
        return math.max(15, math.ceil(skillMaxLevel / 2))
    end,

    -- How many hours it takes for a skill level 100 to decay with slow decay, if that skill is never used
    -- Decay of a skill level 33 increases 3 times slower than a skill level 100
    -- With standard decay, the decay passed time increases twice faster than with slow decay
    -- With fast decay, the decay passed time increases twice faster than with standard decay
    decayTimeBaseInHours = 336, -- 2 week

    -- Recovering skill lost levels is at least 4 time faster than normal skill gains
    -- Set the return to 1 for no boost
    decayLostLevelsSkillGainFact = function(skillLostLevels)
        return 4 * skillLostLevels ^ 0.5
    end,

    -- Each time a skill is used, its decay progress is slowed down by subtracting hours to decay time passed
    decayRecoveredHoursPerSkillUsed = 1,

    -- Other skills from same specialization will also get their decay slowed down by a fraction of current skill reduction
    -- For instance, using lock pick will, skill gain 2.0, and decayRecoveredHoursPerSkillUsed = 1
    --   will remove 2 * 1 = 2 hours to lock pick decay passed time,
    --   and will remove 2 / 20 = 0.1 hours (6 minutes) to all other stealth skills
    -- Set it to 0 to disable the synergy
    decayRecoveredHoursPerSkillUsedSynergyFactor = 1 / 20,

    -- When a skill is trained, the passed 2 hours won't after its decay progress
    -- Other skills from same specialization can benefit from a progress reduction
    -- Set to 1 for no reduction, 0 for no decay progress
    decayReducedHoursPerSkillTrainedSynergyFactor = 1 / 2,

    -- When a skill levels up, the decay progress is reduced by a factor to prevent having a decay just after a level up
    -- Set it to 0 to reset the decay progress on levels up
    slowDownSkillDecayOnSkillLevelUpFactor = 0.5,

    -- When resting in a bed, change the decay time passed by a factor
    decayRestWithBedTimePassedFactor = 0,

    -- When resting without a bed, change the decay time passed by a factor (only openmw 0.49)
    decayRestWithoutBedTimePassedFactor = 1 / 2,

    -- When traveling with a transport, change the decay time passed by a factor
    decayTransportTimePassedFactor = 1 / 2,

    -- With openmw48, when resting, waiting or training a skill, change the decay time passed by a factor
    decayRestOrWaitOrTrainTimePassedFactorV48 = 1 / 2,
}

config.updateConfig = function(configuration)
    H.overrideTableValues(config, configuration)
end

-- Get configuration data, excluding functions
config.getData = function()
    local data = {}
    for k, v in pairs(config) do
        if type(v) ~= "function" then
            data[k] = v
        end
    end
    return data
end

config.setSkillsImpactOnAttributes = function(skillId, primaryAttrId, secondaryAttrId, tertiaryAttrId)
    local changed = config.skillsImpactOnAttributes[skillId][primaryAttrId] ~= 4
            or config.skillsImpactOnAttributes[skillId][secondaryAttrId] ~= 2
            or config.skillsImpactOnAttributes[skillId][tertiaryAttrId] ~= 1
    config.skillsImpactOnAttributes[skillId] = { [primaryAttrId] = 4, [secondaryAttrId] = 2, [tertiaryAttrId] = 1 }
    return changed
end

return config