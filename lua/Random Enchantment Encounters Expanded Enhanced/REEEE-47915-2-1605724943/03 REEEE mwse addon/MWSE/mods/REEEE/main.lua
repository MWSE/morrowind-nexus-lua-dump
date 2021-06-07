local config = require("REEEE.config")

local function onMobileActivated(e)
	if e.reference.object.objectType ~= tes3.objectType.npc then return end
	if mwscript.getItemCount{reference = e.reference, item = "0S_sc_paper"} >= 1 then return end
	if mwscript.getItemCount{reference = e.reference, item = "slave_bracer_left"} >= 1 then return end
	if mwscript.getItemCount{reference = e.reference, item = "slave_bracer_right"} >= 1 then return end
	local itemRNG = math.random(100)
	if itemRNG > config.itemChance then return end
	local itemPick = table.choice(config.itemList)
	tes3.addItem({ reference = e.reference, playSound = false, limit = false, item = itemPick })
	tes3.addItem({ reference = e.reference, playSound = false, limit = false, item = "0S_sc_paper" })
	--mwse.log("REEEE: " .. itemPick .. " added to " .. e.reference.object.name )
end

local function onLoaded()
	event.register("mobileActivated", onMobileActivated)
end

local function initialized()
	if tes3.isModActive("REEEE.esp") then
		mwse.log("REEEE esp detected")
		event.register("loaded", onLoaded)
	else
		mwse.log("REEEE esp not detected")
	end
end
event.register("initialized", initialized)

local function registerModConfig()
	require("REEEE.mcm")
end
event.register("modConfigReady", registerModConfig)