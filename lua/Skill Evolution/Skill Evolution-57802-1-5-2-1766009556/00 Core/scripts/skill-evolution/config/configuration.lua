local core = require('openmw.core')
local util = require('openmw.util')
local I = require('openmw.interfaces')

-- This file contains main configuration values and functions that are not configurable from the in-game settings page.
-- You can alter its content to change the mod balance

local Skills = core.stats.Skill.records
local UseTypes = I.SkillProgression and I.SkillProgression.SKILL_USE_TYPES

local config = {
    skillUseTypes = UseTypes and {
        [Skills.unarmored.id] = {
            [UseTypes.Armor_HitByOpponent] = { key = "HitByOpponent", gain = 1.25, vanilla = 1.0 },
        },
        [Skills.lightarmor.id] = {
            [UseTypes.Armor_HitByOpponent] = { key = "HitByOpponent", gain = 1.0, vanilla = 1.0 },
        },
        [Skills.mediumarmor.id] = {
            [UseTypes.Armor_HitByOpponent] = { key = "HitByOpponent", gain = 1.0, vanilla = 1.0 },
        },
        [Skills.heavyarmor.id] = {
            [UseTypes.Armor_HitByOpponent] = { key = "HitByOpponent", gain = 0.75, vanilla = 1.0 },
        },
        [Skills.handtohand.id] = {
            [UseTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 1.0 },
        },
        [Skills.axe.id] = {
            [UseTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 1.2 },
        },
        [Skills.bluntweapon.id] = {
            [UseTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 1.0 },
        },
        [Skills.longblade.id] = {
            [UseTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 1.0 },
        },
        [Skills.marksman.id] = {
            [UseTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 1.0 },
        },
        [Skills.shortblade.id] = {
            [UseTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 0.75 },
        },
        [Skills.spear.id] = {
            [UseTypes.Weapon_SuccessfulHit] = { key = "SuccessfulHit", gain = 0.75, vanilla = 1.0 },
        },
        [Skills.alteration.id] = {
            [UseTypes.Spellcast_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
        },
        [Skills.conjuration.id] = {
            [UseTypes.Spellcast_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
        },
        [Skills.destruction.id] = {
            [UseTypes.Spellcast_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
        },
        [Skills.illusion.id] = {
            [UseTypes.Spellcast_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
        },
        [Skills.mysticism.id] = {
            [UseTypes.Spellcast_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
        },
        [Skills.restoration.id] = {
            [UseTypes.Spellcast_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
        },
        [Skills.alchemy.id] = {
            [UseTypes.Alchemy_CreatePotion] = { key = "CreatePotion", gain = 2.0, vanilla = 2.0 },
            [UseTypes.Alchemy_UseIngredient] = { key = "UseIngredient", gain = 0.5, vanilla = 0.5 },
        },
        [Skills.enchant.id] = {
            [UseTypes.Enchant_Recharge] = { key = "Recharge", gain = 2.5, vanilla = 5.0 },
            [UseTypes.Enchant_UseMagicItem] = { key = "UseMagicItem", gain = 0.2, vanilla = 0.1 },
            [UseTypes.Enchant_CreateMagicItem] = { key = "CreateMagicItem", gain = 10.0, vanilla = 5.0 },
            [UseTypes.Enchant_CastOnStrike] = { key = "CastOnStrike", gain = 0.0, vanilla = 0.0 },
        },
        [Skills.block.id] = {
            [UseTypes.Block_Success] = { key = "Success", gain = 2.5, vanilla = 2.5 },
        },
        [Skills.armorer.id] = {
            [UseTypes.Armorer_Repair] = { key = "Repair", gain = 0.4, vanilla = 0.4 },
        },
        [Skills.athletics.id] = {
            [UseTypes.Athletics_RunOneSecond] = { key = "RunOneSecond", gain = 0.02, vanilla = 0.02 },
            [UseTypes.Athletics_SwimOneSecond] = { key = "SwimOneSecond", gain = 0.03, vanilla = 0.03 },
        },
        [Skills.acrobatics.id] = {
            [UseTypes.Acrobatics_Jump] = { key = "Jump", gain = 0.4, vanilla = 0.15 },
            [UseTypes.Acrobatics_Fall] = { key = "Fall", gain = 3.0, vanilla = 3.0 },
        },
        [Skills.security.id] = {
            [UseTypes.Security_DisarmTrap] = { key = "DisarmTrap", gain = 3, vanilla = 3.0 },
            [UseTypes.Security_PickLock] = { key = "PickLock", gain = 3, vanilla = 2.0 },
        },
        [Skills.sneak.id] = {
            [UseTypes.Sneak_AvoidNotice] = { key = "AvoidNotice", gain = 0.5, vanilla = 0.25 },
            [UseTypes.Sneak_PickPocket] = { key = "PickPocket", gain = 5.0, vanilla = 2.0 },
        },
        [Skills.mercantile.id] = {
            [UseTypes.Mercantile_Success] = { key = "Success", gain = 0.3, vanilla = 0.3 },
            [UseTypes.Mercantile_Bribe] = { key = "Bribe", gain = 1.0, vanilla = 1.0 },
        },
        [Skills.speechcraft.id] = {
            [UseTypes.Speechcraft_Success] = { key = "Success", gain = 1.0, vanilla = 1.0 },
            [UseTypes.Speechcraft_Fail] = { key = "Fail", gain = 0.0, vanilla = 0.0 },
        },
    },

    decayColor = util.color.rgb(0, 0.25, 1),
    decayBuffedColor = util.color.rgb(0, 0.75, 1),
    decayDamagedColor = util.color.rgb(0.5, 0.5, 1),

    -- Skills won't decay below that value
    -- skillMaxLevel is the highest level the skill reached before decay
    decayMinSkill = function(skillMaxLevel)
        return math.max(15, math.ceil(skillMaxLevel / 2))
    end,

    -- How many hours it takes for a skill level 100 to decay with very slow decay, if that skill is never used
    -- Decay of a skill level 33 increases 3 times slower than a skill level 100
    -- With standard decay, the decay passed time increases twice faster than with slow decay
    -- With fast decay, the decay passed time increases twice faster than with standard decay
    decayTimeBaseInHours = 336, -- 2 weeks

    -- Recovering skill lost levels is at least 4 time faster than normal skill gains
    -- Set the return to 1 for no boost
    decayLostLevelsSkillGainFact = function(skillLostLevels)
        return skillLostLevels > 0 and 4 * skillLostLevels ^ 0.5 or 1
    end,

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

    minScaledSkillGainPercent = 10,
    maxScaledSkillGainPercent = 200,
    athleticsGainMaxTime = 120,
    athleticsGainCurvePower = 1 / 3,
    jumpGainLandingRiskFactor = 2,
    jumpGainBottomFactor = 2,
    jumpGainLandingHeightFactor = 0.75,
    jumpGainLandingFallDamageMaxFactor = 1.25,
    jumpGainMaxMovementFactor = 0.1,
    jumpGainSlowFallDepthFactor = 0.5,
    jumpGainWaterFactor = 0.5,
    jumpGainLavaMaxBonus = 0.5,
    jumpDodgeFactor = 4,
    blockFactor = 4,
    scaledFatigueFactor = 0.5,

    maxFeatStats = 5,
}

return config