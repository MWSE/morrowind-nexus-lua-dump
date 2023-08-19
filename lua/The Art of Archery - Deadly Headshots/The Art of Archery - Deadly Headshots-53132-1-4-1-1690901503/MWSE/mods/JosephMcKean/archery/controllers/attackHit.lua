local logging = require("JosephMcKean.archery.logging")
local log = logging.createLogger("attackHit")

---This is a hack and not reliable
---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
local function getIfMoving(mobile) return mobile.isFalling or mobile.isJumping or mobile.isMovingBack or mobile.isMovingForward or mobile.isMovingLeft or mobile.isMovingRight or mobile.isRunning end

---@param e attackHitEventData
local function attackHit(e)
	local reference = e.reference
	if getIfMoving(e.mobile) then
		reference.tempData.isMoving = true
		if reference.tempData.isMovingTimer then reference.tempData.isMovingTimer:cancel() end
		reference.tempData.isMovingTimer = timer.start({ duration = 0.01, callback = function() reference.data.isMoving = false end })
	else
		reference.tempData.isMoving = false
	end
end

return attackHit
