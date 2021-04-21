local config = require("OEA.OEA10 Fresh.config")

local value1
local value2
local value3
local value4

--the only thing not done was the story and those infernal tables. everything else should be fully coded and working.
local function OnLoad(e)
	if (config.Money == true) then
		require("OEA.OEA10 Fresh.health")
	end

	if (config.Mech == true) then
		require("OEA.OEA10 Fresh.questMechanics")
		require("OEA.OEA10 Fresh.paymentEnter")
		require("OEA.OEA10 Fresh.dialogue")
	end

	if (config.AltStart == true) then
		local Ride = require("OEA.OEA10 Fresh.overrides")
		Ride.overrideScripts()

		require("OEA.OEA10 Fresh.fargothSim")
		require("OEA.OEA10 Fresh.menus")
	end

	if (config.Main == true) and (config.Money == true) and (config.AltStart == true) and (config.Mech == true) then
		local stump = require("OEA.OEA10 Fresh.stump")
		stump.overrideScripts()

		if (value1 == nil) then
			value1 = tes3.findGMST("fSpecialSkillBonus").value
			value2 = tes3.findGMST("fMajorSkillBonus").value
			value3 =  tes3.findGMST("fMinorSkillBonus").value
			value4 = tes3.findGMST("fMiscSkillBonus").value
		end

		--stops player from gaining skills without training (money) during quest
		tes3.findGMST("fSpecialSkillBonus").value = 1000
		tes3.findGMST("fMajorSkillBonus").value = 1000
		tes3.findGMST("fMinorSkillBonus").value = 1000
		tes3.findGMST("fMiscSkillBonus").value = 1000
	elseif (config.Main == false) and (value1 ~= nil) then
		tes3.findGMST("fSpecialSkillBonus").value = value1
		tes3.findGMST("fMajorSkillBonus").value = value2
		tes3.findGMST("fMinorSkillBonus").value = value3
		tes3.findGMST("fMiscSkillBonus").value = value4
	end
end

local function OnInit(e)
	mwse.log("[Freshly-Picked Fargoth's Rosy Septimland] Initialized.")

	event.register("load", OnLoad)
end
event.register("initialized", OnInit)

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
	require("OEA.OEA10 Fresh.mcm")
end)
