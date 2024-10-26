local config = {

    -- INITIALIZATION

    -- Creatures will learn spells based on their level (an other factors): the higher the level, the more powerful the spell
    minCreatureLevelForSpellIndex = {
        20, -- spell huge
        10, -- spell high
        5, --  spell medium
        1, --  spell low
    },

    -- SHARED

    -- Frequency per second for checking changes on active AI package
    checkAiPackageRefreshTime = 1,

    -- WOUNDED

    -- Frequency per second for checking if a healer is needed
    checkNeedsHealerRefreshRate = 1,

    -- Frequency per second for checking if the touch healing spell is fully applied
    checkHealedFinishRefreshRate = 0.5,

    -- HEALER

    -- If a healer decline help but then the situation changes and healing chances increase
    -- then the healer should reconsider helping his partner
    -- newChances / oldChances have to be greater than this value to be considered as better chances
    betterChancesToBeHealedRatio = 1.05,

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

    -- Healing acceptance condition can be configured to have more or less impact
    -- A power is applied to the chance value (value is between 0 and 1)
    chanceImpacts = {
        impactNone = { power = 0 },
        impactLowest = { power = 1 / 8 },
        impactLower = { power = 1 / 4 },
        impactLow = { power = 1 / 2 },
        impactNormal = { power = 1 },
    }
}

return config