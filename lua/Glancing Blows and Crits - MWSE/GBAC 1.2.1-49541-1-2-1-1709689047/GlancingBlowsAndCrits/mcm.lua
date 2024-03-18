local config = require("GlancingBlowsAndCrits.config")
--local configPath = "GlancingBlowsAndCrits"

local template = mwse.mcm.createTemplate("Glancing Blows And Crits")
template:saveOnClose("GBAC", config)

local settings = template:createSideBarPage({
    label = "Settings",
    description =
        "Glancing Blows and Crits, by ZullleMW\n" ..
        "Version 1.2.1\n" ..
        "\n" ..
        "This mod replaces misses with glancing blows and introduces critical hits to regular combat with the intention of making the dice rolling system more satisfying without rebalancing the game.\n" ..
		"\n" ..
		"MCM and 'Cast On Glance' implementation by Daichi",
})

settings:createYesNoButton({
    label = "Enable the mod?",
    description =
        "Turn the mod on or off. You can do so whenever you like.\n" ..
		"\n" ..
        "Default: Yes",
    variable = mwse.mcm:createTableVariable({ id = "enabled", table = config }),
})

settings:createYesNoButton({
	label = "'Cast On Glance' enchantments are cast when glancing blows?",
	description =
		"If this setting is enabled, 'Cast On Glance' enchantments are cast when the player glances.\n" ..
		"The game may become unbalanced if this parameter is on.\n" ..
        "It is on by default because if it is off the game spams message boxes when glancing blows occur.\n" ..
		"\n" ..
		"Default: Yes",
	variable = mwse.mcm:createTableVariable({ id = "castOnGlance", table = config }),
})

settings:createYesNoButton({
	label = "Enable critical hits?",
	description =
		"If this setting is disabled, critical hits will only occur in stealth mode, as in vanilla.\n" ..
        "\n" ..
		"Default: Yes",
	variable = mwse.mcm:createTableVariable({ id = "critEnabled", table = config }),
})

settings:createYesNoButton({
	label = "Glancing blows slightly increase skills?",
	description =
		"If this setting is enabled, glancing blows will increase skills very slightly. Normal hits will still be more effective.\n" ..
		"\n" ..
		"Otherwise, glancing blows will not increase skills.\n" ..
		"\n" ..
		"Default: Yes",
	variable = mwse.mcm:createTableVariable({ id = "glanceSkill", table = config }),
})

settings:createYesNoButton({
	label = "Critical hits greatly increase skills?",
	description =
		"If this settings is enabled, critical hits will greatly increase skills.\n" ..
		"\n" ..
		"Otherwise, critical hits will increase skills like normal hits.\n" ..
		"\n" ..
		"Default: Yes",
	variable = mwse.mcm:createTableVariable({ id = "critSkill", table = config }),
})


mwse.mcm.register(template)
