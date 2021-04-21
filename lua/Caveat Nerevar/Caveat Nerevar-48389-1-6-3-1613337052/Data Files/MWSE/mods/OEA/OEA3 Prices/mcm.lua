local config = require("OEA.OEA3 Prices.config")

local template = mwse.mcm.createTemplate("Caveat Nerevar")
template:saveOnClose("Caveat_Nerevar", config)

local sidebarDefault = 
(
	"The price formula is as follows: (X)*(Old Value/log(Old Value/Y)). " ..
	"This will only apply to items whose original price was greater than 10*Y. " ..
	"The price is visible instantly for inventory items, " ..
	"and upon looking at, looking away, and then looking back at something in the world. " ..
	"To apply formula changes, or turn the price changing on or off, you need to restart the game."
)

local page = template:createSideBarPage
{
	description = sidebarDefault,
	label = "Pricing"
}

page:createYesNoButton{
	label = "Enable Price Changing?",
	variable = mwse.mcm:createTableVariable{
		id = "TurnedOn", 
		table = config
	},
	description = "This toggles whether prices are modified at all."
}

page:createYesNoButton{
	label = "Natural Logarithm?",
	variable = mwse.mcm:createTableVariable{
		id = "Logarithm", 
		table = config
	},
	description = "If yes, the formula uses Log base e. If no, it uses Log base 10. The latter decreases prices less."
}

page:createTextField{
	label = "X Value",
	variable = mwse.mcm:createTableVariable{
		id = "X1", 
		table = config
	},
	numbersOnly = true,
	description = "This determines the value of the variable X in the formula."
}

page:createTextField{
	label = "Y Value",
	variable = mwse.mcm:createTableVariable{
		id = "Y2", 
		table = config
	},
	numbersOnly = true,
	description = "This determines the value of the variable Y in the formula."
}



local sidebarDefault2 = 
(
	"This page allows you to modify some price-affecting Game Settings (GMSTs). These values are percentages of the original for convenience. " ..
	"Each percentage is applied to the vanilla value, overwriting all ESPs. To see changes made, you need to restart the game."
)

local page2 = template:createSideBarPage
{
	description = sidebarDefault2,
	label = "GMSTs"
}

page2:createTextField{
	label = "Travel Cost Percentage",
	variable = mwse.mcm:createTableVariable{
		id = "Travel", 
		table = config
	},
	numbersOnly = true,
	description = "This determines the percentage by which non-Mage travel costs are modified."
}

page2:createTextField{
	label = "Mage Travel Cost Percentage",
	variable = mwse.mcm:createTableVariable{
		id = "TravelMage", 
		table = config
	},
	numbersOnly = true,
	description = "This determines the percentage by which Mage's Guild travel costs are modified."
}

page2:createTextField{
	label = "Training Cost Percentage",
	variable = mwse.mcm:createTableVariable{
		id = "Train", 
		table = config
	},
	numbersOnly = true,
	description = "This determines the percentage by which training costs are modified."
}

page2:createTextField{
	label = "Enchanting Cost Percentage",
	variable = mwse.mcm:createTableVariable{
		id = "Enchant", 
		table = config
	},
	numbersOnly = true,
	description = "This determines the percentage by which enchanting costs are modified."
}

local sidebarDefault3 = 
(
	"These are various other settings you can modify."
)

local page3 = template:createSideBarPage
{
	description = sidebarDefault3,
	label = "Misc."
}

page3:createTextField{
	label = "Mercantile Increase",
	variable = mwse.mcm:createTableVariable{
		id = "Merch", 
		table = config
	},
	numbersOnly = true,
	description = "This determines the amount by which all merchants' Mercantile skill is increased. To see changes made, you must load a save game."
}

page3:createTextField{
	label = "Barter Gold Multiplier",
	variable = mwse.mcm:createTableVariable{
		id = "BarterGold", 
		table = config
	},
	numbersOnly = true,
	description = "All merchants' barter gold is multiplied by this amount. To see changes made, you must restart the game."
}

page3:createYesNoButton{
	label = "Modify Dialogue Gold?",
	variable = mwse.mcm:createTableVariable{
		id = "Dialogue", 
		table = config
	},
	description = "Sums of Gold you receive in dialogue will be adjusted to match your price formula. This does not affect Gold gained via regular scripts. "..
	"If you have price changing off, this will not activate no matter what. Changes made are applied instantly."
}

mwse.mcm.register(template)
