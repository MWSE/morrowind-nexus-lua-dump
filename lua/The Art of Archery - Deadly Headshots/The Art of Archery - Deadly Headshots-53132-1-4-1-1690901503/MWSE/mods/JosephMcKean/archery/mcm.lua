local config = require("JosephMcKean.archery.config")

local logging = require("JosephMcKean.archery.logging")

local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "The Art of Archery" })
	template:saveOnClose("The Art of Archery", config)
	local settings = template:createSideBarPage({ label = "Settings" })
	local categoryLocationalDamage = settings:createCategory({ label = "Locational Damage" })
	categoryLocationalDamage:createYesNoButton({
		label = "Enable Locational Damage?",
		description = "Do you want damage multiplier depending on hit location?",
		variable = mwse.mcm.createTableVariable { id = "enableLocationalDamage", table = config },
	})
	categoryLocationalDamage:createYesNoButton({
		label = "Locational Damage Doesn't Apply to Player?",
		description = "Do headshots work on player?",
		variable = mwse.mcm.createTableVariable { id = "noPlayerHeadshot", table = config },
	})
	categoryLocationalDamage:createYesNoButton({
		label = "Show messages?",
		description = "Do you want a message box to popup every time you headshot?",
		variable = mwse.mcm.createTableVariable { id = "showMessages", table = config },
	})
	categoryLocationalDamage:createYesNoButton({
		label = "Only show headshot message?",
		description = "Do you want a message box to popup only when you headshot, and not a shot in the neck and arrow to the knee?",
		variable = mwse.mcm.createTableVariable { id = "onlyHeadshotMessage", table = config },
	})
	categoryLocationalDamage:createTextField({
		label = "Headshot Message",
		description = "Default message: GOTTEM! \n\n(imagine VvardenfellStormSage commentary-ing every headshot)",
		variable = mwse.mcm.createTableVariable { id = "headshotMessage", table = config },
	})
	local categoryDamageReduction = settings:createCategory({ label = "Damage Reduction" })
	categoryDamageReduction:createYesNoButton({
		label = "Enable projectile damage reduction if the shooter is moving?",
		description = "Shooter has 20% damage reduction penalty if the shooter is moving when the arrow was shot",
		variable = mwse.mcm.createTableVariable { id = "enableDamageReduction", table = config },
	})
	local categoryArrowCounter = settings:createCategory({ label = "Arrow Counter" })
	categoryArrowCounter:createYesNoButton({
		label = "Enable arrow counter?",
		description = "Arrow counter is widget that shows the number of the arrows, or bolts, or thrown weapon you have currently equipped in the lower left corner of the equipped weapon icon",
		variable = mwse.mcm.createTableVariable { id = "enableArrowCounter", table = config },
	})
	local categoryLogLevel = settings:createCategory({ label = "Log Level" })
	categoryLogLevel:createDropdown({
		label = "Set the log level",
		options = {
			{ label = "TRACE", value = "TRACE" },
			{ label = "DEBUG", value = "DEBUG" },
			{ label = "INFO", value = "INFO" },
			{ label = "ERROR", value = "ERROR" },
			{ label = "NONE", value = "NONE" },
		},
		variable = mwse.mcm.createTableVariable { id = "logLevel", table = config },
		callback = function(self) for _, logger in pairs(logging.loggers) do logger:setLogLevel(self.variable.value) end end,
	})
	template:register()
end

event.register("modConfigReady", registerModConfig)
