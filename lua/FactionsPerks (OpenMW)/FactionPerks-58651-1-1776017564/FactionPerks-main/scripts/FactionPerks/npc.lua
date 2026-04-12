local I = require('openmw.interfaces')
local types      = require('openmw.types')

require("scripts.FactionPerks.shared")

-- ============================================================
--  COMBAT HIT HANDLER
--  Processes all incoming hits. Order matters:
--    1. Redoran damage negation is checked first - if the hit
--       is negated there is no point applying lifesteal.
--    2. MT lifesteal only fires if the hit was not negated.
-- ============================================================

I.Combat.addOnHitHandler(function(attack)
     DoMT4Attack(attack)
end)

return {
    eventHandlers = {
        playerSneaking = UpdatePlayerSneakStatus,
    }
}
