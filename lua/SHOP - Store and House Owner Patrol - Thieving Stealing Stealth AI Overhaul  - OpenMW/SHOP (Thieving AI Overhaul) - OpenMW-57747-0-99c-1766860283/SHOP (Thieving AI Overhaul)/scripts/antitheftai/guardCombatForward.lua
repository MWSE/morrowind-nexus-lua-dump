-- Local script, runs on the guard himself
local self  = require('openmw.self')
local core  = require('openmw.core')
local I     = require('openmw.interfaces')   -- S3-Combat lives here

local lastCombat = false            -- were we in combat with the player last update?

-- utility: true if *this* actor is currently attacking the player
local function isFightingPlayer()
    local targets = I.s3lf.combatTargets          -- list supplied by S3 library
    if not targets then return false end
    for _, t in ipairs(targets) do
        if t.type == require('openmw.types').Player then
            return true
        end
    end
    return false
end

return {
    engineHandlers = {
        onUpdate = function()
            local now = isFightingPlayer()

            -- just entered combat with the player
            if now and not lastCombat then
                core.sendGlobalEvent('S3CombatTargetAdded', { id = self.id })
            -- just left combat with the player
            elseif (not now) and lastCombat then
                core.sendGlobalEvent('S3CombatTargetRemoved', { id = self.id })
            end
            lastCombat = now
        end
    }
}
