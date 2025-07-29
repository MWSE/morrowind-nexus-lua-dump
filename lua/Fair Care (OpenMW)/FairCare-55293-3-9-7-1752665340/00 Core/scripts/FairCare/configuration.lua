local config = {

    -- INITIALIZATION

    -- Minimum casting chances, with full fatigue, to gain a healing spell
    minCastChancesToGainSpell = 0.85,

    -- Creatures will learn spells based on their level (an other factors): the higher the level, the more powerful the spell
    minCreatureLevelForSpellIndex = {
        1, --  spell lower
        5, --  spell low
        10, -- spell medium
        15, -- spell high
        20, -- spell higher
    },

    -- SHARED

    -- Frequency per second to update actors' animation timers
    checkAnimationRefreshRate = 0.5,

    -- Frequency per second for checking changes on active AI package
    checkAiPackageRefreshTime = 1,

    -- WOUNDED

    -- Frequency per second for checking if a healer is needed
    checkNeedsHealerRefreshRate = 1,

    -- Frequency per second for checking if the actor is being healed (has a restore health effect)
    checkBeingHealedRefreshRate = 0.1,

    -- When an actor's current health over total is under this ratio, and the actor has healing equipment items, Fair Care will
    -- - Try to use a potion if any
    -- - Temporarily enable the AI if there are mods that disable AI (e.g. Mercy CAO), in order to let the engine use the healing items
    trySelfHealingItemHealthRatio = 0.5,
    -- Maximum time the default AI will be enabled if the AI doesn't use any self-healing item
    allowAiSelfHealMaxTime = 0.5,

    -- HEALER

    -- Delay, in seconds, to wait before checking if a cast animation is playing
    animationExistsMaxDelay = 2,

    -- If a healer accept help but then the situation changes and healing chances decrease to much
    -- then the healer should reconsider helping his partner
    minNewChancesToContinueHealingRatio = 0.9,

    -- If a healer is stuck (cause of other actors) he will stop healing
    -- Frequency at which we save actor location
    saveLastTravelPointsRate = 0.5,
    -- Number of actor locations to consider for computing average speed (3 means 2 intervals and 0.5 * 2 = 1 sec window)
    travelPointCountForSpeed = 3,
    -- Minimum speed ratio to continue healing. Ratio is (current speed) / (max run speed)
    minSpeedRatioToContinueHealing = 0.2,

    -- Frequency per second to update healers' action data (navigation path, chances to continue healing)
    updateActionRefreshRate = 0.5,

    -- Tolerance distance to validate a point in a navigation path towards the wounded partner
    distanceToPathPointTolerance = 20,
    -- Tolerance distance between the healer and the wounded to cast the touch healing spell
    -- Added to the bounding boxes half extents and the combat default distance
    -- Negative value to be closer and allow the wounded to move away while still being hit by the spell
    distanceToWoundedTolerance = -50,

    -- When self-healing, actors move away to avoid blows
    minEscapePathSegment = 200,
    maxEscapePathSegment = 500,
    maxEscapeTime = 3,
    -- When an escape point is proposed, the engine will try to find a valid navigation point within an area defined by a maximum radius
    validPointSearchRadius = 100,

    -- Healing acceptance condition can be configured to have more or less impact
    -- A power is applied to the chance value (value is between 0 and 1)
    chanceImpacts = {
        impactNone = { power = 0 },
        impactLowest = { power = 1 / 8 },
        impactLower = { power = 1 / 4 },
        impactLow = { power = 1 / 2 },
        impactNormal = { power = 1 },
    },
}

return config