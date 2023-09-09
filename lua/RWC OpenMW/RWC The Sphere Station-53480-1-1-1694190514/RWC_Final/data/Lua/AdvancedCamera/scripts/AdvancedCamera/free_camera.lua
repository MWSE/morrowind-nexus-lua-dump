local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
local ui = require('openmw.ui')
local self = require('openmw.self')
local util = require('openmw.util')

local middleButtonWasPressed = false
local savedMode = nil
local controlPlayer = false
local moveUp = 0

local function update(dt, enabled)
    if core.isWorldPaused() then return end
    local middleButtonPressed = input.isMouseButtonPressed(2)
    if (enabled and middleButtonPressed and not middleButtonWasPressed) or (savedMode and not enabled) then
        if savedMode then
            camera.setMode(savedMode)
            savedMode = nil
            ui.showMessage('Free camera is off')
        else
            savedMode = camera.getMode()
            if savedMode == camera.MODE.Static then
                savedMode = nil
            else
                camera.setMode(camera.MODE.Static)
                ui.showMessage('Free camera is on')
            end
        end
    end
    middleButtonWasPressed = middleButtonPressed

    if camera.getMode() == camera.MODE.Static and savedMode then
        camera.showCrosshair(false)
        camera.setExtraPitch(0)
        camera.setExtraYaw(0)
        camera.setExtraRoll(0)
        if not controlPlayer then
            self.controls.jump = false
            self.controls.movement = 0
            self.controls.sideMovement = 0
            self.controls.yawChange = 0
            self.controls.pitchChange = 0

            camera.setPitch(camera.getPitch() + input.getMouseMoveY() * 0.005)
            camera.setYaw(camera.getYaw() + input.getMouseMoveX() * 0.005)
            camera.setRoll(0)

            local moveForward = 0
            local moveRight = 0
            if input.isActionPressed(input.ACTION.MoveForward) then moveForward = moveForward + dt end
            if input.isActionPressed(input.ACTION.MoveBackward) then moveForward = moveForward - dt end
            if input.isActionPressed(input.ACTION.MoveLeft) then moveRight = moveRight - dt end
            if input.isActionPressed(input.ACTION.MoveRight) then moveRight = moveRight + dt end
            local offset = util.transform.rotateZ(camera.getYaw()) * util.vector3(moveRight * 150, moveForward * 150, moveUp * 10)
            camera.setStaticPosition(camera.getPosition() + offset)
            moveUp = 0
        end
    end
end

return {
    onFrame = update,
    onInputAction = function(action)
        if core.isWorldPaused() or not savedMode then return end
        if action == input.ACTION.TogglePOV then
            controlPlayer = not controlPlayer
            if controlPlayer then
                ui.showMessage('Free camera; player controls enabled')
            else
                ui.showMessage('Free camera; camera controls enabled')
            end
        end
        if not controlPlayer and action == input.ACTION.ZoomIn then moveUp = moveUp + 1 end
        if not controlPlayer and action == input.ACTION.ZoomOut then moveUp = moveUp - 1 end
    end,
}

