local core = require('openmw.core')
local I = require('openmw.interfaces')

-- This file contains main configuration values and functions that are not configurable from the in-game settings page.
-- You can alter its content to change the mod balance

local H = require('scripts.NCGDMW.helpers')

local skills = core.stats.Skill.records
local useTypes = I.SkillProgression.SKILL_USE_TYPES

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

    skillUseTypes = {
        [skills.unarmored.id] = {
            [useTypes.Armor_HitByOpponent] = { key = "HitByOpponent", gain = 1.25, vanilla = 1.0 },
        },
        [skills.lightarmor.id] = {
            [useTypes.Armor_HitByOpponent] = { key = "HitByOpponent", gain = 1.00, vanilla = 1.0 },
        },
        [skills.mediumarmor.id] = {
            [useTypes.Armor_HitByOpponent] = { key = "HitByOpponent", gain = 1.00, vanilla = 1.0 },
        },
        [skills.heavyarmor.id] = {
            [useTypes.Armor_HitByOpponent] = { key = "HitByOpponent", gain = 0.75, vanilla = 1.0 },
        },
        [skills.handtohand.id] = {
            [useTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 1.0 },
        },
        [skills.axe.id] = {
            [useTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 1.2 },
        },
        [skills.bluntweapon.id] = {
            [useTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 1.0 },
        },
        [skills.longblade.id] = {
            [useTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 1.0 },
        },
        [skills.marksman.id] = {
            [useTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 1.0 },
        },
        [skills.shortblade.id] = {
            [useTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 0.75 },
        },
        [skills.spear.id] = {
            [useTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 1.0 },
        },
        [skills.alteration.id] = {
            [useTypes.Spellcast_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
        },
        [skills.conjuration.id] = {
            [useTypes.Spellcast_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
        },
        [skills.destruction.id] = {
            [useTypes.Spellcast_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
        },
        [skills.illusion.id] = {
            [useTypes.Spellcast_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
        },
        [skills.mysticism.id] = {
            [useTypes.Spellcast_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
        },
        [skills.restoration.id] = {
            [useTypes.Spellcast_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
        },
        [skills.alchemy.id] = {
            [useTypes.Alchemy_CreatePotion] = { key = "CreatePotion", gain = 2.0, vanilla = 2.0 },
            [useTypes.Alchemy_UseIngredient] = { key = "UseIngredient", gain = 0.5, vanilla = 0.5 },
        },
        [skills.enchant.id] = {
            [useTypes.Enchant_Recharge] = { key = "Recharge", gain = 2.5, vanilla = 5.0 },
            [useTypes.Enchant_UseMagicItem] = { key = "UseMagicItem", gain = 0.2, vanilla = 0.1 },
            [useTypes.Enchant_CreateMagicItem] = { key = "CreateMagicItem", gain = 10.0, vanilla = 5.0 },
            [useTypes.Enchant_CastOnStrike] = { key = "CastOnStrike", gain = 0.05, vanilla = 0.0 },
        },
        [skills.block.id] = {
            [useTypes.Block_Success] = { key = "Success", gain = 2.5, vanilla = 2.5 },
        },
        [skills.armorer.id] = {
            [useTypes.Armorer_Repair] = { key = "Repair", gain = 0.75, vanilla = 0.4 },
        },
        [skills.athletics.id] = {
            [useTypes.Athletics_RunOneSecond] = { key = "RunOneSecond", gain = 0.02, vanilla = 0.02 },
            [useTypes.Athletics_SwimOneSecond] = { key = "SwimOneSecond", gain = 0.03, vanilla = 0.03 },
        },
        [skills.acrobatics.id] = {
            [useTypes.Acrobatics_Jump] = { key = "Jump", gain = 0.1, vanilla = 0.15 },
            [useTypes.Acrobatics_Fall] = { key = "Fall", gain = 3.0, vanilla = 3.0 },
        },
        [skills.security.id] = {
            [useTypes.Security_DisarmTrap] = { key = "DisarmTrap", gain = 2.5, vanilla = 3.0 },
            [useTypes.Security_PickLock] = { key = "PickLock", gain = 2.5, vanilla = 2.0 },
        },
        [skills.sneak.id] = {
            [useTypes.Sneak_AvoidNotice] = { key = "AvoidNotice", gain = 0.5, vanilla = 0.25 },
            [useTypes.Sneak_PickPocket] = { key = "PickPocket", gain = 5.0, vanilla = 2.0 },
        },
        [skills.mercantile.id] = {
            [useTypes.Mercantile_Success] = { key = "Success", gain = 0.3, vanilla = 0.3 },
            [useTypes.Mercantile_Bribe] = { key = "Bribe", gain = 1.0, vanilla = 1.0 },
        },
        [skills.speechcraft.id] = {
            [useTypes.Speechcraft_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
            [useTypes.Speechcraft_Fail] = { key = "Fail", gain = 0.0, vanilla = 0.0 },
        },
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

    -- When resting without a bed, change the decay time passed by a factor
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