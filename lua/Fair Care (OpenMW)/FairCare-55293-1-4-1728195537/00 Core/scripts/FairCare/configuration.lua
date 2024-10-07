local T = require('openmw.types')

local config = {

    -- NPCs will learn a self and/or touch spell if its cost is below this ratio of their base magicka
    minUsedMagickaRatioToCastHeal = 0.5,

    -- Frequency per second for checking changes on active AI package
    checkAiPackageRefreshTime = 1,

    -- Actors will heal friends if their health goes under this ratio
    injuredEnoughRatio = 0.5,

    -- Frequency per second for checking if a healer is needed
    checkNeedsHealerRefreshRate = 1,

    -- Max time the wounded friend waits for potential healer answers
    healRequestMaxTime = 0.5,

    -- Max time the wounded friend waits before asking again to be healed
    timeBeforeAskingHealAgain = 2,

    -- Frequency per second for checking if the touch heal spell is fully applied
    checkHealedFinishRefreshRate = 1,

    -- Frequency per second to update healers' navigation path to reach their wounded friends
    updatePathRefreshRate = 1,

    -- Tolerance distance to validate a point in a navigation path towards the wounded friend
    distanceToPathPointTolerance = 20,

    -- Tolerance distance between the healer and the wounded to cast the touch heal spell
    -- Added to the bounding boxes half extents and the combat default distance
    -- Negative value to be closer and allow the wounded to move away while still being hit by the spell
    distanceToWoundedTolerance = -50,

    -- Creatures will learn spells based on their level (an other factors): the higher the level, the more powerful the spell
    minCreatureLevelForSpellIndex = {
        20, -- spell huge
        10, -- spell high
        5, --  spell medium
        1, --  spell low
    },
}

return config