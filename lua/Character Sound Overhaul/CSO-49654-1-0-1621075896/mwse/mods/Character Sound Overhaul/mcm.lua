local config = require("Character Sound Overhaul.config")

local template = mwse.mcm.createTemplate{name = "Character Sound Overhaul", headerImagePath = "\\Textures\\Anu\\CSO\\CSO_Logo.tga"}
template:saveOnClose("Character Sound Overhaul", config)
template:register()


-- Create Pages


local function createPage(label)
	local page = template:createSideBarPage{
		label = label,
		noScroll = true,
	}
	page.sidebar:createInfo{
		text = "Character Sound Overhaul\n\nA dynamic sound overhaul for the character interactions of Morrowind.\n\nUse this configuration menu to customize your in-game soundscape.\n\nHover over individual settings for more information."
	}
	page.sidebar:createHyperLink {
		text = "Made by Anumaril21",
		exec = "start https://www.nexusmods.com/morrowind/users/60236996?tab=user+files",
		postCreate = function(self)
			self.elements.outerContainer.borderAllSides = self.indent
			self.elements.outerContainer.alignY = 1.0
			--self.elements.outerContainer.layoutHeightFraction = 1.0
			self.elements.info.layoutOriginFractionX = 0.5
		end,
	}
	return page
end

local pageMovement = createPage("Movement Settings")
local pageCombat = createPage("Combat Settings")
local pageItems = createPage("Item Settings")
local pageMisc = createPage("Misc Settings")


-- Movement Category


local categoryMovement = pageMovement:createCategory{
	label = "Movement Sound Settings",
	description = ""
}
categoryMovement:createOnOffButton{
	label = "Enable Movement Sounds",
	description = "Enable Movement Sounds\n\nDetermines whether sound effects based on the terrain will be played during movement.\n\nDefault: On",
	variable = mwse.mcm:createTableVariable{id = "footstepSounds", table = config}
}
categoryMovement:createSlider{
	label = "Player Movement Volume: %s%%",
	description = "Player Movement Volume\n\nDetermines how loud the player's movement sounds are.\n\nDefault: 65%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "PCfootstepVolume", table = config}
}
categoryMovement:createSlider{
	label = "NPC Movement Volume: %s%%",
	description = "NPC Movement Volume\n\nDetermines how loud the movement sounds of NPCs and creatures are.\n\nDefault: 85%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "NPCfootstepVolume", table = config}
}


-- Armor Category


local categoryArmor = pageMovement:createCategory{
	label = "Armor Sound Settings",
	description = ""
}
categoryArmor:createOnOffButton{
	label = "Enable Armor Sounds",
	description = "Enable Armor Sounds\n\nDetermines whether sound effects based on the actor's equipped armor will be played during movement.\n\nDefault: On",
	variable = mwse.mcm:createTableVariable{id = "armorSounds", table = config}
}
categoryArmor:createOnOffButton{
	label = "Enable Alternative Armor Weight Mechanic",
	description = "Enable Alternative Armor Weight Mechanic\n\nDetermines whether armor sound effects are based on the equipped cuirass for all races. In vanilla, boots determined the armor weight for most races while cuirasses determined it for beast races.\n\nDefault: Off",
	variable = mwse.mcm:createTableVariable{id = "altArmor", table = config}
}
categoryArmor:createSlider{
	label = "Player Armor Volume: %s%%",
	description = "Player Armor Volume\n\nDetermines how loud the player's armor movement sounds are.\n\nDefault: 65%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "PCarmorVolume", table = config}
}
categoryArmor:createSlider{
	label = "NPC Armor Volume: %s%%",
	description = "NPC Armor Volume\n\nDetermines how loud the armor movement sounds of NPCs and creatures are.\n\nDefault: 85%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "NPCarmorVolume", table = config}
}


-- Weather Category


local categoryWeather = pageMovement:createCategory{
	label = "Weather Sound Settings",
	description = ""
}
categoryWeather:createOnOffButton{
	label = "Enable Weather Sounds",
	description = "Enable Weather Sounds\n\nDetermines whether sound effects based on the current weather will be played during movement.\n\nDefault: On",
	variable = mwse.mcm:createTableVariable{id = "weatherSounds", table = config}
}
categoryWeather:createSlider{
	label = "Player Weather Sound Volume: %s%%",
	description = "Player Weather Sound Volume\n\nDetermines how loud the weather effects on the player's movement are.\n\nDefault: 60%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "PCweatherFootstepVolume", table = config}
}
categoryWeather:createSlider{
	label = "NPC Weather Sound Volume: %s%%",
	description = "NPC Weather Sound Volume\n\nDetermines how loud the weather effects on the movement of NPCs and creatures are.\n\nDefault: 80%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "NPCweatherFootstepVolume", table = config}
}


-- Combat Category


local categoryCombat = pageCombat:createCategory{
	label = "Combat Sound Settings",
	description = ""
}
categoryCombat:createOnOffButton{
	label = "Enable Weapon Sounds",
	description = "Enable Weapon Sounds\n\nDetermines whether sound effects are enabled for equipping, sheathing, swinging, and damaging with weapons.\n\nDefault: On",
	variable = mwse.mcm:createTableVariable{id = "weaponSounds", table = config}
}
categoryCombat:createSlider{
	label = "Player Weapon Volume: %s%%",
	description = "Player Weapon Volume\n\nDetermines how loud the player's weapon sounds are.\n\nDefault: 65%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "PCweaponVolume", table = config}
}
categoryCombat:createSlider{
	label = "NPC Weapon Volume: %s%%",
	description = "NPC Weapon Volume\n\nDetermines how loud the weapon sounds of NPCs and creatures are.\n\nDefault: 85%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "NPCweaponVolume", table = config}
}


-- Items Category


local categoryItems = pageItems:createCategory{
	label = "Item Sound Settings",
	description = ""
}
categoryItems:createOnOffButton{
	label = "Enable Item Inventory Sounds",
	description = "Enable Item Inventory Sounds\n\nDetermines whether sound effects are enabled for inventory, item pickup, and item dropping sounds.\n\nDefault: On",
	variable = mwse.mcm:createTableVariable{id = "itemSounds", table = config}
}
categoryItems:createOnOffButton{
	label = "Enable Item Use Sounds",
	description = "Enable Item Use Sounds\n\nDetermines whether sound effects are enabled for actions such as drinking potions and repairing items.\n\nDefault: On",
	variable = mwse.mcm:createTableVariable{id = "itemUseSounds", table = config}
}
categoryItems:createSlider{
	label = "Item Sound Volume: %s%%",
	description = "Item Sound Volume\n\nDetermines how loud inventory and item use sounds are.\n\nDefault: 75%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "itemVolume", table = config}
}


-- Misc Category


local categoryMisc = pageMisc:createCategory{
	label = "Misc Sound Settings",
	description = ""
}
categoryMisc:createOnOffButton{
	label = "Enable Journal Sounds",
	description = "Enable Journal Sounds\n\nDetermines whether sound effects are enabled for whenever the journal updates.\n\nDefault: On",
	variable = mwse.mcm:createTableVariable{id = "journalSounds", table = config}
}
categoryMisc:createOnOffButton{
	label = "Enable Body/Corpse Looting Sounds",
	description = "Enable Body/Corpse Looting Sounds\n\nDetermines whether sound effects are enabled for entering and exiting the loot screen of dead actors and corpse containers.\n\nDefault: On",
	variable = mwse.mcm:createTableVariable{id = "lootSounds", table = config}
}
categoryMisc:createOnOffButton{
	label = "Enable Vanilla Thumps",
	description = "Enable Vanilla Thumps\n\nKeeps the most important feature in the game from being altered.\n\nDefault: Off",
	variable = mwse.mcm:createTableVariable{id = "thumps", table = config}
}
categoryMisc:createSlider{
	label = "Misc Sound Volume: %s%%",
	description = "Misc Sound Volume\n\nDetermines how loud selected miscellaneous sounds are.\n\nDefault: 75%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "miscVolume", table = config}
}
