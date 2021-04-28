local parts = {
	head = 0,
	hair = 1
}
local configPath = "More_Heads_Lua"

local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = {
	IsBlocked = {
		["arrille"] = true,
		["chargen class"] = true,
		["chargen name"] = true,
		["fargoth"] = true,
		["m'aiq"] = true
		}
	}
end

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
	if (e.reference == tes3.player) or (e.mobile == tes3.mobilePlayer) then
		return
	end
	if (e.index ~= tes3.activeBodyPart.head) then
		return
	end
	if (raceTable[e.reference.baseObject.race.id:lower()] == nil) then
		return
	end
	if (e.reference.baseObject.isEssential == true) then
		return
	end
	if (e.bodyPart.vampiric == true) then
		return
	end
	if (mwscript.getSpellEffects({ reference = e.reference, spell = "werewolf vision" }) == true) then
		return
	end

	local ID = e.reference.baseObject.id
	if e.object then
		if e.object.objectType == tes3.objectType.armor and e.object.slot == tes3.armorSlot.helmet then
			if e.bodyPart.part == parts.head then
				return
			end
		end
	end
	if (config.IsBlocked[ID:lower()]) or (config.IsBlocked[e.reference.baseObject.sourceMod:lower()]) then
		return
	end
	if (e.reference.data.OEA2H ~= nil) then
		e.bodyPart = tes3.getObject(e.reference.data.OEA2H.BodyPartId)
		return
	end
	local RaceValue = math.random(20)
	local RaceName = e.reference.baseObject.race.id:lower()
	local Sex = e.reference.baseObject.female and "f" or "m"
	local BodyPartId = ("b_n_%s_%s_head_%02d"):format(RaceName, Sex, RaceValue)
	e.bodyPart = tes3.getObject(BodyPartId)
	e.reference.data.OEA2H = { BodyPartId = BodyPartId }
end


local function Loading(e)
	if (tes3.isModActive("MoreHeads.esp") == false) then
		tes3.messageBox "You need to activate MoreHeads.esp. Please exit the game if you want to see different heads."
		return	
	elseif (tes3.isModActive("MoreHeads.esp") == true) then
		event.register("bodyPartAssigned", IntoExistence)
	end
end
event.register("initialized", Loading)

----MCM
local function registerModConfig()

	local template = mwse.mcm.createTemplate({ name = "More Heads Lua" })
	template:saveOnClose(configPath, config)

	local hotkey = template:createExclusionsPage{
		label = "Head Blacklist",
		description = "Select the NPCs and plugins whose heads will never change.",
		showAllBlocked = false,
        variable = mwse.mcm:createTableVariable{
            id = "IsBlocked",
            table = config,
        },

	    filters = {
            {
                label = "Plugins",
                type = "Plugin",
            },
            {
                label = "NPCs",
				type = "Object",
				objectType = tes3.objectType.npc
            }
        }
    }

    mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)