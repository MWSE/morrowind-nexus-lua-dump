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

    1.5 changes
    - fixed a bug causing conflicts with other mods using input keybinds in settings pages
    - fixed the settings page not allowing you to rebind buttons on first time startup
    - fixed having to reloadlua for settings changes to apply in all cases except for enabling/disabling the mod
    - added default keybinds on first time setup and after updating from previous versions
    - added a message after updating from previous versions to explain the changes and reset of settings

    LONG TERM TODO (probably maybe not):
    - toggle visibility of the player
    - Dynamic Camera Effects compatibility
        - cant tilt camera while unpaused [caused by handleCamRoll() in DynamicCamera.lua]
        - cant zero out roll effects from looking/strafing when entering photo mode
]]

local core = require('openmw.core')
local camera = require('openmw.camera')
local input = require('openmw.input')
local self = require('openmw.self')
local util = require('openmw.util')
local storage = require('openmw.storage')
local async = require('openmw.async')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local postprocessing = require('openmw.postprocessing')
local shaderHexDoF = postprocessing.load('HexDoFPhotoMode')
local ModInfo = require('scripts.PhotoMode.ModInfo')

if require('openmw.core').API_REVISION < 72 then
    error(ModInfo.logPrefix .. "This mod requires a new version of OpenMW, please update.")
end

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
local gamepadStorageKey = storage.playerSection('Settings/' .. ModInfo.name .. '/Gamepad')
local generalStorageKey = storage.playerSection('Settings/' .. ModInfo.name .. '/General')
local ENABLE_MOD = enableStorageKey:get('PM_EnableMod')
local DEADZONE_THRESHOLD_RIGHT
local DEADZONE_THRESHOLD_LEFT
local GAMEPAD_X_AXIS_INVERT
local GAMEPAD_Y_AXIS_INVERT
local CAMERA_MOVEMENT_SPEED
local CAMERA_ROLL_SPEED
local CAMERA_ZOOM_SPEED
local FREEZE_TIME_DEFAULT
local DOF_PHOTOMODE_ONLY
local MOUSE_X_AXIS_INVERT
local MOUSE_Y_AXIS_INVERT

local function updateGamepadSettings(groupName, key)
    DEADZONE_THRESHOLD_RIGHT = gamepadStorageKey:get('PM_DeadzoneRight')
    DEADZONE_THRESHOLD_LEFT = gamepadStorageKey:get('PM_DeadzoneLeft')
    GAMEPAD_X_AXIS_INVERT = gamepadStorageKey:get('PM_GamepadInvertX')
    GAMEPAD_Y_AXIS_INVERT = gamepadStorageKey:get('PM_GamepadInvertY')
end
local function updateGeneralSettings(groupName, key)
    CAMERA_MOVEMENT_SPEED = generalStorageKey:get('PM_MovementSpeed') or 150
    CAMERA_ROLL_SPEED = math.rad(generalStorageKey:get('PM_TiltSpeed') or 30)
    CAMERA_ZOOM_SPEED = math.rad(generalStorageKey:get('PM_ZoomStep') or 30)
    FREEZE_TIME_DEFAULT = generalStorageKey:get('PM_FreezeTimeDefault')
    DOF_PHOTOMODE_ONLY = generalStorageKey:get('PM_DoFPhotoModeOnly')
    MOUSE_X_AXIS_INVERT = generalStorageKey:get('PM_MouseInvertX')
    MOUSE_Y_AXIS_INVERT = generalStorageKey:get('PM_MouseInvertY')
end
updateGamepadSettings()
updateGeneralSettings()
gamepadStorageKey:subscribe(async:callback(updateGamepadSettings))
generalStorageKey:subscribe(async:callback(updateGeneralSettings))

local function inMenu()
    return I.UI.getMode() or core.isWorldPaused()
end

local savedControlStates = nil
local function disablePlayerControls()
    if savedControlStates then return end
    savedControlStates = {}
    for _, control in pairs(controlSwitches) do
        savedControlStates[control] = types.Player.getControlSwitch(self, control)
        types.Player.setControlSwitch(self, control, false)
    end
end

local function restorePlayerControls()
    if not savedControlStates then return end
    for control, state in pairs(savedControlStates) do
        types.Player.setControlSwitch(self, control, state)
    end
    savedControlStates = nil
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
        if DOF_PHOTOMODE_ONLY then shaderHexDoF:disable() end
    else 
        -- camera.setStaticPosition(startingCameraPos)
    end
end

local function freezeTime()
    if paused then return end
    paused = true
    startingSimulationTimeScale = core.getSimulationTimeScale()
    core.sendGlobalEvent('toggleSimulation', 0)
end

local function unfreezeTime()
    if not paused then return end
    paused = false
    core.sendGlobalEvent('toggleSimulation', startingSimulationTimeScale)
end

local function toggleFreezeTime()
    if paused then
        unfreezeTime()
    else
        freezeTime()
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
            photoModeOn = true
            saveCamera()
            camera.setMode(camera.MODE.Static, true) -- force static mode, otherwise can be delayed by animations
            if startingCameraMode == camera.MODE.FirstPerson then
                -- shift camera in front of player to get out of head
                camera.setStaticPosition(camera.getPosition() + util.transform.rotateZ(camera.getYaw()) * util.vector3(0, 20, 0))
            end
            disablePlayerControls()
            if FREEZE_TIME_DEFAULT then freezeTime() end
        end
    else
        photoModeOn = false
        unfreezeTime()
        restorePlayerControls()
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
    if MOUSE_Y_AXIS_INVERT then mousePitch = mousePitch * -1 end
    if MOUSE_X_AXIS_INVERT then mouseYaw = mouseYaw * -1 end
    local controllerPitch = controllerDeadzone(input.getAxisValue(input.CONTROLLER_AXIS.RightY), DEADZONE_THRESHOLD_RIGHT) * (1 / 75)
    local controllerYaw = controllerDeadzone(input.getAxisValue(input.CONTROLLER_AXIS.RightX), DEADZONE_THRESHOLD_RIGHT) * (1 / 75)
    if GAMEPAD_Y_AXIS_INVERT then controllerPitch = controllerPitch * -1 end
    if GAMEPAD_X_AXIS_INVERT then controllerYaw = controllerYaw * -1 end
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
    if ENABLE_MOD and pressed and not inMenu() then togglePhotoMode() return true end
    return false
end))

input.registerActionHandler('freezeTimeAction', async:callback(function(pressed)
    if ENABLE_MOD and pressed and photoModeOn and not inMenu() then toggleFreezeTime() return true end
    return false
end))

input.registerActionHandler('resetCameraAction', async:callback(function(pressed)
    if ENABLE_MOD and pressed and photoModeOn and not inMenu() then resetCamera() return true end
    return false
end))

input.registerActionHandler('dofAction', async:callback(function(pressed)
    if ENABLE_MOD and pressed and (photoModeOn or not DOF_PHOTOMODE_ONLY) and not inMenu() then
        if shaderHexDoF:isEnabled() then
            shaderHexDoF:disable()
        else
            shaderHexDoF:enable()
        end
    return true
    end
return false
end))

local function defaultKeybinds()
    local bindingSection = storage.playerSection('OMWInputBindings')
    local defaultKeybinds = {
        { key = "photoModeAction", name = ModInfo.name .. "_PhotoModeAction", button = 24 },        -- U
        { key = "freezeTimeAction", name = ModInfo.name .. "_FreezeTimeAction", button = 12 },      -- I
        { key = "dofAction", name = ModInfo.name .. "_DoFAction", button = 25 },                    -- V
        { key = "resetCameraAction", name = ModInfo.name .. "_ResetCameraAction", button = 56 },    -- /
        { key = "moveUpAction", name = ModInfo.name .. "_MoveUpAction", button = 44 },              -- Space
        { key = "moveDownAction", name = ModInfo.name .. "_MoveDownAction", button = 224 },         -- Left Ctrl
        { key = "rollLeftAction", name = ModInfo.name .. "_RollLeftAction", button = 80 },          -- Left Arrow
        { key = "rollRightAction", name = ModInfo.name .. "_RollRightAction", button = 79 },        -- Right Arrow
        { key = "zoomInAction", name = ModInfo.name .. "_ZoomInAction", button = 82 },              -- Up Arrow
        { key = "zoomOutAction", name = ModInfo.name .. "_ZoomOutAction", button = 81 },            -- Down Arrow
    }
    local message = "Setting default keybind(s) for:"
    for _, action in pairs(defaultKeybinds) do
        if not bindingSection:get(action.name) then
            message = message .. " " .. action.key
            bindingSection:set(action.name, {
                key = action.key,
                button = action.button,
                type = 'action',
                device = 'keyboard',
            })
        end
    end
    if message ~= "Setting default keybind(s) for:" then
        print(ModInfo.logPrefix .. message)
    end
end

local function defaultValues()
    CAMERA_MOVEMENT_SPEED = 150
    CAMERA_ROLL_SPEED = math.rad(30)
    CAMERA_ZOOM_SPEED = math.rad(30)
    FREEZE_TIME_DEFAULT = true
    DOF_PHOTOMODE_ONLY = true
    MOUSE_X_AXIS_INVERT = false
    MOUSE_Y_AXIS_INVERT = false
    DEADZONE_THRESHOLD_RIGHT = 0.1
    DEADZONE_THRESHOLD_LEFT = 0.1
    GAMEPAD_X_AXIS_INVERT = false
    GAMEPAD_Y_AXIS_INVERT = false
end

local function migrateVersion1005(data)
    print(ModInfo.logPrefix .. "Updated from version " .. data.version .. " to " .. scriptVersion)
    print(ModInfo.logPrefix .. "Cleaning storage sections of previous redundant key names. Click \"Reset\" on the mod settings page to restore defaults.")
    enableStorageKey:reset()
    keybindsStorageKey:reset()
    gamepadStorageKey:reset()
    generalStorageKey:reset()
    defaultKeybinds()
    defaultValues()
    local message = "Photo Mode has been updated to v" .. ModInfo.versionSemantic
    .. "\nMod settings have been reset to clean up some storage entries behind the scenes."
    .. "\n\nPlease go to the mod settings menu and click \"Reset\" in each"
    .. " category to restore default settings and reconfigure to your liking."
    .. "\n\nThank you for using Photo Mode!"
    ui.showMessage(message)
end

local function onFrame(dt)
    local now = core.getRealTime()
    local realDt = now - lastRealTime
    lastRealTime = now

    if not ENABLE_MOD or not photoModeOn or inMenu() then return end

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
    print(ModInfo.logPrefix .. "First time setup initializing")
    defaultKeybinds()
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
        if tonumber(data.version) < 1005 then migrateVersion1005(data) end
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