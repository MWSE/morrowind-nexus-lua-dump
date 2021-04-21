
local this = {}

local skillValues = {
    arrow = 0,
    bolt = 5,
    dart = 10,

    low = 5,
    lowP = 10,
    medium = 15,
    mediumP = 20,
    high = 25,
    highP = 30,
    veryHigh = 35,


    plume = 10,
    glass = 50
}


this.ammoTypes = {
    arrow = {
        handler = "arrows",
        description = "arrows",
        id = "arrow",
        craftCount = 20,
        skillReq = skillValues.arrow
    },
    bolt = {
        handler = "bolts",
        description = "bolts",
        id = "bolt",
        craftCount = 20,
        skillReq = skillValues.bolt
    },
    dart = {
        handler = "darts",
        description = "darts",
        id = "dart",
        craftCount = 10,
        skillReq = skillValues.dart
    }
}


this.materials = {
    plume = {
        id = "_plume",
        description = "Racer plume",
        ingredients = {
            { id = "ingred_racer_plumes_01", count = 1 },
        },
        skillReq = skillValues.plume
    },

    glass = {
        id = "_glass",
        description = "Glass",
        ingredients = {
            { id = "ingred_raw_glass_01", count = 1 },
        },
        skillReq = skillValues.glass
    }
}

this.enchantments = {
    fire = {
        id = "_fire_01",
        description = "enchanted with fire damage",
        ingredients = {
            { id = "ingred_fire_salts_01", count = 1 }
        },
        skillReq = skillValues.low
    },

    fireCruel = {
        id = "_fire_02",
        description = "enchanted with powerful fire damage",
        ingredients = {
            { id = "ingred_fire_salts_01", count = 2 }
        },
        skillReq = skillValues.medium
    },

    fireDire = {
        id = "_fire_03",
        description = "enchanted with very powerful fire damage",
        ingredients = {
            { id = "ingred_fire_salts_01", count = 3 }
        },
        skillReq = skillValues.high
    },

    frost = {
        id = "_frost_01",
        description = "enchanted with frost damage",
        ingredients = {
            { id = "ingred_frost_salts_01", count = 1 }
        },
        skillReq = skillValues.low
    },

    frostCruel = {
        id = "_frost_02",
        description = "enchanted with powerful frost damage",
        ingredients = {
            { id = "ingred_frost_salts_01", count = 2 }
        },
        skillReq = skillValues.medium
    },

    frostDire = {
        id = "_frost_03",
        description = "enchanted with very powerful frost damage",
        ingredients = {
            { id = "ingred_frost_salts_01", count = 3 }
        },
        skillReq = skillValues.high
    },

    shock = {
        id = "_shock_01",
        description = "enchanted with shock damage",
        ingredients = {
            { id = "ingred_scrap_metal_01", count = 1 }
        },
        skillReq = skillValues.low
    },

    shockCruel = {
        id = "_shock_02",
        description = "enchanted with powerful shock damage",
        ingredients = {
            { id = "ingred_scrap_metal_01", count = 2 }
        },
        skillReq = skillValues.medium
    },

    shockDire = {
        id = "_shock_03",
        description = "enchanted with very powerful shock damage",
        ingredients = {
            { id = "ingred_scrap_metal_01", count = 3 }
        },
        skillReq = skillValues.high
    },



    poison = {
        id = "_poison_01",
        description = "enchanted with poison damage",
        ingredients = {
            { id = "ingred_russula_01", count = 1 },
            { id = "ingred_coprinus_01", count = 1 },
        },
        skillReq = skillValues.lowP
    },

    poisonCruel = {
        id = "_poison_02",
        description = "enchanted with powerful poison damage",
        ingredients = {
            { id = "ingred_russula_01", count = 2 },
            { id = "ingred_coprinus_01", count = 2 },
        },
        skillReq = skillValues.mediumP
    },

    poisonDire = {
        id = "_poison_03",
        description = "enchanted with very powerful poison damage",
        ingredients = {
            { id = "ingred_russula_01", count = 3 },
            { id = "ingred_coprinus_01", count = 3 },
        },

        skillReq = skillValues.highP
    },

    --special

    paralyse = {
        id = "_paralyse_01",
        description = "that paralyze the target",
        ingredients = {
            { id = "ingred_bc_spore_pod", count = 1 },
        },
        skillReq = skillValues.mediumP
    },

    cupid = {
        id = "_cupid",
        description = "that calm the enemy",
        ingredients = {
            { id = "ingred_ruby_01", count = 1 },
        },
        skillReq = skillValues.highP
    },

    mageBain = {
        id = "_magebane",
        description = "that disorient spell casters",
        ingredients = {
            { id = "ingred_pearl_01", count = 1 },
        },
        skillReq = skillValues.medium
    },
    
    fury = {
        id = "_fury",
        description = "enchanted with explosive fire, frost and shock damage.",
        ingredients = {
            { id = "ingred_fire_salts_01", count = 1 },
            { id = "ingred_frost_salts_01", count = 1 },
            { id = "ingred_scrap_metal_01", count = 1 }
        },
        skillReq = skillValues.veryHigh
    }

}



return this
