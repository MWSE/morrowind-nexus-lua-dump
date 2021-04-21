local function adjustWadeSpeed(e)
    local mobile = e.mobile    
    if (mobile.isSwimming or mobile.isFlying) then return end
	
	local currentCell = e.reference.cell	
	if (currentCell.isInterior and not currentCell.hasWater) then return end
	
	local waterLevel = currentCell.waterLevel or 0	
	local minPosition = mobile.position.z
	local maxPosition = minPosition + mobile.height*0.9	

    local scalar = (waterLevel - minPosition) /(maxPosition - minPosition)
    if (scalar < 0 or scalar > 1) then	return	end

    local landSpeed = e.speed
    local swimSpeed = mobile.isRunning and mobile.swimRunSpeed or mobile.swimSpeed
	scalar = math.sqrt(scalar)
    e.speed = landSpeed * (1 - scalar) + swimSpeed * scalar
end
event.register("calcMoveSpeed", adjustWadeSpeed)