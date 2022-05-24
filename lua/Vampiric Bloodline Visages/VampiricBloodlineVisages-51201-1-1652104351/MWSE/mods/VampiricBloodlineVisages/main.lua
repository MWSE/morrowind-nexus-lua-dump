local defaultConfig = ({togglePlayer = false})
local config = mwse.loadConfig ("VampiricBloodlineVisages", defaultConfig)

local raceTable = {
	["argonian"] = true,
	["breton"] = true,
	["dark elf"] = true,
	["high elf"] = true,
	["imperial"] = true,
	["khajiit"] = true,
	["nord"] = true,
	["orc"] = true,
	["redguard"] = true,
	["wood elf"] = true
}

local function IntoExistence(e)
	if config.togglePlayer == false then
		if (e.reference == tes3.player) or (e.mobile == tes3.mobilePlayer) then
			return
		end
	end

	if (raceTable[e.reference.baseObject.race.id:lower()] == nil) then
		return
	end

	if (e.index ~= tes3.activeBodyPart.head) then
		return
	end

	if (e.bodyPart.vampiric == false) then
		return
	end

	local ClanValue = "nil"
	if e.reference.object.spells:contains("Vampire Aundae Specials") then
		ClanValue = "a"
	elseif e.reference.object.spells:contains("Vampire Berne Specials") then
		ClanValue = "b"
	elseif e.reference.object.spells:contains("Vampire Quarra Specials") then
		ClanValue = "q"
	end
	if ClanValue == "nil" then
		return
	end

	local RaceName = e.reference.baseObject.race.id:lower()
	local Sex = e.reference.baseObject.female and "f" or "m"
	local BodyPartId = ("b_v_%s_%s_head_%s"):format(RaceName, Sex, ClanValue)
	e.bodyPart = tes3.getObject(BodyPartId)

end

local function Loading()

	if (tes3.isModActive("VampiricBloodlineVisages.esp") == true) then
		event.register("bodyPartAssigned", IntoExistence)
	else
		mwse.log ("VampiricBloodlineVisages plugin not found")
	end

end

event.register("initialized", Loading)

local function registerModConfig()

	local template = mwse.mcm.createTemplate("VampiricBloodlineVisages")
	template:saveOnClose("VampiricBloodlineVisages", config)
	local page = template:createPage()
	local category = page:createCategory("Settings")
	category:createOnOffButton({
	label = "Enable player support",
	variable = mwse.mcm:createTableVariable{id = "togglePlayer", table = config}
	})
	mwse.mcm.register(template)

end

event.register("modConfigReady", registerModConfig)