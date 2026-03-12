local I = require('openmw.interfaces')

return {
    eventHandlers = {
        ApplyFireHit = function(data)
            I.Combat.onHit({
                sourceType = I.Combat.ATTACK_SOURCE_TYPES.Magic,
                damage     = { health = data.damage },
                successful = true,
                strength   = 1,
            })
        end,
    },
}