local anim = require('openmw.animation')
local self = require('openmw.self')

local MAX_ANIM_SPEED = 4.0 -- animation speed multiplier at 100 Magnitude

return {
    onUpdate = function(_, magnitude)
        if magnitude <= 0 then return end
        local speedMult = 1 + (magnitude / 100 * (MAX_ANIM_SPEED - 1))
        anim.setSpeed(self, 'spellcast', speedMult)
    end,
}