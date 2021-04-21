local config = require("OEA.OEA10 Fresh.config")
local DoOnce

local function OnMobileActivated(e)
	if (e.reference ~= nil) and (e.reference.cell.id == "Imperial Prison Ship") then
		if (DoOnce == nil) or (DoOnce == 0) then
			if (mwscript.getItemCount({ reference = tes3.player, item = "ring_keley" }) > 0) then
				return
			end
			DoOnce = 1
			mwscript.positionCell({
				reference = tes3.player,
				cell = "Seyda Neen, Fargoth's House",
				x = 1,
				y = 1,
				z = 1,
				rotation = 160 --so you start off looking at the door, and uiObjectTooltip will trigger
			})
		end
	end

	if (e.reference ~= nil) and (e.reference.baseObject.id == "fargoth") then
		mwscript.disable({ reference = e.reference })
	end

	if (e.reference ~= nil) and (config.Dial == true) then
		if (string.sub(e.reference.cell.id, 1, 10) == "Seyda Neen") then
			e.mobile.talkedTo = true
		end
	end
end

local function DisableThings()
	mwscript.disable({ reference = "chargen_crate_01_misc01" })
	mwscript.disable({ reference = "chargen_lantern_03_sway" })
	mwscript.disable({ reference = "chargenbarrel_01_drinks" })
	mwscript.disable({ reference = "chargen_chest_02_empty" })
	mwscript.disable({ reference = "chargen_crate_01_empty" })
	mwscript.disable({ reference = "chargen_ship_trapdoor" })
	mwscript.disable({ reference = "chargen boat guard 1" })
	mwscript.disable({ reference = "chargen boat guard 2" })
	mwscript.disable({ reference = "chargen statssheet" })
	mwscript.disable({ reference = "chargen dock guard" })
	mwscript.disable({ reference = "chargen_cabindoor" })
	mwscript.disable({ reference = "chargen_barrel_01" })
	mwscript.disable({ reference = "chargen_barrel_02" })
	mwscript.disable({ reference = "chargen_crate_01" })
	mwscript.disable({ reference = "chargen_crate_02" })
	mwscript.disable({ reference = "chargen_plank" })
	mwscript.disable({ reference = "chargen boat" })

	tes3.setLockLevel({ reference = "chargen door hall", level = 0 })
	tes3.unlock({ reference = "chargen door hall" })
end

local function CellChanged(e)
	if (e.cell.id == "Seyda Neen") then
		DisableThings()

		for door in e.cell:iterateReferences(tes3.objectType.door) do
			if (door.destination.cell.id == "Seyda Neen, Fargoth's House") then
				if (door.modified == false) then
					tes3.setLockLevel({ reference = door, level = 0 })
					tes3.unlock({ reference = door })

					if (door.attachments ~= nil) and (door.attachments.variables ~= nil) then
						door.attachments.variables.owner = nil
					end

					door.lockNode.key = tes3.getObject("OEA_Fargoth_Key")
				end
				door.modified = true
				break
			end
		end

		for container in e.cell:iterateReferences(tes3.objectType.container) do
			if (container.baseObject.id == "flora_treestump_unique") and (container.modified == false) then
				if (container.attachments ~= nil) and (container.attachments.variables ~= nil) then
					container.attachments.variables.owner = nil
					container.modified = true
				end
			end

			if (container.baseObject.id == "chargen barrel fatigue") and (container.modified == false) then
				tes3.removeItem({ reference = container, item = "ring_keley", count = 1 })
				container.modified = true
			end
		end
	end


	if (e.cell.id == "Seyda Neen, Census and Excise Office") then
		for door in e.cell:iterateReferences(tes3.objectType.door) do
			tes3.setLockLevel({ reference = door, level = 0 })
			tes3.unlock({ reference = door })
		end
	end

	if (DoOnce == nil) then
		return
	end

	if (e.cell.id ~= "Seyda Neen, Fargoth's House") then
		return
	end

	for ref in e.cell:iterateReferences() do
		if (tes3.getOwner({ reference = ref }) ~= nil) then
			if (ref.attachments ~= nil) and (ref.attachments.variables ~= nil) then
				ref.attachments.variables.owner = nil
				ref.modified = true
			end
		end

		if (tes3.getLockLevel({ reference = ref }) ~= nil) then
			tes3.setLockLevel({ reference = ref, level = 0 })
			tes3.unlock({ reference = ref })
			ref.modified = true
		end
	end

	mwscript.removeItem({ reference = tes3.player, item = "common_shirt_01", count = 1 })
	mwscript.removeItem({ reference = tes3.player, item = "common_shoes_01", count = 1 })
	mwscript.removeItem({ reference = tes3.player, item = "common_pants_01", count = 1 })

	mwscript.addItem({ reference = tes3.player, item = "common_shirt_04", count = 1 })
	mwscript.addItem({ reference = tes3.player, item = "common_pants_04", count = 1 })
	mwscript.addItem({ reference = tes3.player, item = "common_shoes_04", count = 1 })
	mwscript.addItem({ reference = tes3.player, item = "torch_infinite_time", count = 1 })

	mwscript.addItem({ reference = tes3.player, item = "ring_keley", count = 1 })
	mwscript.addItem({ reference = tes3.player, item = "Gold_001", count = 300 })
	mwscript.addItem({ reference = tes3.player, item = "pick_journeyman_01", count = 1 })

	tes3.addItem({ reference = tes3.player, item = "OEA_Fargoth_Key", count = 1 })

	tes3.runLegacyScript({ command = "EnableRaceMenu" })

	DoOnce = nil
end

local function InfoText(e)
	if (config.AltStart == false) then
		return
	end

	if (e.info.actor ~= nil) and (e.info.actor.id == "hrisskar flat-foot") then
		if (e.info.type == 2) then --type 2 is greetings
			e.text = "Yeah, yeah, I get it, you're here to gloat. But you're the last person I want to see right now."
			return
		end
	elseif (e.info.actor ~= nil) and (e.info.actor.id == "dagoth_ur_1") then
		if (e.info.type == 2) then --type 2 is greetings
			e.text = "Welcome Nere--wait, you're not Nerevar! Who are you?"
		else
			e.text = "Leave, outlander, before it is too late for my mercy."
		end
	elseif (e.info.actor ~= nil) and (e.info.actor.id == "chargen class") then
		if (e.info.type == 2) then --type 2 is greetings
			e.text = "Hmm, I think I remember you. You're...Fargoth, right? What are you doing here?"
		end
	end
end

local function Loaded(e)
	if (config.AltStart == true) then
		event.unregister("cellChanged", CellChanged)
		event.unregister("mobileActivated", OnMobileActivated)
		event.unregister("infoGetText", InfoText)

		event.register("cellChanged", CellChanged)
		event.register("mobileActivated", OnMobileActivated)

		if (config.Dial == true) then
			event.register("infoGetText", InfoText)
		end
	else
		event.unregister("cellChanged", CellChanged)
		event.unregister("mobileActivated", OnMobileActivated)
		event.unregister("infoGetText", InfoText)
	end
end
event.register("loaded", Loaded)

local function Load(e)
	if (config.AltStart == true) and (config.Dial == true) then
		event.unregister("infoGetText", InfoText)
		event.register("infoGetText", InfoText)
	else
		event.unregister("infoGetText", InfoText)
	end
end
event.register("load", Load)

if (config.AltStart == true) then
	event.register("cellChanged", CellChanged)
	event.register("mobileActivated", OnMobileActivated)

	if (config.Dial == true) then
		event.register("infoGetText", InfoText)
	end
end
