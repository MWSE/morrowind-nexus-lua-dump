--[[
    Staves! — Config
    All tuning values for the Staves skill and its perk ladder.
]]

local config = {
    skillId = "staves_staves",
    startLevel = 5,
    maxLevel = 100,
    classBonus = 10,

    -- Window during which a released staff attack is considered valid
    -- for hit-side perk processing. Longer than Throwing's because
    -- melee swings can take a while to land.
    pendingWindow = 1.5,

    perks = {
        -- 25: Concussive Strike — chance-based bonus fatigue damage.
        concussive = {
            level = 25,
            chance = 0.40,
            fatigueAtUnlock = 8,
            fatigueAt100 = 20,
            sound = "Hand To Hand Hit",
        },
        -- 50: Arcane Siphon — chance on hit to drain magicka from the
        -- target and restore the same amount to the player.
        -- Targets with no magicka (many creatures) are unaffected.
        arcaneSiphon = {
            level = 50,
            chance = 0.15,
            drainAtUnlock = 10,
            drainAt100 = 25,
            restoreMultiplier = 1.0,
            sound = "mysticism cast",
        },
        -- 75: Resonant Conduit — rare but substantial enchantment-charge
        -- recovery on the wielded staff. Low trigger rate keeps it bursty
        -- instead of acting like a constant recharge trickle.
        resonantConduit = {
            level = 75,
            chance = 0.05,
            chargeAtUnlock = 25,
            chargeAt100 = 50,
            sound = "enchant success",
        },
        -- 100: Null Pulse — chance on hit to Silence the target briefly.
        -- The actor script applies the Silence effect locally and plays the
        -- Silence VFX/sound cue so the proc is readable with messages off.
        nullPulse = {
            level = 100,
            chance = 0.12,
            silenceDuration = 4,
            sound = "illusion hit",
        },
    },

    feedback = {
        concussive = "Concussive Strike!",
        arcaneSiphon = "Arcane Siphon!",
        resonantConduit = "Resonant Conduit! (charge restored)",
        nullPulse = "Null Pulse! (silenced)",
    },
}

return config
