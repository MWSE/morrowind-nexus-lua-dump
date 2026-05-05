-- ============================================================
-- StatCounters scrib watcher
-- This CREATURE script runs on every creature. On activation
-- by the player it checks if this creature is a known scrib,
-- and if so sends a ScribPetted event to the player so the
-- player script can count it.
-- ============================================================
local self   = require('openmw.self')
local T      = require('openmw.types')
local nearby = require('openmw.nearby')

local SCRIB_IDS = {
    ["scrib"]              = true,
    ["scrib diseased"]     = true,
    ["scrib_vaba-amus"]    = true,
    ["scrib blighted"]     = true,
    ["scrib_rerlas"]       = true,
    ["icescrib"]           = true,
    ["aa_cr_horned_scrib"] = true,
}

local function onActivated(actor)
    -- Only care about activations by a player
    if not T.Player.objectIsInstance(actor) then return end
    -- Only count known live scribs
    if not SCRIB_IDS[self.object.recordId] then return end
    if T.Actor.isDead(self.object) then return end
    -- Send event to the activating player's script
    actor:sendEvent("ScribPetted", {})
end

return {
    engineHandlers = {
        onActivated = onActivated,
    },
}
