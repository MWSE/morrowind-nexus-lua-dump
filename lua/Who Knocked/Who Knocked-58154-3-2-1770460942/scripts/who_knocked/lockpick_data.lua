-- Lockpick Data Table
-- Separates all lockpick-related data from logic
-- Following architectural rule: separate data wherever possible

local lockpickData = {
    -- Door difficulty ratings for different lockpick methods
    doorTypes = {
        shack = {
            strength = 30,
            security = 20,
            magic = 25,
            name = "Shack Door"
        },
        house = {
            strength = 40,
            security = 30,
            magic = 35,
            name = "House Door"
        },
        manor = {
            strength = 60,
            security = 50,
            magic = 40,
            name = "Manor Door"
        },
        vault = {
            strength = 80,
            security = 90,
            magic = 70,
            name = "Vault Door"
        },
        shop = {
            strength = 45,
            security = 40,
            magic = 30,
            name = "Shop Door"
        },
        guild = {
            strength = 55,
            security = 45,
            magic = 50,
            name = "Guild Door"
        },
        temple = {
            strength = 50,
            security = 35,
            magic = 60,
            name = "Temple Door"
        },
        tavern = {
            strength = 40,
            security = 25,
            magic = 30,
            name = "Tavern Door"
        },
        generic = {
            strength = 35,
            security = 25,
            magic = 30,
            name = "Generic Door"
        }
    },
    
    -- Success chance modifiers for each method
    chanceModifiers = {
        force = 0.7,      -- 70% max success rate
        pick = 0.6,       -- 60% max success rate
        magic = 0.8,      -- 80% max success rate
        master = 0.75    -- 75% max success rate
    },
    
    -- Messages for success and failure
    messages = {
        force = {
            success = "You force the door open with your strength!",
            fail = "The door resists your strength."
        },
        pick = {
            success = "Your lockpick skill opens the lock!",
            fail = "The lock proves too complex for your skills."
        },
        magic = {
            success = "Your alteration spell unlocks the door!",
            fail = "The magical resistance is too strong."
        },
        master = {
            success = "Your combined expertise opens the door!",
            fail = "The door defeats all your attempts."
        }
    },
    
    -- Skill names for display
    skillNames = {
        strength = "Strength",
        security = "Security",
        alteration = "Alteration"
    }
}

return lockpickData
