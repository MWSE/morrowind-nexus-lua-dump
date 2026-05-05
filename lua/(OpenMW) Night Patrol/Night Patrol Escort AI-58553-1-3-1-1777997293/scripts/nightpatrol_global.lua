local types = require('openmw.types')
local I     = require('openmw.interfaces')

local function onReturnGuard(data)
    local guard = data.guard
    if not guard or not guard:isValid() then return end
    if types.Actor.isDead(guard) then return end
    local cellName = data.cellName
    local pos      = data.position
    if not pos then return end
    guard:teleport(cellName or '', pos)
    -- clear any leftover mod AI so vanilla Wander resumes
    guard:sendEvent('RemoveAIPackages', 'Travel')
end

local function onTrespass(data)
    if not data or not data.player or not data.player:isValid() then return end
    local arg = {
        type = types.Player.OFFENSE_TYPE.Trespassing,
    }
    if data.guard and data.guard:isValid() then
        arg.victim = data.guard
    end
    local result = I.Crimes.commitCrime(data.player, arg)

    -- tell the player script whether the crime was actually seen
    if data.player:isValid() then
        data.player:sendEvent('NightPatrol_TrespassResult', {
            seen = result and result.wasCrimeSeen or false,
        })
    end
end

return {
    eventHandlers = {
        NightPatrol_ReturnGuard = onReturnGuard,
        NightPatrol_Trespass    = onTrespass,
    },
}