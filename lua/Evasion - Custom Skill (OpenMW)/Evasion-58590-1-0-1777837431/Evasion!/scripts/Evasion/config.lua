--[[
    Evasion! — Config
    All tuning values for the Evasion skill and its perk ladder.
]]

local config = {
    skillId = "evasion_evasion",
    startLevel = 5,
    maxLevel = 100,
    classBonus = 10,

    -- Limits on riposte health damage so big-weapon NPCs can't get nuked
    -- when the player has very high Evasion.
    riposteMaxHealthDamage = 40,
    riposteMinHealthDamage = 1,

    ashSandSpellId = "evasion_ash_sand_blind",
    vanishSelfSpellId = "evasion_vanish_self",
    vanishCalmSpellId = "evasion_vanish_calm",

    perks = {
        -- Level 25: Dodging while tired has a modest chance to restore
        -- a meaningful fatigue burst.
        secondWind = {
            level = 25,
            fatigueThreshold = 0.5,
            chanceAtUnlock = 0.25,
            chanceAt100 = 0.35,
            restoreAtUnlock = 20,
            restoreAt100 = 20,
            cooldown = 10.0,
        },
        -- Level 50: Rarely redirect a portion of the dodged attacker's
        -- intended damage back to them as health damage.
        riposte = {
            level = 50,
            chanceAtUnlock = 0.10,
            chanceAt100 = 0.20,
            fractionAtUnlock = 0.35,
            fractionAt100 = 0.45,
            sound = "Health Damage",
        },
        -- Level 75: Throw pocket ash in the attacker's eyes on a successful dodge.
        ashSand = {
            level = 75,
            chanceAtUnlock = 0.35,
            chanceAt100 = 0.50,
            blindMagnitude = 50,
            blindDuration = 5,
            cooldown = 8.0,
            sound = "mysticism cast",
        },
        -- Level 100: Disappear from the fight for a few seconds.
        vanish = {
            level = 100,
            cooldown = 30.0,
            chameleonMagnitude = 100,
            chameleonDuration = 5,
            calmMagnitude = 100,
            calmDuration = 5,
            sound = "illusion cast",
        },
    },

    feedback = {
        secondWind = "Second Wind!",
        riposte = "Riposte!",
        ashSand = "Pocket Ash!",
        vanish = "Vanish!",
    },
}

return config
