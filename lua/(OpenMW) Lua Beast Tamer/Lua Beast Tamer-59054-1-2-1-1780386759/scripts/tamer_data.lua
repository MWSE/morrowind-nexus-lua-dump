local types = require("openmw.types")

return {
    BLUNT_TYPES = {
        [types.Weapon.TYPE.BluntOneHand]  = true,
        [types.Weapon.TYPE.BluntTwoClose] = true,
        [types.Weapon.TYPE.BluntTwoWide]  = true,
    },

    -- attributes that get boosted on player level-up. strength agility endurance are basically useless and create a lot of problems when calculating fatigue so screw them
    BOOST_ATTRIBUTES = {
        "speed",
        "willpower",
        "luck",
    },

    -- PEACEFUL TAMING

    -- a creature with modified fight above this ignores dropped food
    PEACEFUL_FIGHT_MAX  = 75,
    -- how close a creature must be to notice dropped food
    PEACEFUL_DETECT_DIST = 300,
    PEACEFUL_HEIGHT_GAP  = 100,

    PEACEFUL_ROLL = {
        BASE                  = 20,
        LEVEL_WEIGHT          = 1.5,
        PERSONALITY_WEIGHT    = 0.15,
        WILLPOWER_WEIGHT      = 0.1,
        LUCK_WEIGHT           = 0.1,
        CREATURE_LEVEL_WEIGHT = 3,
        MIN_CHANCE            = 5,
        MAX_CHANCE            = 95,
    },
}