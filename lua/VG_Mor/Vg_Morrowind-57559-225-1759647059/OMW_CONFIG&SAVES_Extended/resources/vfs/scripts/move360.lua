if require('openmw.core').API_REVISION < 10 then
    error('This mod requires a newer version of OpenMW, please update.')
end

local camera = require('openmw.camera')
local input = require('openmw.input')
local self = require('openmw.self')
local util = require('openmw.util')
local settings = require('openmw.settings')
local I = require('openmw.interfaces')

if not I.Camera then
    error('Interface "Camera" is required')
end

local MODE = camera.MODE
local togglePOV = false
local idleTimer = 0
local vanityDelay = settings.getGMST('fVanityDelay')

local active = false

local function turnOn()
    I.Camera.disableModeControl()
    I.Camera.disableStandingPreview()
    active = true
end

local function turnOff()
    I.Camera.enableModeControl()
    I.Camera.enableStandingPreview()
    active = false
    if camera.getMode() == MODE.Preview then
        camera.setMode(MODE.ThirdPerson)
    end
end

local function updatePOV()
    if input.isActionPressed(input.ACTION.TogglePOV) and input.getControlSwitch(input.CONTROL_SWITCH.ViewMode) then
        togglePOV = true
    elseif togglePOV then
        togglePOV = false
        if camera.getMode() == MODE.FirstPerson then
            camera.setMode(MODE.Preview)
        else
            camera.setMode(MODE.FirstPerson)
        end
    end
end

local function updateVanity(dt)
    if input.isIdle() then
        idleTimer = idleTimer + dt
    else
        idleTimer = 0
    end
    local vanityAllowed = input.getControlSwitch(input.CONTROL_SWITCH.VanityMode)
    if vanityAllowed and idleTimer > vanityDelay and camera.getMode() ~= MODE.Vanity then
        camera.setMode(MODE.Vanity)
    end
    if camera.getMode() == MODE.Vanity then
        if not vanityAllowed or idleTimer == 0 then
            camera.setMode(camera.MODE.Preview)
        else
            camera.setYaw(camera.getYaw() + math.rad(3) * dt)
        end
    end
end

local function onUpdate(dt)
    local newActive = not (self:isInMagicStance() or self:isInWeaponStance())
    if newActive and not active then
        turnOn()
    elseif not newActive and active then
        turnOff()
    end
    if not active then return end
    if camera.getMode() == MODE.Static then return end
    if camera.getMode() == MODE.ThirdPerson then camera.setMode(MODE.Preview) end
    updatePOV()
    updateVanity(dt)
    if camera.getMode() == MODE.Preview then
        camera.showCrosshair(true)
        local move = util.vector2(self.controls.sideMovement, self.controls.movement)
        move = move:rotate(self.rotation.z - camera.getYaw())
        self.controls.sideMovement = move.x
        self.controls.movement = move.y
        if move:length() > 0.05 then
            local delta = math.atan2(move.x, move.y)
            local maxDelta = math.max(delta, 1) * 2 * dt
            self.controls.turn = util.clamp(delta, -maxDelta, maxDelta)
        else
            self.controls.turn = 0
        end
    end
end

return {
    engineHandlers = {
        onInputUpdate = onUpdate
    }
}

