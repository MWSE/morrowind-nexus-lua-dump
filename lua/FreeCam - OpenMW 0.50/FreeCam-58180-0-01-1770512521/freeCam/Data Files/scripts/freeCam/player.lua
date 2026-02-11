local storage = require('openmw.storage')
local input = require('openmw.input')
local self = require('openmw.self')
local util = require('openmw.util')

local controlsSettings = storage.playerSection('SettingsFreeCamcontrols')
local freeModule = require('scripts.FreeCam.free')

local isActive = false
local isLocked = false
local initialPlayerRotation = nil
local rotationAccumulator = 0

local ROTATION_INCREMENT = 0.13  -- ~7.5 degrees in radians
local leftArrowHeld = false
local rightArrowHeld = false

local function rotatePlayer(direction)
   if not isActive or isLocked then
      return
   end
   
   rotationAccumulator = direction * ROTATION_INCREMENT
end

local function toggleCamera()
   if isActive then
      freeModule.off()
      isActive = false
   else
      -- Store player rotation before activating
      initialPlayerRotation = self.rotation
      local initialYaw = self.rotation:getYaw()
      
      -- Activate FreeCam
      local hadLockedPosition = freeModule.hasLockedPosition()
      freeModule.on()
      isActive = true
      
      -- Restore player rotation after entering FreeCam
      local currentYaw = self.rotation:getYaw()
      local rotationDiff = initialYaw - currentYaw
      
      if math.abs(rotationDiff) > 0.01 then
         self.controls.yawChange = rotationDiff
      end
      
      -- Auto-lock if returning to locked position
      if hadLockedPosition then
         isLocked = true
         freeModule.lock()
      else
         isLocked = false
      end
   end
end

local function toggleLock()
   if not isActive then
      return
   end
   
   if isLocked then
      freeModule.unlock()
      isLocked = false
   else
      freeModule.lock()
      isLocked = true
   end
end

local function onKeyPress(key)
   local freeKey = controlsSettings:get('freeHotkey')
   local shiftPressed = input.isKeyPressed(input.KEY.LeftShift) or input.isKeyPressed(input.KEY.RightShift)
   
   if key.code == freeKey and shiftPressed then
      toggleLock()
   elseif key.code == freeKey and not shiftPressed then
      toggleCamera()
   end
end

return {
   engineHandlers = {
      onKeyPress = onKeyPress,
      onFrame = function(dt)
         if dt > 0 and isActive then
            freeModule.update(dt, isLocked)
			
		 if not isLocked then
			if input.isKeyPressed(input.KEY.LeftArrow) then
				rotationAccumulator = rotationAccumulator - (ROTATION_INCREMENT * dt * 10)
			end
			if input.isKeyPressed(input.KEY.RightArrow) then
				rotationAccumulator = rotationAccumulator + (ROTATION_INCREMENT * dt * 10)
			end
		 end	
	  
            if rotationAccumulator ~= 0 then
               self.controls.yawChange = rotationAccumulator
               rotationAccumulator = 0
            end
         end
      end,
      onLoad = function(saved)
         if saved and saved.isActive then
            isActive = true
            isLocked = saved.isLocked or false
            initialPlayerRotation = saved.initialPlayerRotation
            freeModule.on(saved.cameraState)
            if isLocked then
               freeModule.lock()
            end
         else
            isActive = false
            isLocked = false
            initialPlayerRotation = nil
         end
      end,
      onSave = function()
         if isActive then
            return {
               isActive = true,
               isLocked = isLocked,
               cameraState = freeModule.save(),
               initialPlayerRotation = initialPlayerRotation,
            }
         else
            return { 
               isActive = false, 
               isLocked = false,
               initialPlayerRotation = nil,
            }
         end
      end,
   },
}