local types = require('openmw.types')
local I     = require('openmw.interfaces')

return {
    eventHandlers = {
        NightPatrol_ReturnGuard = function(data)
            local guard = data.guard
            if not guard or not guard:isValid() then return end
            if types.Actor.isDead(guard) then return end
            local cellName = data.cellName
            local pos      = data.position
            if not pos then return end
            guard:teleport(cellName or '', pos)
            -- clear any leftover mod AI so vanilla Wander resumes
            guard:sendEvent('RemoveAIPackages', 'Travel')
        end,

        NightPatrol_Trespass = function(data)
            if not data or not data.player or not data.player:isValid() then return end
            local arg = {
                type = types.Player.OFFENSE_TYPE.Trespassing,
                victimAware = true,
            }
            if data.guard and data.guard:isValid() then
                arg.victim = data.guard
            end
            I.Crimes.commitCrime(data.player, arg)
        end,
    },
}