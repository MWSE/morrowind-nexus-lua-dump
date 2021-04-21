--[[Story beats: wulf is our stand-in for Uncle Rupee, since I can call him "Uncle Septim" as a joke. he shows up at the pond after Fargoth exits the stump, and promises
to take you to Septimland. Unlike FPTRR, this is underground, under the pond, and your money funds the digging by Argonians and dreugh and whatnot. Eventually he says he
 will take you there, but instead you tcl down a bit and drown. Right before you die, you are teleported away by someone, idk who, never got that far. And you and this
person rally together and defeat wulf. The end."]]--

local config = require("OEA.OEA10 Fresh.config")
local H = {}

local function HidingSpot()
	if (tes3.menuMode() == true) then
		return
	end

	if (tes3.player.data.OEA10 == nil) then
		tes3.player.data.OEA10 = {}
	end

	if (tes3.player.data.OEA10.goldCount == nil) then
		tes3.player.data.OEA10.goldCount = -1
		tes3.runLegacyScript({
			reference = tes3.getReference("flora_treestump_unique"),
			command = "PlaceAtMe wulf, 1, 100, 2"
		})
	end
end

local function UncleScript()
	if (tes3.menuMode() == true) then
		return
	end

	local param = tes3.getReference("wulf")

	if (param.cell.id == "Ghostgate, Tower of Dusk") then
		mwscript.disable({ reference = param })
		return
	end

	if (param.baseObject.name == "Wulf") then
		param.baseObject.name = "Uncle Septim"
		param.mobile.activeAI = false
		param.mobile.hello = 0
		mwscript.disable({ reference = param })
		return
	end
	
	if (mwscript.getDistance({ reference = param, target = tes3.player }) < 1000) then
		tes3.runLegacyScript({
			reference = param,
			command = ("Face %s, %s"):format(tes3.player.position.x, tes3.player.position.y)
		})
	end
end

local function OnContainerClose(e)
	if (e.reference.baseObject.id ~= "flora_treestump_unique") then
		return
	end

	if (mwscript.getItemCount({ reference = e.reference, item = "Gold_001" }) > 0) then
		if (tes3.player.data.OEA10 ~= nil) and (tes3.player.data.OEA10.goldCount ~= nil) then
			if (tes3.player.data.OEA10.goldCount == -1) then
				tes3.player.data.OEA10.goldCount = 0
				local Count = mwscript.getItemCount({ reference = e.reference, item = "Gold_001" })
				tes3.removeItem({ reference = e.reference, item = "Gold_001", count = Count })
			else
				local Count = mwscript.getItemCount({ reference = e.reference, item = "Gold_001" })
				tes3.player.data.OEA10.goldCount = tes3.player.data.OEA10.goldCount + Count
				tes3.removeItem({ reference = e.reference, item = "Gold_001", count = Count })
			end
		end
	end
end

local function Loaded(e)
	if (config.AltStart == true) and (config.Main == true) and (config.Money == true) and (config.Mech == true) then
		event.unregister("containerClosed", OnContainerClose)

		event.register("containerClosed", OnContainerClose)
	else
		event.unregister("containerClosed", OnContainerClose)
	end
end
event.register("loaded", Loaded)

function H.overrideScripts()
	if (config.AltStart == false) or (config.Mech == false) then
		return
	end

	if (config.Main == false) or (config.Money == false) then
		return
	end

	mwse.overrideScript("treestumpScript", HidingSpot)
	mwse.overrideScript("disableWulf", UncleScript)
end

return H