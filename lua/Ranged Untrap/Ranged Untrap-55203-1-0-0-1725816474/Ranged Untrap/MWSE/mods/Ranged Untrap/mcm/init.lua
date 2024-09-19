local configlib = require("Ranged Untrap.config")
local log = require("logging.logger").getLogger("Ranged Untrap") --[[@as mwseLogger]]
local mcmConfig = configlib.getConfig()

--- @param self mwseMCMInfo
local function center(self)
	self.elements.info.absolutePosAlignX = 0.5
end

local authors = {
	{
		name = "C3pa",
		url = "https://www.nexusmods.com/morrowind/users/37172285?tab=user+files",
	},
}

--- @param container mwseMCMSideBarPage
local function createSidebar(container)
	container.sidebar:createInfo({
		text = (
			"\nWelcome to Ranged Untrap!\n\nHover over a feature for more info.\n\nMade by:"
		),
		postCreate = center,
	})
	for _, author in ipairs(authors) do
		container.sidebar:createHyperlink({
			text = author.name,
			url = author.url,
			postCreate = center,
		})
	end
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Ranged Untrap",
		config = mcmConfig,
		defaultConfig = configlib.default,
		headerImagePath = "MWSE/mods/Ranged Untrap/mcm/Header.tga",
		onClose = function()
			configlib.saveConfig(mcmConfig)
		end,
		showDefaultSetting = true,
	})
	template:register()

	local page = template:createSideBarPage({
		label = "Settings",
		showReset = true,
		postCreate = function(self)
			self.sidebar.elements.subcomponentsContainer.paddingAllSides = 8
		end
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

	page:createYesNoButton({
		label = "Cast trap spell on critical fail?",
		description = "When turned on, trap spell will be cast on the player on critical fails in disarming traps \z
			with a ranged weapon.",
		configKey = "castTrapOnCriticalFail",
	})

	page:createYesNoButton({
		label = "Cast trap spell on regular fail?",
		description = "When turned on, trap spell will be cast on the player on regular fails in disarming traps \z
			with a ranged weapon.\n\nNote: this setting makes the game more difficult.",
		configKey = "castTrapOnFail",
	})

	page:createYesNoButton({
		label = "Play fail sound?",
		description = "When any of the Cast trap spell options are turned off, a fail disarm trap sound is played \z
			to give the player some auditory cue of the action result.",
		configKey = "soundOnFail",
	})

	local fSecurityMult = mwse.mcm.createTableVariable({
		table = mcmConfig,
		id = "fSecurityMult",
	})
	local fMarksmanMult = mwse.mcm.createTableVariable({
		table = mcmConfig,
		id = "fMarksmanMult",
	})

	do -- Player term
		local function getPlayerTermText()
			return string.format("playerTerm = %.2f x Security + %.2f x Marksman + 0.2 x Agility + 0.1 x Luck",
				fSecurityMult.value,
				fMarksmanMult.value
			)
		end

		local playerTermDescription = "The higher the playerTerm, the higher the chance of successfuly disarming a \z
			trap with ranged weapons."
		local player = page:createCategory({
			label = "Player term:",
			description = playerTermDescription,
		})

		local playerTerm = player:createInfo({
			text = getPlayerTermText(),
			description = playerTermDescription,
			postCreate = function(self)
				self.text = getPlayerTermText()
				self.elements.info.text = getPlayerTermText()
			end,
		})

		local s1 = player:createSlider({
			label = "fSecurityMult = %s",
			description = "Security multiplier in the playerTerm equation.\n\n" .. playerTermDescription,
			min = 0.01,
			max = 1.00,
			step = 0.01,
			jump = 0.05,
			decimalPlaces = 2,
			variable = fSecurityMult,
			callback = function(self)
				playerTerm:postCreate()
			end
		})
		local _updateValueLabel = s1.updateValueLabel
		--- @param self mwseMCMSlider
		s1.updateValueLabel = function(self)
			_updateValueLabel(self)
			playerTerm:postCreate()
		end

		local s2 = player:createSlider({
			label = "fMarksmanMult = %s",
			description = "Marksman multiplier in the playerTerm equation.\n\n" .. playerTermDescription,
			min = 0.01,
			max = 1.00,
			step = 0.01,
			jump = 0.05,
			decimalPlaces = 2,
			variable = fMarksmanMult,
			callback = function(self)
				playerTerm:postCreate()
			end
		})
		--- @param self mwseMCMSlider
		s2.updateValueLabel = function(self)
			_updateValueLabel(self)
			playerTerm:postCreate()
		end
	end


	do -- Trap term
		local trapTermDescription = "The higher the trapTerm, the lower the chance of successfuly disarming a \z
			trap with ranged weapons."
		local fTrapCostMult = mwse.mcm.createTableVariable({
			table = mcmConfig,
			id = "fTrapCostMult",
		})

		local function getTrapTermText()
			return string.format("trapTerm = %.2f x Trap magicka cost", fTrapCostMult.value)
		end

		local trap = page:createCategory({
			label = "Trap term:",
			description = trapTermDescription
		})

		local trapTerm = trap:createInfo({
			description = trapTermDescription,
			text = getTrapTermText(),
			postCreate = function(self)
				self.text = getTrapTermText()
				self.elements.info.text = getTrapTermText()
			end,
		})

		local s1 = trap:createSlider({
			label = "fTrapCostMult = %s",
			description = "Trap cost multiplier in trapTerm equation.\n\n" .. trapTermDescription,
			min = 0.01,
			max = 3.00,
			step = 0.01,
			jump = 0.05,
			decimalPlaces = 2,
			variable = fTrapCostMult,
			callback = function(self)
				trapTerm:postCreate()
			end
		})
		local _updateValueLabel = s1.updateValueLabel
		--- @param self mwseMCMSlider
		s1.updateValueLabel = function(self)
			_updateValueLabel(self)
			trapTerm:postCreate()
		end
	end


	local formulas = page:createCategory({ label = "Other formulas:" })
	formulas:createInfo({
		text = "if trapTerm > playerTerm then critical fail\n\n\z
			x = (playerTerm - trapTerm) x fatigueTerm x (projectileVelocity / fProjectileMaxSpeed*)\n\n\z
			roll 100; if roll <= x then disarm trap successful; else regular fail\n\n\z
			*fProjectileMaxSpeed GMST, with default value of 3000.",
	})

	page:createDropdown({
		label = "Logging Level",
		description = "Set the log level. If you've found a bug in the mod, please backup \z
		               your MWSE.log, set the logging level to Trace, and replicate the bug. When \z
		               reporting the bug please attach both MWSE.log files.",
		options = {
			{ label = "Trace", value = "TRACE" },
			{ label = "Debug", value = "DEBUG" },
			{ label = "Info",  value = "INFO" },
			{ label = "Warn",  value = "WARN" },
			{ label = "Error", value = "ERROR" },
			{ label = "None",  value = "NONE" },
		},
		variable = mwse.mcm.createTableVariable({ id = "logLevel", table = mcmConfig }),
		callback = function(self)
			log:setLogLevel(self.variable.value)
		end
	})
end

event.register(tes3.event.modConfigReady, registerModConfig)
