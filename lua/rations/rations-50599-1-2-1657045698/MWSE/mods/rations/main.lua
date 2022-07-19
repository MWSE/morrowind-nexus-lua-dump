local config = require("rations.config")

local function onMobileActivated(e)
	if e.reference.object.objectType ~= tes3.objectType.npc then return end
	if e.reference.object.faction then
		if e.reference.object.faction.id == "Imperial Legion" then
			if mwscript.getItemCount{reference = e.reference, item = "0s_rations_00"} >= 1 then return end
			if mwscript.getItemCount{reference = e.reference, item = "0s_rations_01"} >= 1 then return end
			local RNG = math.random(100)
			if RNG > config.legionChance then return end
			tes3.addItem({ reference = e.reference, playSound = false, limit = false, item = "0s_rnd_ration_legion" })
		end
		if e.reference.object.faction.id == "Ashlanders" then
			if mwscript.getItemCount{reference = e.reference, item = "0s_rations_02"} >= 1 then return end
			if mwscript.getItemCount{reference = e.reference, item = "0s_rations_03"} >= 1 then return end
			local RNG = math.random(100)
			if RNG > config.ashChance then return end
			tes3.addItem({ reference = e.reference, playSound = false, limit = false, item = "0s_rnd_ration_ash" })
		end
	end
end

local function onLoaded()
	event.register("mobileActivated", onMobileActivated)
end

local function initialized()
	if tes3.isModActive("rations.ESP") then
		event.register("loaded", onLoaded)
	else
		mwse.log("rations esp not detected")
	end
end
event.register("initialized", initialized)

local function registerModConfig()
	require("rations.mcm")
end
event.register("modConfigReady", registerModConfig)