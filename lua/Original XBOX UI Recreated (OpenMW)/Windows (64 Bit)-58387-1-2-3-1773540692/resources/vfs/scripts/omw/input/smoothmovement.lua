local input = require('openmw.input')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')
local types = require('openmw.types')
local self = require('openmw.self')

local NPC = types.NPC

local moveActions = {
    'MoveForward',
    'MoveBackward',
    'MoveLeft',
    'MoveRight'
}
for _, key in ipairs(moveActions) do
    local smoothKey = 'Smooth' .. key
    input.registerAction {
        key = smoothKey,
        l10n = 'OMWControls',
        name = smoothKey .. '_name',
        description = smoothKey .. '_description',
        type = input.ACTION_TYPE.Range,
        defaultValue = 0,
    }
end

local settings = storage.playerSection('SettingsOMWControls')

local function shouldAlwaysRun(actor)
    return actor.controls.sneak or not NPC.isOnGround(actor) or NPC.isSwimming(actor)
end

local function remapToWalkRun(actor, inputMovement, allowRunning)
    if shouldAlwaysRun(actor) then
        return true, inputMovement
    end
    local normalizedInput, inputSpeed = inputMovement:normalize()
    if not allowRunning then
        return false, normalizedInput * math.min(1, inputSpeed)
    end
    local switchPoint = 0.5
    if inputSpeed < switchPoint then
        return false, inputMovement * 2
    else
        local matchWalkingSpeed = NPC.getWalkSpeed(actor) / NPC.getRunSpeed(actor)
        local runSpeedRatio = 2 * (inputSpeed - switchPoint) * (1 - matchWalkingSpeed) + matchWalkingSpeed
        return true, normalizedInput * math.min(1, runSpeedRatio)
    end
end

local function computeSmoothMovement()
    local controllerInput = util.vector2(
        input.getAxisValue(input.CONTROLLER_AXIS.MoveForwardBackward),
        input.getAxisValue(input.CONTROLLER_AXIS.MoveLeftRight)
    )
    local alwaysRun = settings:get('alwaysRun')
    local invertAlwaysRun = input.isActionPressed(input.ACTION.Run)
    local allowRunning = alwaysRun ~= invertAlwaysRun
    return remapToWalkRun(self, controllerInput, allowRunning)
end

local function bindSmoothMove(key, axis, direction)
    local smoothKey = 'Smooth' .. key
    input.bindAction(smoothKey, async:callback(function()
        local _, movement = computeSmoothMovement()
        return math.max(direction * movement[axis], 0)
    end), {})
    input.bindAction(key, async:callback(function(_, standardMovement, smoothMovement)
        if not settings:get('smoothControllerMovement') then
            return standardMovement
        end

        if smoothMovement > 0 then
            return smoothMovement
        else
            return standardMovement
        end
    end), { smoothKey })
end

bindSmoothMove('MoveForward', 'x', -1)
bindSmoothMove('MoveBackward', 'x', 1)
bindSmoothMove('MoveRight', 'y', 1)
bindSmoothMove('MoveLeft', 'y', -1)

input.bindAction('Run', async:callback(function(_, run)
    if not settings:get('smoothControllerMovement') then
        return run
    end
    local smoothRun, movement = computeSmoothMovement()
    if movement:length2() > 0 then
        -- playercontrols.lua computes the final run state as:
        --   self.controls.run = RunActionValue ~= settings.alwaysRun
        -- So here we convert the desired run state (from the joystick magnitude) into a Run action value.
        return smoothRun ~= settings:get('alwaysRun')
    else
        return run
    end
end), {})
