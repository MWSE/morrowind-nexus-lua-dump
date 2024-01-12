
local config = require("Virnetch.protectiveHelmets.config")

local template = mwse.mcm.createTemplate("Protective Helmets")
template:saveOnClose("protective_helmets", config)

local page = template:createSideBarPage{
	label = "Settings",
	description = "Protective Helmets by Virnetch"
		.. "\n\n"
		.. "Automatically adds resistances to diseases and poisons when wearing a closed helmet."
}

local effectCategory = page:createCategory{
	label = "Effects",
	description = "Change the effects that full helmets add to the wearer."
		.. "\n\n"
		.. "Changing these options requires a restart for the changes to come to effect."
}

effectCategory:createOnOffButton{
	label = "Resist Common Disease",
	description = "Enable the Resist Common Disease effect on full helmets."
		.. "\n\n"
		.. "Default: On\n"
		.. "Changing this option requires a restart for the changes to come to effect.",
	variable = mwse.mcm.createTableVariable{
		id = "enableDisease",
		table = config
	}
}

effectCategory:createSlider{
	label = "Magnitude",
	description = "Change the magnitude for the Resist Common Disease effect."
		.. "\n\n"
		.. "Default: 10\n"
		.. "Changing this option requires a restart for the changes to come to effect.",
	max = 100,
	min = 0,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "diseaseMag",
		table = config
	}
}

effectCategory:createOnOffButton{
	label = "Resist Blight Disease",
	description = "Enable the Resist Blight Disease effect on full helmets."
		.. "\n\n"
		.. "Default: On\n"
		.. "Changing this option requires a restart for the changes to come to effect.",
	variable = mwse.mcm.createTableVariable{
		id = "enableBlight",
		table = config
	}
}

effectCategory:createSlider{
	label = "Magnitude",
	description = "Change the magnitude for the Resist Blight Disease effect."
		.. "\n\n"
		.. "Default: 10\n"
		.. "Changing this option requires a restart for the changes to come to effect.",
	max = 100,
	min = 0,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "blightMag",
		table = config
	}
}

effectCategory:createOnOffButton{
	label = "Resist Poison",
	description = "Enable the Resist Poison effect on full helmets."
		.. "\n\n"
		.. "Default: On\n"
		.. "Changing this option requires a restart for the changes to come to effect.",
	variable = mwse.mcm.createTableVariable{
		id = "enablePoison",
		table = config
	}
}

effectCategory:createSlider{
	label = "Magnitude",
	description = "Change the magnitude for the Resist Poison effect."
		.. "\n\n"
		.. "Default: 10\n"
		.. "Changing this option requires a restart for the changes to come to effect.",
	max = 100,
	min = 0,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "poisonMag",
		table = config
	}
}

template:createExclusionsPage{
	label = "Helmet Blacklist",
	description = "Helmets with a head part can be blacklisted here. Blacklisted helmets will NOT add resistance effects. Helmets in the unchanged list WILL add resistance effects. Blacklisting a plugin will remove any resistance effects from any helmet that the plugin adds/modifies.",
	variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config},
	leftListLabel = "Blacklist",
	rightListLabel = "Unchanged",
	filters = {
		{
			label = "Helmets",
			callback = function()
				local helmets = {}
				for armor in tes3.iterateObjects(tes3.objectType.armor) do
					if armor.slot == tes3.armorSlot.helmet and armor.parts then
						for _, part in pairs(armor.parts) do
							if part.type == tes3.activeBodyPart.head then
								table.insert(helmets, armor.id:lower())
								break
							end
						end
					end
				end
				table.sort(helmets)
				return helmets
			end
		},
		{
			label = "Plugins",
			type = "Plugin",
		}
	}
}

template:createExclusionsPage{
	label = "Helmet Whitelist",
	description = "Helmets without a head part can be whitelisted here. Whitelisted helmets WILL also add resistance effects. Helmets in the unchanged list will NOT add resistance effects. Whitelisting a plugin will add resistance effects to any helmet that the plugin adds/modifies.",
	variable = mwse.mcm.createTableVariable{ id = "whitelist", table = config},
	leftListLabel = "Whitelist",
	rightListLabel = "Unchanged",
	filters = {
		{
			label = "Helmets",
			callback = function()
				local helmets = {}
				for armor in tes3.iterateObjects(tes3.objectType.armor) do
					if armor.slot == tes3.armorSlot.helmet and armor.parts then
						local hasHeadPart = false
						for _, part in pairs(armor.parts) do
							if part.type == tes3.activeBodyPart.head then
								hasHeadPart = true
								break
							end
						end
						if not hasHeadPart then
							table.insert(helmets, armor.id:lower())
						end
					end
				end
				table.sort(helmets)
				return helmets
			end
		},
		{
			label = "Plugins",
			type = "Plugin",
		}
	}
}

mwse.mcm.register(template)