--[[
    sprinting
--]]

local sprinting
local noSprinting
local ath

local function onCalcMoveSpeed(e)
    if (e.reference == tes3.player) then
        if (sprinting == true) and tes3.mobilePlayer.isRunning and tes3.mobilePlayer.fatigue.current > 0 then
            e.speed = e.speed * (1.75 - (ath / 3))
			tes3.mobilePlayer.fatigue.current = tes3.mobilePlayer.fatigue.current - (1.5 - ath)
			mge.enableZoom()
			mge.setZoom{amount=1.04, animate=true}
		elseif tes3.mobilePlayer.isRunning == false or noSprinting == true or tes3.mobilePlayer.fatigue.current == 0 then
			mge.setZoom{amount=0, animate=true}
        end
    end
end



local function sprintKey(e)
ath = tes3.mobilePlayer.athletics.current / 200
if ath < 1 then
ath = 1
end
    if tes3.mobilePlayer.isRunning then
        sprinting = e.pressed
		noSprinting = false
    end
end

local function noSprintKey(e)
        sprinting = false
		noSprinting = true
    end



local function initialized(e)
    event.register("calcMoveSpeed", onCalcMoveSpeed)
    event.register("keyDown", sprintKey, { filter = 56 })
	event.register("keyUp", noSprintKey, { filter = 56 })
    print("Initialized Sprinting v0.00")
end
event.register("initialized", initialized)
