local EasyMCM = require("easyMCM.EasyMCM")
local config  = require("Krimson.Adjustable Skill Progression.config")

local template = EasyMCM.createTemplate("Adjustable Skill Progression")
template:saveOnClose("Krimson.Adjustable Skill Progression", config)
template:register()

local page = template:createSideBarPage({
	label = "Class Skills",
	description = "Class, Level, and Individual skills all work together for a fully customizable skill experience set up of your choice."
})

local settings = page:createCategory("Exp = Slider value / 10\n\nFrom 0 to 10x, adjustable by 0.1 increments.\n\nex. 5 = 0.5x, 10 = 1x, 50 = 5x, 75 = 7.5x, 100 = 10x\n\n\n\nClass Skills/Skill Levels\n")

settings:createOnOffButton{
	label = "Class Skills: ON/OFF",
	description = "Enables experience based on Type of Skill.",
	variable = mwse.mcm.createTableVariable{ id = "classMod", table = config }
}

settings:createSlider{
	label = "Major Skills",
	description = "Change to multiply the Experience gained for all Major skills.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "majorMod", table = config}
}

settings:createSlider{
	label = "Minor Skills",
	description = "Change to multiply the Experience gained for all Minor skills.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "minorMod", table = config}
}

settings:createSlider{
	label = "Miscellaneous Skills",
	description = "Change to multiply the Experience gained for all Miscellaneous skills.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "miscMod", table = config}
}

local settings3 = page:createCategory("\n\nSkill Levels\n")

settings3:createOnOffButton{
	label = "Skill Levels: ON/OFF",
	description = "Enables experience based on Level of Skill.",
	variable = mwse.mcm.createTableVariable{ id = "levelMod", table = config }
}

settings3:createSlider{
	label = "Skill Levels 1-25",
	description = "Change to multiply the Experience gained for for levels 1-25.\n\nDefault: 20\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "levelMod25", table = config}
}

settings3:createSlider{
	label = "Skill Levels 26-50",
	description = "Change to multiply the Experience gained for for levels 26-50.\n\nDefault: 15\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "levelMod50", table = config}
}

settings3:createSlider{
	label = "Skill Levels 51-75",
	description = "Change to multiply the Experience gained for for levels 51-75.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "levelMod75", table = config}
}

settings3:createSlider{
	label = "Skill Levels 76 and over",
	description = "Change to multiply the Experience gained for for levels over 75.\n\nDefault: 5\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "levelMod100", table = config}
}

local page2 = template:createSideBarPage({
	label = "Individual Skills",
	description = "Class, Level, and Individual skills all work together for a fully customizable skill experience set up of your choice."
  })

local settings2 = page2:createCategory("Individual Skills\n")

settings2:createOnOffButton{
	label = "Individual Skills: ON/OFF",
	description = "Enables experience based on Individual Skills.",
	variable = mwse.mcm.createTableVariable{ id = "indvMod", table = config }
}

settings2:createSlider{
	label = "Acrobatics",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "acrobaticsMod", table = config}
}

settings2:createSlider{
	label = "Alchemy",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "alchemyMod", table = config}
}

settings2:createSlider{
	label = "Alteration",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "alterationMod", table = config}
}

settings2:createSlider{
	label = "Armorer",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "armorerMod", table = config}
}

settings2:createSlider{
	label = "Athletics",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "athleticsMod", table = config}
}

settings2:createSlider{
	label = "Axe",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "axeMod", table = config}
}

settings2:createSlider{
	label = "Block",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "blockMod", table = config}
}

settings2:createSlider{
	label = "Blunt Weapon",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "bluntMod", table = config}
}

settings2:createSlider{
	label = "Conjuration",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "conjurationMod", table = config}
}

settings2:createSlider{
	label = "Destruction",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "destructionMod", table = config}
}

settings2:createSlider{
	label = "Enchant",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "enchantMod", table = config}
}

settings2:createSlider{
	label = "Hand to Hand",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "handMod", table = config}
}

settings2:createSlider{
	label = "Heavy Armor",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "heavyMod", table = config}
}

settings2:createSlider{
	label = "Illusion",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "illusionMod", table = config}
}

settings2:createSlider{
	label = "Light Armor",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "lightMod", table = config}
}

settings2:createSlider{
	label = "Long Blade",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "longMod", table = config}
}

settings2:createSlider{
	label = "Marksman",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "marksmanMod", table = config}
}

settings2:createSlider{
	label = "Medium Armor",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mediumMod", table = config}
}

settings2:createSlider{
	label = "Mercantile",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mercantileMod", table = config}
}

settings2:createSlider{
	label = "Mystcism",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mystcismMod", table = config}
}

settings2:createSlider{
	label = "Restoration",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "restorationMod", table = config}
}

settings2:createSlider{
	label = "Security",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "securityMod", table = config}
}

settings2:createSlider{
	label = "Short Blade",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "shortMod", table = config}
}

settings2:createSlider{
	label = "Sneak",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "sneakMod", table = config}
}

settings2:createSlider{
	label = "Spear",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "spearMod", table = config}
}

settings2:createSlider{
	label = "Speechcraft",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "speechcraftMod", table = config}
}

settings2:createSlider{
	label = "Unarmored",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "unarmoredMod", table = config}
}