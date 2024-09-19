local configlib = require("The Inflation.config")
local mcmConfig = configlib.getConfig()


local text = {
	sideBarDefault = [[

Welcome to The Inflation!

Hover over individual settings for more info.

]],

	worth = {
		options = {
			{ label = "Gold only", value = configlib.netWorth.goldOnly },
			{ label = "All equipped items", value = configlib.netWorth.equippedItems },
			{ label = "All the items in inventory", value = configlib.netWorth.wholeInventory },
		},
		label = "How shall player's net worth be determined?",
		description = (
			"\nGold only - player's net worth is the amount of gold the player is currently carrying.\n\n"..

			"All equipped items - player's worth is the value of all the items the player currently has equipped.\n\n"..

			"All the items in inventory - player's worth is the value of all the items in players inventory "..
			"including gold and currently equipped items.\n\n"
		),
	},

	spellsWorth = {
		label = "Bought spells contribute to player net worth?",
		description = "\nWith this option enabled, spells which the player has bought will be factored in player net worth calculation.",
	},

	barter = {
		label = (
			"\nBartering and Training Prices"
		),
		description = (
			"\nThis formula is used for adjustment of bartering and training prices. "..
			"The exponent used in the formula can be changed separately for bartering and training."
		),
		formula = (
			"\n  = max(1, log(playerWorth, basePrice x 10)) ^ exp"
		),
		enableBarter = {
			label = "Change prices of bought items?",
			description = "\nWhen enabled the prices of bought items scale with the player net worth."
		},
		barterExp = {
			label = "barterExp = %s",
			description = (
				"\nThe exponent used in cost adjustments for bartering.\n\n"..

				"The higher the exponent, the more items cost."
			),
		},
		enableTraining = {
			label = "Change prices of Training services?",
			description = "\nWhen enabled the Training prices scale with the player net worth."
		},
		trainingExp = {
			label = "trainingExp = %s",
			description = (
				"\nThe exponent used in cost adjustments for training.\n\n"..

				"The higher the exponent, the more training costs."
			),
		},
	},

	generic = {
		label = (
			"\nRepair and Travel services and Spell prices"
		),
		description = (
			"\nThis formula is used for adjustment of repair, travel and spell prices. "..
			"There is one setting which applies for repair and travel services, and another that "..
			"applies for spells."
		),
		formula = "\n  = max(1, log(playerWorth / basePrice, base)) ^ exp",
		base = {
			label = "base = %s",
			description = "\nIncreasing this value will make prices lower, while decreasing it will make the prices higher.",
		},
		enableGeneric = {
			label = "Change prices of Repair and Travel services?",
			description = "\nWhen enabled the prices for Repair and Travel services scale with the player net worth."
		},
		genericExp = {
			label = "genericExp = %s",
			description = (
				"\nThe exponent used for adjusting the prices of repair and travel services. The higher the exponent, the pricier "..
				"the services will be."
			)
		},
		enableSpells = {
			label = "Change prices of bought spells?",
			description = "\nWhen enabled the prices of bought spells scale with the player net worth."
		},
		spellExp = {
			label = "spellExp = %s",
			description = (
				"\nThe exponent used for spell price adjustment. Usually spells are one-time purchase, so they cost"..
				" more, which translates to higher exponent with defauls settings. This value can be changed.\n\n"..

				"The higher the exponent, the more spells will cost."
			)
		},
	},
}

local function newline(component)
	component:createInfo({ text = "\n" })
end

--- @param container mwseMCMSideBarPage
local function addSideBar(container)
	container.sidebar:createInfo({ text = text.sideBarDefault })
	container.sidebar:createHyperlink({
		text = "Made by C3pa",
		url = "https://www.nexusmods.com/users/37172285?tab=user+files",
		postCreate = function(self)
			self.elements.info.absolutePosAlignX = 0.5
		end,
	})
end

local function createTableVar(id)
	return mwse.mcm.createTableVariable({ id = id, table = mcmConfig })
end


local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "The Inflation",
		config = mcmConfig,
		defaultConfig = configlib.default,
		headerImagePath = "MWSE/mods/The Inflation/MCMHeader.tga",
		onClose = function()
			configlib.saveConfig(mcmConfig)
		end,
		showDefaultSetting = true,
	})
	template:register()

	local page = template:createSideBarPage({
		label = "Settings",
		showReset = true,
	})
	addSideBar(page)

	do	-- Net Worth Block
		local netWorth = page:createCategory({ label = "\nPlayer Net Worth" })

		newline(netWorth)
		netWorth:createInfo({
			label = text.worth.label,
			description = text.worth.description,
		})
		netWorth:createDropdown({
			options = text.worth.options,
			description = text.worth.description,
			configKey = "netWorthCaluclation",
		})

		newline(netWorth)
		netWorth:createOnOffButton({
			label = text.spellsWorth.label,
			description = text.spellsWorth.description,
			configKey = "spellsAffectNetWorth",
		})
	end

	do	-- Bartering/Training Block
		local barter = page:createCategory({
			label = text.barter.label,
			description = text.barter.description,
		})
		barter:createInfo({
			label = text.barter.formula,
			description = text.barter.description
		})

		barter:createOnOffButton({
			label = text.barter.enableBarter.label,
			description = text.barter.enableBarter.description,
			configKey = "enableBarter",
		})
		barter:createSlider({
			label = text.barter.barterExp.label,
			description = text.barter.barterExp.description,
			min = 1.0,
			max = 6.0,
			step = 0.05,
			jump = 0.25,
			decimalPlaces = 2,
			configKey = "barterExp"
		})

		newline(barter)
		barter:createOnOffButton({
			label = text.barter.enableTraining.label,
			description = text.barter.enableTraining.description,
			configKey = "enableTraining",
		})
		barter:createSlider({
			label = text.barter.trainingExp.label,
			description = text.barter.trainingExp.description,
			min = 1.0,
			max = 6.00,
			step = 0.05,
			jump = 0.25,
			decimalPlaces = 2,
			configKey = "trainingExp",
		})
	end

	do	-- Generic/Spells Block
		local generic = page:createCategory({
			label = text.generic.label,
			description = text.generic.description,
		})
		generic:createInfo({
			label = text.generic.formula,
			description = text.generic.description,
		})

		generic:createSlider({
			label = text.generic.base.label,
			description = text.generic.base.description,
			min = 2,
			max = 100,
			step = 1,
			jump = 5,
			configKey = "base",
		})

		newline(generic)
		generic:createOnOffButton({
			label = text.generic.enableGeneric.label,
			description = text.generic.enableGeneric.description,
			configKey = "enableGeneric",
		})
		generic:createSlider({
			label = text.generic.genericExp.label,
			description = text.generic.genericExp.description,
			min = 1.0,
			max = 6.0,
			step = 0.05,
			jump = 0.25,
			decimalPlaces = 2,
			configKey = "genericExp",
		})

		newline(generic)
		generic:createOnOffButton({
			label = text.generic.enableSpells.label,
			description = text.generic.enableSpells.description,
			configKey = "enableSpells",
		})
		generic:createSlider({
			label = text.generic.spellExp.label,
			description = text.generic.spellExp.description,
			min = 1.0,
			max = 6.0,
			step = 0.05,
			jump = 0.25,
			decimalPlaces = 2,
			configKey = "spellExp",
		})
	end
end

event.register(tes3.event.modConfigReady, registerModConfig)
