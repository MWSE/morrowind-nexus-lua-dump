--[[
	Mod Initialization: Morrowind Quick Loot Fixer script
	Version 1
	Author: mort
	       
	removes all light sources from your character on b press
]] --

-- Ensure that the player has the necessary MWSE version.
if (mwse.buildDate == nil or mwse.buildDate < 20201001) then
	mwse.log("[QuickLoot] Build date of %s does not meet minimum build date of 2020-10-01.", mwse.buildDate)
	event.register(
		"initialized",
		function()
			tes3.messageBox("Please run MWSE-Update.exe.")
		end
	)
	return
end

local function removeLights(e)
	local lootKey = tes3.scanCode["b"]
	--print(e.keyCode ~= tes3.scanCode[lootKey])
	
	if ( e.keyCode ~= lootKey ) then
		return
	end

	local inventory = tes3.player.object.inventory

	loopend = #inventory
	lightsRemoved = 0

	for x=1,loopend do
		if (inventory.iterator[x-lightsRemoved].object.objectType == tes3.objectType.light) then
			print(inventory.iterator[x].object)
			tes3.transferItem({
				from = tes3.player,
				to = tes3.getPlayerTarget(),
				item = inventory.iterator[x-lightsRemoved].object,
				playSound = false,
				count = math.abs(inventory.iterator[x-lightsRemoved].count),
				updateGUI = true,
			})
			lightsRemoved = lightsRemoved + 1
		end
	end
	mwse.log("all light sources have been removed")
end

local function onInitialized()
	event.register("keyDown", removeLights)
end
event.register("initialized", onInitialized)