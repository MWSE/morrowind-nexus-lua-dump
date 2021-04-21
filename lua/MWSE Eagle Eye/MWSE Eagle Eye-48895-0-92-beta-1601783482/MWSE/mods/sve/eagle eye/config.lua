local config = mwse.loadConfig("eagle eye")
local base = {
      	   eagleEyeEnabled = true,
      	   eagleEyeAlwaysEnabled = true,
      	   eagleEyeKeyInfo = {
            		   keyCode = tes3.scanCode.lShift,
            		   isAltDown = false,
            		   isShiftDown = false,
            		   isControlDown = false,
	    		   },
	   eagleEyeDistance = 5000,
	   normalActivationDistance = tes3.findGMST("iMaxActivateDist").value,
	   exceedsActivationDistanceMessage = "Too far away.",
      	   tigerEyeEnabled = true,
      	   tigerEyeKeyInfo = {
            		   keyCode = tes3.scanCode.lShift,
            		   isAltDown = false,
            		   isShiftDown = false,
            		   isControlDown = false,
	    		   },
	   tigerEyeBoundingBoxMinToDistRatio = nil, -- disabled -- 15, -- %
	   tigerEyeBoundingBoxMinLength = nil, -- disabled -- 35,
	   tigerEyeDistanceItem = 0,
	   lockOnBindKeyDown = true,
	   tigerEyeInventoryItemsEnabled = true,
	   tigerEyeDistanceActor = tes3.findGMST("iMaxActivateDist").value,
	   tigerEyeDistanceObject = tes3.findGMST("iMaxActivateDist").value,
	   tigerEyeEnabledRunning = false,
	   tigerEyeEnabledWalking = false,
	   tigerEyeEnabledJumping = false,
	   tigerEyeEnabledSwimming = false,
	   skipRepetitiveLocks = 1,
	   }

if config == nil then
   return base
end

-- this is to avoid missing entries during development
for key,_ in pairs(base) do
   if config[key] == nil then
      config[key] = base[key]
   end
end
return config