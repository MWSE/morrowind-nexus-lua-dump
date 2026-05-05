local config = {
    skillId = 'throwing',
    startLevel = 5,
    maxLevel = 100,
    classBonus = 10,

    -- Window during which a released throw is considered valid for XP redirect
    -- and hit-side perk processing.
    pendingWindow = 2.5,

    -- A small amount of native Marksman carries over into Throwing.
    marksmanTransferFactor = 0.20,
    marksmanTransferCap = 15,

    -- Effective-Marksman override while a thrown weapon is equipped.
    effectiveMarksmanCap = 100,

    xp = {
        hit = 1.00,
        crit = 0.35,
        heavyHit = 1.20,
        heavyWeight = 8.0,
    },

    combat = {
        skillDamageBonusAt100 = 0.30,
        strengthDamageBonusAt100 = 0.18,
        lightWeightThreshold = 2.0,
        heavyWeightThreshold = 12.0,
        heavyWeightPenaltyAt100Strength = 0.10,
        heavyWeightPenaltyAt0Strength = 0.35,

        -- Throwing should feel more dangerous up close than bows.
        shortRangeFullDistance = 450,
        shortRangeMaxDistance = 1200,
        shortRangeBonusAtFull = 0.25,
        shortRangeFeedbackThreshold = 0.03,

        -- Wind-up speed multiplier applied to thrown-weapon attack release animations.
        throwWindupSpeedAt0 = 1.12,
        throwWindupSpeedAt100 = 1.30,
        throwWindupWeightPenalty = 0.08,
        throwWindupFeedbackThreshold = 0.03,

        -- Throwing should not collapse to vanilla minimum damage on low-charge throws.
        -- Light projectiles get the highest low-charge floor so spam-throwing
        -- feels distinct from bow draw timing.
        quickThrowDamageFloorLight = 0.70,
        quickThrowDamageFloorHeavy = 0.44,
        quickThrowDamageFloorSkillBonusAt100 = 0.10,
        throwChargeExponent = 0.70,
        throwFullChargeCap = 0.85,
    },

    perks = {
        critical = {
            level = 25,
            -- Independent Throwing crit roll. This is intentionally not tied to
            -- Bullseye headshots and does not scale with skill after unlock.
            chance = 0.05,
            damageMultiplier = 1.40,
            sound = 'critical damage',
        },
        twinFlight = {
            level = 50,
            chanceAtUnlock = 0.08,
            chanceAt100 = 0.18,
            damageMultiplier = 2.0,
            extraHitSound = 'health damage',
            extraHitDelay = 0.20,
        },
        bleed = {
            level = 75,
            chanceAtUnlock = 0.10,
            chanceAt100 = 0.22,
            magnitudeMin = 1,
            magnitudeMax = 3,
            duration = 3,
            sound = 'health damage',
        },
        paralyze = {
            level = 100,
            chanceAtUnlock = 0.08,
            chanceAt100 = 0.08,
            baseDuration = 2,
            bonusDurationAt100 = 0,
        },
    },

    feedback = {
        critical = 'Critical throw!',
        twinFlight = 'Twinned throw!',
        bleed = 'Bleeding throw!',
        paralyze = 'Paralyzing throw!',
    },
}

return config
