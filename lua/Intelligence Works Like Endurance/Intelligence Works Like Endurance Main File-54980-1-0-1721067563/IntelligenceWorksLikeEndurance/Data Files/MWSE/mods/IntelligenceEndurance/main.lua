


local config = require("intelligenceEndurance.config")
mwse.log("[Intelligence Works Like Endurance MWSE-Lua] Initialized Version 1.0")

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("intelligenceEndurance.mcm")
end)

local hasLeveled
local currentMagickaBonus;
local function preLevelUpCallback(e)
	hasLeveled = true
end
event.register("uiActivated", preLevelUpCallback, { filter = "MenuLevelUp"})





local function finishLevelUp(e)
	if(hasLeveled == true) then
		hasLeveled = false;
		
		local intAmountToAdd = tes3.mobilePlayer.intelligence.base/config.intelligenceBonus;
		if(intAmountToAdd < 1) then
			intAmountToAdd = 1
		end
		tes3.player.data.totalMagickaBonus = tes3.player.data.totalMagickaBonus + intAmountToAdd
		local currentMagicMultiplication = tes3.mobilePlayer.magicka.current/tes3.mobilePlayer.magicka.base
		local baseMagicka = (tes3.mobilePlayer.intelligence.current * tes3.mobilePlayer.magickaMultiplier.current) + tes3.player.data.totalMagickaBonus 
		tes3.setStatistic({ reference = tes3.mobilePlayer, name = "magicka", base = baseMagicka})
		tes3.setStatistic({ reference = tes3.mobilePlayer, name = "magicka", current = baseMagicka * currentMagicMultiplication})
		tes3.mobilePlayer:updateDerivedStatistics(tes3.mobilePlayer.magicka)
		currentMagickaBonus = tes3.player.data.totalMagickaBonus
	end
end


event.register("menuExit", finishLevelUp)

local function onLoad()
	tes3.player.data.totalMagickaBonus = tes3.player.data.totalMagickaBonus or 0
	local currentMagicMultiplication = tes3.mobilePlayer.magicka.current/tes3.mobilePlayer.magicka.base
	local baseMagicka = (tes3.mobilePlayer.intelligence.current * tes3.mobilePlayer.magickaMultiplier.current) + tes3.player.data.totalMagickaBonus 
	tes3.setStatistic({ reference = tes3.mobilePlayer, name = "magicka", base = baseMagicka})
	tes3.setStatistic({ reference = tes3.mobilePlayer, name = "magicka", current = baseMagicka * currentMagicMultiplication})
	tes3.mobilePlayer:updateDerivedStatistics(tes3.mobilePlayer.magicka)
	currentMagickaBonus = tes3.player.data.totalMagickaBonus
end
event.register("loaded", onLoad)


local function onMagicMenuActivated(e)
		if(tes3.mobilePlayer ~= nil and tes3.player ~= nil and tes3.player.data.totalMagickaBonus ~= nil) then
			local currentMagicMultiplication = tes3.mobilePlayer.magicka.current/tes3.mobilePlayer.magicka.base
			local baseMagicka = (tes3.mobilePlayer.intelligence.current * tes3.mobilePlayer.magickaMultiplier.current) + tes3.player.data.totalMagickaBonus 
			tes3.setStatistic({ reference = tes3.mobilePlayer, name = "magicka", base = baseMagicka})
			tes3.setStatistic({ reference = tes3.mobilePlayer, name = "magicka", current = baseMagicka * currentMagicMultiplication})
			tes3.mobilePlayer:updateDerivedStatistics(tes3.mobilePlayer.magicka)
			currentMagickaBonus = tes3.player.data.totalMagickaBonus
		end
end
event.register(tes3.event.menuEnter, onMagicMenuActivated)