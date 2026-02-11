local camera = require('openmw.camera')
local input = require('openmw.input')
local util = require('openmw.util')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local LPFdt = require('scripts.FreeCam.filters').LPFdt

local controlsSettings = storage.playerSection('SettingsFreeCamcontrols')
local freeSettings = storage.playerSection('SettingsFreeCamfree')

local filterRotation = function(current, new, dt)
   local smoothness = freeSettings:get('rotationSmoothness')
   return LPFdt(current, new, smoothness, dt)
end

local filterSpeed = function(current, new, dt)
   local smoothness = freeSettings:get('speedSmoothness')
   return LPFdt(current, new, smoothness, dt)
end

local filterDirection = function(current, new, dt)
   local smoothness = freeSettings:get('directionSmoothness')
   
   local filtered = util.vector3(
      LPFdt(current.x, new.x, smoothness, dt),
      LPFdt(current.y, new.y, smoothness, dt),
      LPFdt(current.z, new.z, smoothness, dt)
   )
   
   return filtered
end

local function getCameraRotation()
   return util.vector2(camera.getYaw(), camera.getPitch())
end

local function setCameraRotation(v)
   camera.setYaw(v.x)
   camera.setPitch(v.y)
end

local speedMap = {
   [input.ACTION.CycleWeaponRight] = 1,
   [input.ACTION.CycleWeaponLeft] = -1,
   [input.ACTION.CycleSpellRight] = 1,
   [input.ACTION.CycleSpellLeft] = -1,
}

local function getTargetSpeed(currentSpeed)
   local speedDelta = 0
   for action, v in pairs(speedMap) do
      if input.isActionPressed(action) then
         speedDelta = speedDelta + v
      end
   end
   local sensitivity = freeSettings:get('speedSensitivity')
   return math.max(0, currentSpeed + speedDelta * sensitivity)
end

local function getTargetDirection(rotation, controllerLeftStick)
   local yaw = rotation.x
   local pitch = -rotation.y
   
   local forward = util.vector3(
      math.sin(yaw) * math.cos(pitch),
      math.cos(yaw) * math.cos(pitch),
      math.sin(pitch)
   )
   
   local right = util.vector3(
      math.cos(yaw),
      -math.sin(yaw),
      0
   )
   
   local up = util.vector3(0, 0, 1)
   
   local direction = util.vector3(0, 0, 0)
   
   if input.isActionPressed(input.ACTION.MoveForward) then
      direction = direction + forward
   end
   if input.isActionPressed(input.ACTION.MoveBackward) then
      direction = direction - forward
   end
   if input.isActionPressed(input.ACTION.MoveLeft) then
      direction = direction - right
   end
   if input.isActionPressed(input.ACTION.MoveRight) then
      direction = direction + right
   end
   if input.isActionPressed(input.ACTION.Jump) then
      direction = direction + up
   end
   if input.isActionPressed(input.ACTION.Sneak) then
      direction = direction - up
   end
   
   if controllerLeftStick then
      local stickForward = controllerLeftStick.y
      local stickRight = controllerLeftStick.x
      
      direction = direction + (forward * stickForward)
      direction = direction + (right * stickRight)
   end
   
   if direction:length() > 0 then
      return direction:normalize()
   else
      return util.vector3(0, 0, 0)
   end
end

local CONTROL_MAP = {}
if input.CONTROL_SWITCH then
   CONTROL_MAP = {
      input.CONTROL_SWITCH.Controls,
      input.CONTROL_SWITCH.Fighting,
      input.CONTROL_SWITCH.Jumping,
      input.CONTROL_SWITCH.Looking,
      input.CONTROL_SWITCH.Magic,
      input.CONTROL_SWITCH.ViewMode,
      input.CONTROL_SWITCH.VanityMode,
   }
end

local S = {
   rotation = util.vector2(0, 0),
   rotationChange = util.vector2(0, 0),
   position = util.vector3(0, 0, 0),
   direction = util.vector3(0, 0, 0),
   speed = 0,
   lastCameraMode = nil,
   lastControlSwitches = {},
   hudWasVisible = true,
}

local lockedCameraState = nil

local function on(state)
   if state then
      for k, v in pairs(state) do
         S[k] = v
      end
   else
      if lockedCameraState then
         S.rotation = lockedCameraState.rotation
         S.position = lockedCameraState.position
         S.speed = lockedCameraState.speed
      else
         S.rotation = getCameraRotation()
         S.position = camera.getPosition()
         S.speed = freeSettings:get('initialSpeed')
      end
      
      S.lastCameraMode = camera.getMode()
      S.rotationChange = util.vector2(0, 0)
      S.direction = util.vector3(0, 0, 0)
      
      if I.UI then
         S.hudWasVisible = I.UI.getMode()
         I.UI.setHudVisibility(false)
      end

      if input.getControlSwitch and #CONTROL_MAP > 0 then
         for _, v in pairs(CONTROL_MAP) do
            S.lastControlSwitches[v] = input.getControlSwitch(v)
         end
      end
   end

   if input.setControlSwitch and #CONTROL_MAP > 0 then
      for _, v in pairs(CONTROL_MAP) do
         input.setControlSwitch(v, false)
      end
   end
   
   camera.setMode(camera.MODE.Static)
   setCameraRotation(S.rotation)
   camera.setStaticPosition(S.position)
end

local function update(dt, isLocked)
   camera.setMode(camera.MODE.Static)
   
   if isLocked then
      camera.setStaticPosition(S.position)
      setCameraRotation(S.rotation)
      return
   end
   
   local rotationInput = util.vector2(0, 0)
   local mouseMove = util.vector2(input.getMouseMoveX(), input.getMouseMoveY())
   rotationInput = rotationInput + mouseMove
   
   local controllerLeftStick = nil
   
   if input.getAxisValue then
      local rightStickX = input.getAxisValue(2) or 0
      local rightStickY = input.getAxisValue(3) or 0
      local leftStickX = input.getAxisValue(0) or 0
      local leftStickY = input.getAxisValue(1) or 0
      
      local deadzone = 0.15
      if math.abs(rightStickX) < deadzone then rightStickX = 0 end
      if math.abs(rightStickY) < deadzone then rightStickY = 0 end
      if math.abs(leftStickX) < deadzone then leftStickX = 0 end
      if math.abs(leftStickY) < deadzone then leftStickY = 0 end
      
      local controllerSensitivity = 600
      rotationInput = rotationInput + util.vector2(rightStickX * controllerSensitivity * dt, rightStickY * controllerSensitivity * dt)
      
      if leftStickX ~= 0 or leftStickY ~= 0 then
         controllerLeftStick = util.vector2(leftStickX, -leftStickY)
      end
   end
   
   local sensitivity = util.vector2(
      controlsSettings:get('cameraSensitivityX'),
      controlsSettings:get('cameraSensitivityY')
   ) / 256
   
   local newRotationChange = rotationInput:emul(sensitivity)
   S.rotationChange = filterRotation(S.rotationChange, newRotationChange, dt)
   
   local maxRotation = freeSettings:get('maxRotation') * 2 * math.pi
   if S.rotationChange:length() > maxRotation * dt then
      S.rotationChange = S.rotationChange:normalize() * maxRotation * dt
   end

   if math.abs(S.rotation.y) > math.pi * 0.5 and S.rotationChange.y * S.rotation.y > 0 then
      S.rotationChange = util.vector2(S.rotationChange.x, 0)
   end
   S.rotation = S.rotation + S.rotationChange
   setCameraRotation(S.rotation)

   local targetSpeed = getTargetSpeed(S.speed)
   S.speed = filterSpeed(S.speed, targetSpeed, dt)

   local targetDirection = getTargetDirection(S.rotation, controllerLeftStick)
   S.direction = filterDirection(S.direction, targetDirection, dt)
   
   if S.direction:length() > 0.001 then
      S.position = S.position + S.direction * S.speed * dt
   end
   
   camera.setStaticPosition(S.position)
end

local function off()
   camera.setMode(S.lastCameraMode)
   
   if I.UI then
      I.UI.setHudVisibility(true)
   end
   
   if input.setControlSwitch and #CONTROL_MAP > 0 then
      for _, v in pairs(CONTROL_MAP) do
         input.setControlSwitch(v, S.lastControlSwitches[v])
      end
   end
end

local function lock()
   lockedCameraState = {
      position = S.position,
      rotation = S.rotation,
      speed = S.speed,
   }
   
   if input.setControlSwitch and #CONTROL_MAP > 0 then
      for _, v in pairs(CONTROL_MAP) do
         input.setControlSwitch(v, S.lastControlSwitches[v])
      end
   end
end

local function unlock()
   lockedCameraState = nil
   
   if input.setControlSwitch and #CONTROL_MAP > 0 then
      for _, v in pairs(CONTROL_MAP) do
         input.setControlSwitch(v, false)
      end
   end
end

local function hasLockedPosition()
   return lockedCameraState ~= nil
end

local module = {
   on = on,
   update = update,
   off = off,
   save = function() return S end,
   lock = lock,
   unlock = unlock,
   hasLockedPosition = hasLockedPosition,
}

return module