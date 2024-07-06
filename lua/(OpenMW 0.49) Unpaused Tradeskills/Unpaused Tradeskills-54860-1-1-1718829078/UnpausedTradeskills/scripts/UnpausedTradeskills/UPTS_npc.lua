local self = require('openmw.self')
local util = require('openmw.util')

local dialogTarget = nil
local turningToTarget = false

local function onUpdate(dt)
    if dialogTarget then
        self.controls.movement = 0
        self.controls.sideMovement = 0
        local deltaPos = dialogTarget.position - self.position
        local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(self.rotation:getYaw())
        local deltaYaw = math.atan2(destVec.x, destVec.y)
        if math.abs(deltaYaw) < math.rad(10) then
            turningToTarget = false
        elseif math.abs(deltaYaw) > math.rad(30) then
            turningToTarget = true
        end
        if turningToTarget then
            self.controls.yawChange = util.clamp(deltaYaw, -dt * 2.5, dt * 2.5)
        else
            self.controls.yawChange = 0
        end
    end
end

return {
    eventHandlers = {
        UnpausedTradeskills_StartDialog = function(player) dialogTarget = player end,
        UnpausedTradeskills_StopDialog = function() dialogTarget = nil end,
    },
    engineHandlers = {
        onUpdate = onUpdate,
    },
}

