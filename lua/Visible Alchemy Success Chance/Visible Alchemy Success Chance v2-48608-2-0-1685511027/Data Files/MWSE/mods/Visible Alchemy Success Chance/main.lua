local function alchemyChance(e)
	local alcSkill = tes3.mobilePlayer.alchemy.current
	local int = tes3.mobilePlayer.intelligence.current
	local luck = tes3.mobilePlayer.luck.current
	-- the latest formula from UESP, fatigue has no effect ? 
	local alcSuccessChance = alcSkill + int/10 + luck/10
	if(e.newlyCreated) then
		local alcChanceLabel = e.element:createLabel{ text = "Chance   " .. math.round(alcSuccessChance, 2) }
		alcChanceLabel.absolutePosAlignY = -0.1
		alcChanceLabel.positionY = -247 
		e.element:updateLayout()
	end
end


local function initialized(e)
	-- call function alchemyChance() when Alchemy menu is opened
	event.register("uiActivated", alchemyChance, { filter = "MenuAlchemy" })
	print("Visible Alchemy Success Chance mod has initialized")
end

event.register("initialized", initialized)