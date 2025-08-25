--[[
    Photo Mode for OpenMW 0.49 RC7 by TrackpadTimmy
    Adds free-cam movement, time freeze toggle, and tilt/zoom.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

--[[
1.3 changes
add deadzone function for gamepad users to prevent stick drift from spinning out of control
add configurable deadzone values in settings
]]

--[[
TODO:
add on screen window showing current zoom and tilt angles
add a button to toggle visibility of the player
Dynamic Camera Effects compatibility
  cant tilt camera while unpaused [caused by handleCamRoll() in DynamicCamera.lua]
  cant zero out roll effects from looking/strafing when entering photo mode
]]

if require('openmw.core').API_REVISION < 72 then
    error("This mod requires a new version of OpenMW, please update.")
end

local core = require('openmw.core')
local camera = require('openmw.camera')
local input = require('openmw.input')
local self = require('openmw.self')
local util = require('openmw.util')
local storage = require('openmw.storage')
local async = require('openmw.async')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local postprocessing = require('openmw.postprocessing')
local shaderHexDoF = postprocessing.load('HexDoFPhotoMode')
local ModInfo = require('scripts.PhotoMode.ModInfo')

local scriptVersion = ModInfo.version

local photoModeOn = false
local paused = false

local MIN_FOV = math.rad(10)
local MAX_FOV = math.rad(160)

local startingCameraMode = camera.MODE.FirstPerson
local startingCameraFOV = 75
local startingCameraPos = nil
local startingCameraPitch = 0
local startingCameraYaw = 0
local startingCameraRoll = 0
local startingSimulationTimeScale = 1

local lastRealTime = core.getRealTime()

local controlSwitches = {
    Controls = types.Player.CONTROL_SWITCH.Controls,
    Fighting = types.Player.CONTROL_SWITCH.Fighting,
    Jumping = types.Player.CONTROL_SWITCH.Jumping,
    Magic = types.Player.CONTROL_SWITCH.Magic,
    VanityMode = types.Player.CONTROL_SWITCH.VanityMode,
    ViewMode = types.Player.CONTROL_SWITCH.ViewMode,
}
-- Looking = types.Player.CONTROL_SWITCH.Looking,

local startingControlStates = {}

local enableStorageKey = storage.playerSection('Settings/' .. ModInfo.name .. '/Enable')
local keybindsStorageKey = storage.playerSection('Settings/' .. ModInfo.name .. '/Keybinds')
local generalStorageKey = storage.playerSection('Settings/' .. ModInfo.name .. '/General')

local enableMod = enableStorageKey:get('enableMod')
local CAMERA_MOVEMENT_SPEED = generalStorageKey:get('movementSpeed')
local CAMERA_ROLL_SPEED = math.rad(generalStorageKey:get('tiltSpeed'))
local CAMERA_ZOOM_SPEED = math.rad(generalStorageKey:get('zoomStep'))
local freezeTimeDefault = generalStorageKey:get('freezeTimeDefault')
local dofPhotoModeOnly = generalStorageKey:get('dofPhotoModeOnly')
local DEADZONE_THRESHOLD_RIGHT = generalStorageKey:get('deadzoneRight')
local DEADZONE_THRESHOLD_LEFT = generalStorageKey:get('deadzoneLeft')



local Actions = {
    {
        key = 'photoModeAction',
        type = input.ACTION_TYPE.Boolean,
        l10n = ModInfo.l10nName,
        name = 'Key:',
        description = '',
        defaultValue = false,
    },
    {
        key = 'freezeTimeAction',
        type = input.ACTION_TYPE.Boolean,
        l10n = ModInfo.l10nName,
        name = 'Key:',
        description = '',
        defaultValue = false,
    },
    {
        key = 'resetCameraAction',
        type = input.ACTION_TYPE.Boolean,
        l10n = ModInfo.l10nName,
        name = 'Key:',
        description = '',
        defaultValue = false,
    },
    {
        key = 'moveUpAction',
        type = input.ACTION_TYPE.Boolean,
        l10n = ModInfo.l10nName,
        name = 'Key:',
        description = '',
        defaultValue = false,
    },
    {
        key = 'moveDownAction',
        type = input.ACTION_TYPE.Boolean,
        l10n = ModInfo.l10nName,
        name = 'Key:',
        description = '',
        defaultValue = false,
    },
    {
        key = 'rollLeftAction',
        type = input.ACTION_TYPE.Boolean,
        l10n = ModInfo.l10nName,
        name = 'Key:',
        description = '',
        defaultValue = false,
    },
    {
        key = 'rollRightAction',
        type = input.ACTION_TYPE.Boolean,
        l10n = ModInfo.l10nName,
        name = 'Key:',
        description = '',
        defaultValue = false,
    },
    {
        key = 'zoomInAction',
        type = input.ACTION_TYPE.Boolean,
        l10n = ModInfo.l10nName,
        name = 'Key:',
        description = '',
        defaultValue = false,
    },
    {
        key = 'zoomOutAction',
        type = input.ACTION_TYPE.Boolean,
        l10n = ModInfo.l10nName,
        name = 'Key:',
        description = '',
        defaultValue = false,
    },
    {
        key = 'dofAction',
        type = input.ACTION_TYPE.Boolean,
        l10n = ModInfo.l10nName,
        name = 'Key:',
        description = '',
        defaultValue = false,
    },
}

for _, action in ipairs(Actions) do
    input.registerAction(action)
end

local function inMenu()
    return I.UI.getMode() or core.isWorldPaused()
end

local function togglePlayerControls(switch)
    for _, control in pairs(controlSwitches) do
        if switch == false then
            -- save the current control switch states
            startingControlStates[control] = types.Player.getControlSwitch(self, control)
            -- disable all player control switches
            -- do not disable the Looking switch, it causes the player to reset towards facing north. handled in updateCamera
            types.Player.setControlSwitch(self, control, false)
        else
            -- restore the saved states (default to true if nil)
            types.Player.setControlSwitch(self, control, startingControlStates[control] or true)
        end
    end
end

-- camera state before entering photo mode
local function saveCamera()
    startingCameraMode = camera.getMode()
    startingCameraFOV = camera.getFieldOfView()
    startingCameraPos = camera.getPosition()
    startingCameraPitch = camera.getPitch()
    startingCameraYaw = camera.getYaw()
    startingCameraRoll = camera.getRoll()
end

-- reset camera to starting FOV and roll in photo mode, or restore to original state before entering photo mode
local function resetCamera()
    camera.setFieldOfView(startingCameraFOV)
    camera.setRoll(startingCameraRoll)
    if not photoModeOn then
        camera.setMode(startingCameraMode, true)
        camera.setPitch(startingCameraPitch)
        camera.setYaw(startingCameraYaw)
        if dofPhotoModeOnly then shaderHexDoF:disable() end
    else 
        -- camera.setStaticPosition(startingCameraPos)
    end
end

-- force time freeze, force time unfreeze, and toggle time freeze
local function toggleFreezeTime(switch)
    if switch == true then
        paused = true
        startingSimulationTimeScale = core.getSimulationTimeScale()
        core.sendGlobalEvent('toggleSimulation', 0)
    elseif switch == false then
        paused = false
        core.sendGlobalEvent('toggleSimulation', startingSimulationTimeScale)
    else
        toggleFreezeTime(not paused)
    end
end

local function togglePhotoMode()
    if not photoModeOn then
        if camera.getMode() ~= camera.MODE.FirstPerson
        and camera.getMode() ~= camera.MODE.ThirdPerson
        and camera.getMode() ~= camera.MODE.Preview then
            print(ModInfo.logPrefix .. "Must be in First or Third person to enable")
        elseif not types.Player.getControlSwitch(self, types.Player.CONTROL_SWITCH.Looking)
        or not types.Player.getControlSwitch(self, types.Player.CONTROL_SWITCH.Controls)
        or not types.Player.getControlSwitch(self, types.Player.CONTROL_SWITCH.Jumping) then
            print(ModInfo.logPrefix .. "Must have looking/moving/jumping active to enable")
        else
            -- print("Enabling Photo Mode")
            photoModeOn = true
            saveCamera()
            camera.setMode(camera.MODE.Static, true) -- force static mode, otherwise can be delayed by animations
            if startingCameraMode == camera.MODE.FirstPerson then
                -- shift camera in front of player to get out of head
                camera.setStaticPosition(camera.getPosition() + util.transform.rotateZ(camera.getYaw()) * util.vector3(0, 20, 0))
            end
            togglePlayerControls(false)
            if freezeTimeDefault then toggleFreezeTime(true) end
        end
    else
        -- print("Disabling Photo Mode")
        photoModeOn = false
        toggleFreezeTime(false)
        togglePlayerControls(true)
        resetCamera()
    end
end

local function controllerDeadzone(value, deadzone)
    if math.abs(value) < deadzone then
        return 0
    else
        return value
    end
end

-- stepped roll and zoom functions. deprecated for smooth movement in updateCamera()
--[[
-- keeps camera roll within -360 to 360 degrees
local function updateCameraRoll(dir)
    local currentRoll = camera.getRoll()
    local roll = dir * CAMERA_ROLL_SPEED * mult

    if currentRoll + roll >= math.rad(360) then
        camera.setRoll(currentRoll + roll - math.rad(360))
    elseif currentRoll + roll <= math.rad(-360) then
        camera.setRoll(currentRoll + roll + math.rad(360))
    else
        camera.setRoll(currentRoll + roll)
    end
    
    -- print(ModInfo.logPrefix .. "Tilt set to " .. tostring(math.floor(math.deg(camera.getRoll()) * 100 + 0.5) / 100) .. " degrees")
end

-- clamp to min and max FOV values
-- TODO: consider showing fov num on screen
local function updateCameraFOV(dir)
    local currentFOV = camera.getFieldOfView()
    local fov = dir * CAMERA_ZOOM_STEP * mult

    if currentFOV + fov > MAX_FOV then
        print(ModInfo.logPrefix .. "FOV clamped to maximum")
        camera.setFieldOfView(MAX_FOV)
    elseif currentFOV + fov < MIN_FOV then
        print(ModInfo.logPrefix .. "FOV clamped to minimum")
        camera.setFieldOfView(MIN_FOV)
    else
        camera.setFieldOfView(currentFOV + fov)
    end
    
    -- print(ModInfo.logPrefix .. "FOV set to " .. tostring(math.floor(math.deg(camera.getFieldOfView()) * 100 + 0.5) / 100) .. " degrees")
end
]]

local function updateCamera(realDt)
    -- credit to ptmikheev
    -- camera look/movement code adapted from https://gitlab.com/ptmikheev/openmw-lua-examples/-/blob/master/AdvancedCamera/scripts/AdvancedCamera/free_camera.lua

    -- disables player looking
    -- used to replace the Looking control switch because of how it forces player to look north when used
    self.controls.pitchChange = 0
    self.controls.yawChange = 0
    camera.setExtraPitch(0)
    camera.setExtraYaw(0)
    camera.setExtraRoll(0)

    -- mouse and gamepad movement for looking in static camera    
    local mousePitch = input.getMouseMoveY() * (1 / 650)
    local mouseYaw = input.getMouseMoveX() * (1 / 650)
    local controllerPitch = controllerDeadzone(input.getAxisValue(input.CONTROLLER_AXIS.RightY), DEADZONE_THRESHOLD_RIGHT) * (1 / 75)
    local controllerYaw = controllerDeadzone(input.getAxisValue(input.CONTROLLER_AXIS.RightX), DEADZONE_THRESHOLD_RIGHT) * (1 / 75)
    camera.setPitch(camera.getPitch() + mousePitch + controllerPitch)
    camera.setYaw(camera.getYaw() + mouseYaw + controllerYaw)

    local moveForward = 0
    local moveRight = 0
    local moveUp = 0
    local rollRight = 0
    local zoomIn = 0
    
    -- camera movement input
    -- prevents dpad movement in photo mode, freeing up the dpad for bindings
    if input.isActionPressed(input.ACTION.MoveForward) and not input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadUp) then moveForward = moveForward + realDt end
    if input.isActionPressed(input.ACTION.MoveBackward) and not input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadDown) then moveForward = moveForward - realDt end
    if input.isActionPressed(input.ACTION.MoveRight) and not input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadRight) then moveRight = moveRight + realDt end
    if input.isActionPressed(input.ACTION.MoveLeft) and not input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadLeft) then moveRight = moveRight - realDt end
    if input.getBooleanActionValue('moveUpAction') then moveUp = moveUp + realDt end
    if input.getBooleanActionValue('moveDownAction') then moveUp = moveUp - realDt end
    if input.getBooleanActionValue('rollLeftAction') then rollRight = rollRight + realDt end
    if input.getBooleanActionValue('rollRightAction') then rollRight = rollRight - realDt end
    if input.getBooleanActionValue('zoomOutAction') then zoomIn = zoomIn + realDt end
    if input.getBooleanActionValue('zoomInAction') then zoomIn = zoomIn - realDt end

    -- camera movement gamepad input
    moveForward = moveForward + realDt * -controllerDeadzone(input.getAxisValue(input.CONTROLLER_AXIS.LeftY), DEADZONE_THRESHOLD_LEFT)
    moveRight = moveRight + realDt * controllerDeadzone(input.getAxisValue(input.CONTROLLER_AXIS.LeftX), DEADZONE_THRESHOLD_LEFT)

    -- movement vector based on camera direction
    local offset = util.transform.rotateZ(camera.getYaw()) * util.vector3(
        moveRight * CAMERA_MOVEMENT_SPEED * mult,
        moveForward * CAMERA_MOVEMENT_SPEED * mult,
        moveUp * CAMERA_MOVEMENT_SPEED * mult
    )
    camera.setStaticPosition(camera.getPosition() + offset)

    -- smooth adjust camera roll
    local roll = rollRight * CAMERA_ROLL_SPEED * mult
    camera.setRoll(util.normalizeAngle(camera.getRoll() + roll))

    -- smooth adjust camera zoom
    local fov = zoomIn * CAMERA_ZOOM_SPEED * mult
    local newFOV = util.clamp(camera.getFieldOfView() + fov, MIN_FOV, MAX_FOV)
    camera.setFieldOfView(newFOV)
end

input.registerActionHandler('photoModeAction', async:callback(function(pressed)
    if enableMod and pressed and not inMenu() then togglePhotoMode() return true end
    return false
end))

input.registerActionHandler('freezeTimeAction', async:callback(function(pressed)
    if enableMod and pressed and photoModeOn and not inMenu() then toggleFreezeTime() return true end
    return false
end))

input.registerActionHandler('resetCameraAction', async:callback(function(pressed)
    if enableMod and pressed and photoModeOn and not inMenu() then resetCamera() return true end
    return false
end))

input.registerActionHandler('dofAction', async:callback(function(pressed)
    if enableMod and pressed and (photoModeOn or not dofPhotoModeOnly) and not inMenu() then
        if shaderHexDoF:isEnabled() then
            shaderHexDoF:disable()
        else
            shaderHexDoF:enable()
        end
    return true
    end
return false
end))
--[[
input.registerActionHandler('rollLeftAction', async:callback(function(pressed)
    if enableMod and pressed and photoModeOn and not inMenu() then updateCameraRoll(1) return true end
    return false
end))

input.registerActionHandler('rollRightAction', async:callback(function(pressed)
    if enableMod and pressed and photoModeOn and not inMenu() then updateCameraRoll(-1) return true end
    return false
end))

input.registerActionHandler('zoomInAction', async:callback(function(pressed)
    if enableMod and pressed and photoModeOn and not inMenu() then updateCameraFOV(-1) return true end
    return false
end))

input.registerActionHandler('zoomOutAction', async:callback(function(pressed)
    if enableMod and pressed and photoModeOn and not inMenu() then updateCameraFOV(1) return true end
    return false
end))
]]
local function onFrame(dt)
    local now = core.getRealTime()
    local realDt = now - lastRealTime
    lastRealTime = now

    if not enableMod or not photoModeOn or inMenu() then return end

    -- modifier keys
    -- keyboard: shift and alt for faster and slower
    -- controller: right and left triggers for faster and slower
    mult = 1
    if input.isAltPressed() and not input.isShiftPressed() then
        mult = 0.2 
    elseif input.isShiftPressed() and not input.isAltPressed() then
        mult = 5
    else
        local lt = input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft)
        local rt = input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight)

        if lt > 0.5 and rt <= 0.5 then
            mult = 0.2
        elseif rt > 0.5 and lt <= 0.5 then
            mult = 5
        end
    end

    updateCamera(realDt)
end

onInit = function()
    print("\n\n**********\n" .. ModInfo.logPrefix .. "PLEASE MANUALLY SET PHOTO MODE KEY BINDINGS IN THE SCRIPT SETTINGS!\n**********\n")
end

onSave = function()
    -- disable photo mode when saving
    print(ModInfo.logPrefix .. "onSave")
    if photoModeOn then togglePhotoMode() end
    return {
        PhotoModeDisabled = 1,
        version = scriptVersion,
        pitch = camera.getPitch(),
        yaw = camera.getYaw(),
        roll = camera.getRoll(),
        fov = camera.getFieldOfView(),
    }
end

onLoad = function(data)    
    if not data or data.PhotoModeDisabled ~= 1 then
        -- reset to defaults if photo mode wasnt disabled previously
        print(ModInfo.logPrefix .. "No previous onSave data, restoring to defaults")
        camera.setMode(camera.MODE.FirstPerson, true)
        camera.setFieldOfView(startingCameraFOV)
        camera.setPitch(startingCameraPitch)
        camera.setYaw(startingCameraYaw)
        camera.setRoll(startingCameraRoll)

        for _, control in pairs(controlSwitches) do
            types.Player.setControlSwitch(self, control, true)
        end
    else
        print(ModInfo.logPrefix .. "onLoad resetting camera settings to saved values")
        camera.setPitch(data.pitch or 0)
        camera.setYaw(data.yaw or 0)
        camera.setRoll(data.roll or 0)
        camera.setFieldOfView(data.fov or 75)
    end

    if data.version ~= scriptVersion then
        print(ModInfo.logPrefix .. "Updated from version " .. data.version .. " to " .. scriptVersion)
        -- do something if needed
    end
end

return {
    engineHandlers = {
        onFrame = onFrame,
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad,
    }
}