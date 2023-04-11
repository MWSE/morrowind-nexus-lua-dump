local function calcMoveSpeed(e)
	if e.reference ~= tes3.player then return end

	-- If we're moving diagonally, multiply by a constant to compensate
	if (tes3.mobilePlayer.isMovingForward or tes3.mobilePlayer.isMovingBack) and (tes3.mobilePlayer.isMovingLeft or tes3.mobilePlayer.isMovingRight) then
		-- In third person, the player is moved by animations using root motion, so the simple constant doesn't really apply.
		-- Instead, we use an eyeballed constant.
		if tes3.mobilePlayer.is3rdPerson then
			e.speed = e.speed * 0.77
		else
			e.speed = e.speed * 0.70711
		end
	end
end
event.register(tes3.event.calcMoveSpeed, calcMoveSpeed)