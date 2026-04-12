local M = {}

-- Local Variables
local holdTime = 0
local detectingPlaceStacksHold = false
local previousFramePress = false

-- Local Functions

local getCalculatedHoldTime = function(settingsHoldMS)
	return Core.getRealTime() + settingsHoldMS / 1000 -- convert ms to seconds
end

M.stopDetectingPlaceStacksHold = function()
	detectingPlaceStacksHold = false
end

local shouldCancelPlaceStacksHoldDetection = function()
	if not Input.isActionPressed(Input.ACTION.Activate) then
		return true
	end
	return false
end

M.detectPlaceStacksPress = function()
	local detected = false
	local currentFramePress = Input.getBooleanActionValue(Keys.CONSTANT_KEYS.CustomInputs.PlaceStacks)
	if DetectorHelpers.detectPress(previousFramePress, currentFramePress) then
		M.stopDetectingPlaceStacksHold()
		detected = true
	end
	previousFramePress = currentFramePress
	return detected
end

M.detectPlaceStacksHold = function()
	local detected = false

	if detectingPlaceStacksHold and shouldCancelPlaceStacksHoldDetection() then
		M.stopDetectingPlaceStacksHold()
		DB.log("place stacks hold cancelled")
		return detected
	end
	if detectingPlaceStacksHold then
		if Core.getRealTime() >= holdTime then
			M.stopDetectingPlaceStacksHold()
			detected = true
		end
	end
	return detected
end

M.startDetectingPlaceStacksHoldIfEnabled = function(settingsHoldMS)
	local settingsPlaceStacksHoldEnabled = settingsHoldMS > 0
	if settingsPlaceStacksHoldEnabled then
		if not Helpers.isContainerValid(FocusedContainer, Types) then
			return
		end

		holdTime = getCalculatedHoldTime(settingsHoldMS)
		DB.log("place stacks hold started with setting " .. settingsHoldMS .. " - time set to: " .. holdTime)
		detectingPlaceStacksHold = true
	end
end

return M
