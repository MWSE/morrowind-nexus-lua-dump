local I = require('openmw.interfaces')
local types = require('openmw.types')
local pself = require('openmw.self')

require("scripts.FactionPerks.shared")

-- ============================================================
--  COMBAT HIT HANDLER
--  Processes incoming hits on NPCs from the player.
--  MT lifesteal (FPerks_DoMT4Attack) fires on successful
--  sneaking weapon attacks against NPCs.
--  IC Divine Smite (FPerks_DoICSmite) fires on weapon hits
--  against undead, daedra, and vampire NPC targets.
--  Strength of the Redoran is a separate player-side effect
--  and has no interaction here.
-- ============================================================

I.Combat.addOnHitHandler(function(attack)
    FPerks_DoMT4Attack(attack)
    FPerks_DoICSmite(attack)
end)

local function takeDamage(data)
    local health = types.Actor.stats.dynamic.health(pself)
    health.current = health.current - data.amount
end

return {
    eventHandlers = {
        playerSneaking = FPerks_UpdatePlayerSneakStatus,
        FPerks_TakeDamage = takeDamage,
    }
}
