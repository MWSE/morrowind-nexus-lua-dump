local config = require("SUDS.config")
local template = mwse.mcm.createTemplate("SUDS")
template:saveOnClose("SUDS", config)
local page = template:createSideBarPage()
page.label = "Settings"
page.description =(
	"SUDS\n\n" ..
	"Scaling Universal Damage Sponger\n\n" ..
	".\n\n" ..
	"Actors gain health bonus per player level\n\n" ..
	"Actors with health greater than cap are ignored.\n\n" ..
	"Health bonus cannot go above cap.\n\n" ..
	"Actors with companion share are ignored.\n\n" ..
	"Actors on blacklist are ignored.\n\n" ..
	".\n\n" ..
	".\n\n" ..
	".\n\n" ..
	"end of line.\n\n"
)
page.noScroll = false
local category = page:createCategory("SUDS")
category:createTextField({
	label = "Health Cap",
	description = "Actors that exceed cap are ignored .\n\n" .. "Default setting 500",
	numbersOnly = true,
	variable = mwse.mcm.createTableVariable{id = "hpCap", table = config },
	defaultSetting = 500,
})
category:createTextField({
	label = "Multiplier",
	description = "Health multiplier per player level\n" ..
	"(Health + (Health * (Multiplier * player level)))\n\n" ..
	"Default setting 0.01 (1 percent)\n",
	numbersOnly = true,
	variable = mwse.mcm.createTableVariable{id = "hpMultiplier", table = config },
    defaultSetting = 0.01,
})
category:createYesNoButton{
	label = "Enable Logging",
	description = "Outputs results to mwse.log\n\n" ..
	"default off",
	variable = mwse.mcm.createTableVariable{ id = "logToggle", table = config }
}
mwse.mcm.register(template)