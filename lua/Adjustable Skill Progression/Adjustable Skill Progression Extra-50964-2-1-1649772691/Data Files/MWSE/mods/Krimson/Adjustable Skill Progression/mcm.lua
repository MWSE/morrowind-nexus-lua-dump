local EasyMCM = require("easyMCM.EasyMCM")
local config  = require("Krimson.Adjustable Skill Progression.config")

local template = EasyMCM.createTemplate("Adjustable Skill Progression")
template:saveOnClose("Krimson.Adjustable Skill Progression", config)
template:register()

local page = template:createSideBarPage({
	label = "Class Skills",
	description = "All settings work together for a fully customizable skill experience set up of your choice."
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

local settings0 = page:createCategory("\n\nSkill Levels\n")

settings0:createOnOffButton{
	label = "Skill Levels: ON/OFF",
	description = "Enables experience based on Level of Skill.",
	variable = mwse.mcm.createTableVariable{ id = "levelMod", table = config }
}

settings0:createSlider{
	label = "Skill Levels 1-25",
	description = "Change to multiply the Experience gained for for levels 1-25.\n\nDefault: 20\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "levelMod25", table = config}
}

settings0:createSlider{
	label = "Skill Levels 26-50",
	description = "Change to multiply the Experience gained for for levels 26-50.\n\nDefault: 15\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "levelMod50", table = config}
}

settings0:createSlider{
	label = "Skill Levels 51-75",
	description = "Change to multiply the Experience gained for for levels 51-75.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "levelMod75", table = config}
}

settings0:createSlider{
	label = "Skill Levels Over 75",
	description = "Change to multiply the Experience gained for for levels over 75.\n\nDefault: 5\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "levelMod100", table = config}
}

settings0:createOnOffButton{
	label = "Individual Skills: ON/OFF",
	description = "Enables experience based on Individual Skills.",
	variable = mwse.mcm.createTableVariable{ id = "indvMod", table = config }
}

settings0:createOnOffButton{
	label = "Individual Skill Levels: ON/OFF",
	description = "Enables experience based on Level of Individual Skills.",
	variable = mwse.mcm.createTableVariable{ id = "indvMod", table = config }
}

local page2 = template:createSideBarPage({
	label = "Individual Skills",
	description = "All settings work together for a fully customizable skill experience set up of your choice."
  })

local settings2 = page2:createCategory("Individual Skills\n")

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
	label = "Mysticism",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mysticismMod", table = config}
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

local page3 = template:createSideBarPage({
	label = "Ind Skill Levels : A",
	description = "All settings work together for a fully customizable skill experience set up of your choice."
  })

local settings3 = page3:createCategory("Acrobatics")

settings3:createSlider{
	label = "Acrobatics Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "acrobaticsLevelMod25", table = config}
}

settings3:createSlider{
	label = "Acrobatics Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "acrobaticsLevelMod50", table = config}
}

settings3:createSlider{
	label = "Acrobatics Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "acrobaticsLevelMod75", table = config}
}

settings3:createSlider{
	label = "Acrobatics Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "acrobaticsLevelMod100", table = config}
}

local settings4 = page3:createCategory("Alchemy")

settings4:createSlider{
	label = "Alchemy Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "alchemyLevelMod25", table = config}
}

settings4:createSlider{
	label = "Alchemy Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "alchemyLevelMod50", table = config}
}

settings4:createSlider{
	label = "Alchemy Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "alchemyLevelMod75", table = config}
}

settings4:createSlider{
	label = "Alchemy Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "alchemyLevelMod100", table = config}
}

local settings5 = page3:createCategory("Alteration")

settings5:createSlider{
	label = "Alteration Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "alterationLevelMod25", table = config}
}

settings5:createSlider{
	label = "Alteration Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "alterationLevelMod50", table = config}
}

settings5:createSlider{
	label = "Alteration Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "alterationLevelMod75", table = config}
}

settings5:createSlider{
	label = "Alteration Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "alterationLevelMod100", table = config}
}

local settings6 = page3:createCategory("Armorer")

settings6:createSlider{
	label = "Armorer Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "armorerLevelMod25", table = config}
}

settings6:createSlider{
	label = "Armorer Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "armorerLevelMod50", table = config}
}

settings6:createSlider{
	label = "Armorer Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "armorerLevelMod75", table = config}
}

settings6:createSlider{
	label = "Armorer Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "armorerLevelMod100", table = config}
}

local settings7 = page3:createCategory("Athletics")

settings7:createSlider{
	label = "Athletics Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "athleticsLevelMod25", table = config}
}

settings7:createSlider{
	label = "Athletics Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "athleticsLevelMod50", table = config}
}

settings7:createSlider{
	label = "Athletics Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "athleticsLevelMod75", table = config}
}

settings7:createSlider{
	label = "Athletics Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "athleticsLevelMod100", table = config}
}

local settings8 = page3:createCategory("Axe")

settings8:createSlider{
	label = "Axe Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "axeLevelMod25", table = config}
}

settings8:createSlider{
	label = "Axe Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "axeLevelMod50", table = config}
}

settings8:createSlider{
	label = "Axe Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "axeLevelMod75", table = config}
}

settings8:createSlider{
	label = "Axe Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "axeLevelMod100", table = config}
}

local page4 = template:createSideBarPage({
	label = "Ind Skill Levels : B-E",
	description = "All settings work together for a fully customizable skill experience set up of your choice."
  })

local settings9 = page4:createCategory("Block")

settings9:createSlider{
	label = "Block Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "blockLevelMod25", table = config}
}

settings9:createSlider{
	label = "Block Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "blockLevelMod50", table = config}
}

settings9:createSlider{
	label = "Block Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "blockLevelMod75", table = config}
}

settings9:createSlider{
	label = "Block Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "blockLevelMod100", table = config}
}

local settings10 = page4:createCategory("Blunt Weapon")

settings10:createSlider{
	label = "Blunt Weapon Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "bluntLevelMod25", table = config}
}

settings10:createSlider{
	label = "Blunt Weapon Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "bluntLevelMod50", table = config}
}

settings10:createSlider{
	label = "Blunt Weapon Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "bluntLevelMod75", table = config}
}

settings10:createSlider{
	label = "Blunt Weapon Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "bluntLevelMod100", table = config}
}

local settings11 = page4:createCategory("Conjuration")

settings11:createSlider{
	label = "Conjuration Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "conjurationLevelMod25", table = config}
}

settings11:createSlider{
	label = "Conjuration Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "conjurationLevelMod50", table = config}
}

settings11:createSlider{
	label = "Conjuration Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "conjurationLevelMod75", table = config}
}

settings11:createSlider{
	label = "Conjuration Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "conjurationLevelMod100", table = config}
}

local settings12 = page4:createCategory("Destruction")

settings12:createSlider{
	label = "Destruction Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "destructionLevelMod25", table = config}
}

settings12:createSlider{
	label = "Destruction Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "destructionLevelMod50", table = config}
}

settings12:createSlider{
	label = "Destruction Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "destructionLevelMod75", table = config}
}

settings12:createSlider{
	label = "Destruction Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "destructionLevelMod100", table = config}
}

local settings13 = page4:createCategory("Enchant")

settings13:createSlider{
	label = "Enchant Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "enchantLevelMod25", table = config}
}

settings13:createSlider{
	label = "Enchant Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "enchantLevelMod50", table = config}
}

settings13:createSlider{
	label = "Enchant Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "enchantLevelMod75", table = config}
}

settings13:createSlider{
	label = "Enchant Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "enchantLevelMod100", table = config}
}

local page5 = template:createSideBarPage({
	label = "Ind Skill Levels : H-L",
	description = "All settings work together for a fully customizable skill experience set up of your choice."
  })

local settings14 = page5:createCategory("Hand to Hand")

settings14:createSlider{
	label = "Hand to Hand Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "handLevelMod25", table = config}
}

settings14:createSlider{
	label = "Hand to Hand Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "handLevelMod50", table = config}
}

settings14:createSlider{
	label = "Hand to Hand Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "handLevelMod75", table = config}
}

settings14:createSlider{
	label = "Hand to Hand Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "handLevelMod100", table = config}
}

local settings15 = page5:createCategory("Heavy Armor")

settings15:createSlider{
	label = "Heavy Armor Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "heavyLevelMod25", table = config}
}

settings15:createSlider{
	label = "Heavy Armor Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "heavyLevelMod50", table = config}
}

settings15:createSlider{
	label = "Heavy Armor Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "heavyLevelMod75", table = config}
}

settings15:createSlider{
	label = "Heavy Armor Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "heavyLevelMod100", table = config}
}

local settings16 = page5:createCategory("Illusion")

settings16:createSlider{
	label = "Illusion Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "illusionLevelMod25", table = config}
}

settings16:createSlider{
	label = "Illusion Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "illusionLevelMod50", table = config}
}

settings16:createSlider{
	label = "Illusion Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "illusionLevelMod75", table = config}
}

settings16:createSlider{
	label = "Illusion Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "illusionLevelMod100", table = config}
}

local settings17 = page5:createCategory("Light Armor")

settings17:createSlider{
	label = "Light Armor Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "lightLevelMod25", table = config}
}

settings17:createSlider{
	label = "Light Armor Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "lightLevelMod50", table = config}
}

settings17:createSlider{
	label = "Light Armor Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "lightLevelMod75", table = config}
}

settings17:createSlider{
	label = "Light Armor Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "lightLevelMod100", table = config}
}

local settings18 = page5:createCategory("Long Blade")

settings18:createSlider{
	label = "Long Blade Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "longLevelMod25", table = config}
}

settings18:createSlider{
	label = "Long Blade Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "longLevelMod50", table = config}
}

settings18:createSlider{
	label = "Long Blade Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "longLevelMod75", table = config}
}

settings18:createSlider{
	label = "Long Blade Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "longLevelMod100", table = config}
}

local page6 = template:createSideBarPage({
	label = "Ind Skill Levels : M-R",
	description = "All settings work together for a fully customizable skill experience set up of your choice."
  })

local settings19 = page6:createCategory("Marksman")

settings19:createSlider{
	label = "Marksman Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "marksmanLevelMod25", table = config}
}

settings19:createSlider{
	label = "Marksman Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "marksmanLevelMod50", table = config}
}

settings19:createSlider{
	label = "Marksman Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "marksmanLevelMod75", table = config}
}

settings19:createSlider{
	label = "Marksman Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "marksmanLevelMod100", table = config}
}

local settings20 = page6:createCategory("Medium Armor")

settings20:createSlider{
	label = "Medium Armor Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mediumLevelMod25", table = config}
}

settings20:createSlider{
	label = "Medium Armor Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mediumLevelMod50", table = config}
}

settings20:createSlider{
	label = "Medium Armor Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mediumLevelMod75", table = config}
}

settings20:createSlider{
	label = "Medium Armor Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mediumLevelMod100", table = config}
}

local settings21 = page6:createCategory("Mercantile")

settings21:createSlider{
	label = "Mercantile Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mercantileLevelMod25", table = config}
}

settings21:createSlider{
	label = "Mercantile Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mercantileLevelMod50", table = config}
}

settings21:createSlider{
	label = "Mercantile Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mercantileLevelMod75", table = config}
}

settings21:createSlider{
	label = "Mercantile Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mercantileLevelMod100", table = config}
}

local settings22 = page6:createCategory("Mysticism")

settings22:createSlider{
	label = "Mysticism Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mysticismLevelMod25", table = config}
}

settings22:createSlider{
	label = "Mysticism Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mysticismLevelMod50", table = config}
}

settings22:createSlider{
	label = "Mysticism Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mysticismLevelMod75", table = config}
}

settings22:createSlider{
	label = "Mysticism Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "mysticismLevelMod100", table = config}
}

local settings23 = page6:createCategory("Restoration")

settings23:createSlider{
	label = "Restoration Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "restorationLevelMod25", table = config}
}

settings23:createSlider{
	label = "Restoration Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "restorationLevelMod50", table = config}
}

settings23:createSlider{
	label = "Restoration Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "restorationLevelMod75", table = config}
}

settings23:createSlider{
	label = "Restoration Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "restorationLevelMod100", table = config}
}

local page7 = template:createSideBarPage({
	label = "Ind Skill Levels : S-U",
	description = "All settings work together for a fully customizable skill experience set up of your choice."
  })

local settings24 = page7:createCategory("Security")

settings24:createSlider{
	label = "Security Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "securityLevelMod25", table = config}
}

settings24:createSlider{
	label = "Security Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "securityLevelMod50", table = config}
}

settings24:createSlider{
	label = "Security Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "securityLevelMod75", table = config}
}

settings24:createSlider{
	label = "Security Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "securityLevelMod100", table = config}
}

local settings25 = page7:createCategory("Short Blade")

settings25:createSlider{
	label = "Short Blade Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "shortLevelMod25", table = config}
}

settings25:createSlider{
	label = "Short Blade Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "shortLevelMod50", table = config}
}

settings25:createSlider{
	label = "Short Blade Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "shortLevelMod75", table = config}
}

settings25:createSlider{
	label = "Short Blade Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "shortLevelMod100", table = config}
}

local settings26 = page7:createCategory("Sneak")

settings26:createSlider{
	label = "Sneak Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "sneakLevelMod25", table = config}
}

settings26:createSlider{
	label = "Sneak Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "sneakLevelMod50", table = config}
}

settings26:createSlider{
	label = "Sneak Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "sneakLevelMod75", table = config}
}

settings26:createSlider{
	label = "Sneak Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "sneakLevelMod100", table = config}
}

local settings27 = page7:createCategory("Spear")

settings27:createSlider{
	label = "Spear Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "spearLevelMod25", table = config}
}

settings27:createSlider{
	label = "Spear Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "spearLevelMod50", table = config}
}

settings27:createSlider{
	label = "Spear Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "spearLevelMod75", table = config}
}

settings27:createSlider{
	label = "Spear Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "spearLevelMod100", table = config}
}

local settings28 = page7:createCategory("Speechcraft")

settings28:createSlider{
	label = "Speechcraft Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "speechcraftLevelMod25", table = config}
}

settings28:createSlider{
	label = "Speechcraft Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "speechcraftLevelMod50", table = config}
}

settings28:createSlider{
	label = "Speechcraft Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "speechcraftLevelMod75", table = config}
}

settings28:createSlider{
	label = "Speechcraft Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "speechcraftLevelMod100", table = config}
}

local settings29 = page7:createCategory("Unarmored")

settings29:createSlider{
	label = "Unarmored Levels 1-25",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "unarmoredLevelMod25", table = config}
}

settings29:createSlider{
	label = "Unarmored Levels 26-50",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "unarmoredLevelMod50", table = config}
}

settings29:createSlider{
	label = "Unarmored Levels 51-75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "unarmoredLevelMod75", table = config}
}

settings29:createSlider{
	label = "Unarmored Levels Over 75",
	description = "Change to multiply the Experience gained for the listed skill.\n\nDefault: 10\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{id = "unarmoredLevelMod100", table = config}
}