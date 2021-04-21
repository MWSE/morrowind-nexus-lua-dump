local config = require("OEA.OEA9 Fail.config")

local template = mwse.mcm.createTemplate({ name = "Practice Makes Perfect" })
template:saveOnClose("Practice_Makes_Perfect", config)

local page = template:createPage()
page.noScroll = true
page.indent = 0
page.postCreate = function(self)
    self.elements.innerContainer.paddingAllSides = 10
end

local category = page:createCategory()
category.label = "What multiple of success EXP should failure yield for:"

local omega = category:createTextField{
	label = "Hand to Hand",
	variable = mwse.mcm:createTableVariable{
		id = "HandMult", 
		table = config
	},
	numbersOnly = true
}

local a = category:createTextField{
	label = "Weapon Skills",
	variable = mwse.mcm:createTableVariable{
		id = "WeaponMult", 
		table = config
	},
	numbersOnly = true
}

local b = category:createTextField{
	label = "Marksman",
	variable = mwse.mcm:createTableVariable{
		id = "AmmoMult", 
		table = config
	},
	numbersOnly = true
}

local c = category:createTextField{
	label = "Magic Skills",
	variable = mwse.mcm:createTableVariable{
		id = "MagicMult", 
		table = config
	},
	numbersOnly = true
}

local d = category:createTextField{
	label = "Alchemy",
	variable = mwse.mcm:createTableVariable{
		id = "AlchMult", 
		table = config
	},
	numbersOnly = true
}

local e = category:createTextField{
	label = "Armorer",
	variable = mwse.mcm:createTableVariable{
		id = "ArmMult", 
		table = config
	},
	numbersOnly = true
}

local f = category:createTextField{
	label = "Enchant",
	variable = mwse.mcm:createTableVariable{
		id = "EnchMult", 
		table = config
	},
	numbersOnly = true
}

local g = category:createTextField{
	label = "Security",
	variable = mwse.mcm:createTableVariable{
		id = "SecMult", 
		table = config
	},
	numbersOnly = true
}

local h = category:createTextField{
	label = "Speechcraft (Must load a save game to apply changes)",
	variable = mwse.mcm:createTableVariable{
		id = "SpeechMult", 
		table = config
	},
	numbersOnly = true
}

mwse.mcm.register(template)