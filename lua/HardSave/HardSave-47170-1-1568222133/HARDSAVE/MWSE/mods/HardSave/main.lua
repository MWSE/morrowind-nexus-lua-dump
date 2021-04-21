local function onSave(e)
	if tes3.mobilePlayer.inCombat then
		tes3.messageBox({ message = "You cannot save the game in battle" })
		return false
	end
end

local function initialized(e)
	event.register("save", onSave)
end
event.register("initialized", initialized)