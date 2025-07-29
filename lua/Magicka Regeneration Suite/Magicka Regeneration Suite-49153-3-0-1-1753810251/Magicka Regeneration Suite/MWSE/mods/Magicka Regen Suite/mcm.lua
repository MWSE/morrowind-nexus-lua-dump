local config = require("Magicka Regen Suite.config")
local gmst = require("Magicka Regen Suite.modules.gmst")
local text = require("Magicka Regen Suite.mcmText")

local authors = {
	{
		name = "C3pa",
		url = "https://next.nexusmods.com/profile/C3pa/mods",
	},
}

---@param component mwseMCMCategory
local function newline(component)
	component:createInfo({ text = "\n" })
end

--- @param self mwseMCMInfo|mwseMCMHyperlink
local function center(self)
	self.elements.info.absolutePosAlignX = 0.5
end

---@param container mwseMCMSideBarPage
local function addSideBar(container)
	container.sidebar:createInfo({
		text = text.sideBarDefault,
		postCreate = center
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
		name = "Magicka Regen Suite",
		headerImagePath = "MWSE/mods/Magicka Regen Suite/MCMHeader.tga",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true
	})
	template:register()
	template:saveOnClose(config.fileName, config)

	do -- Main settings page
		local page = template:createSideBarPage({
			label = "Main Settings",
			showReset = true
		})
		addSideBar(page)

		local generalCategory = page:createCategory({
			label = "\nGeneral",
			description = text.regenerationTypesDescription
		})

		generalCategory:createInfo({
			text = "The magicka regeneration formula I want to use...",
			description = text.regenerationFormulasDescription
		})

		generalCategory:createDropdown({
			options = text.regenerationFormula,
			description = text.regenerationFormulasDescription,
			configKey = "regenerationFormula",
			callback = gmst.updateGMSTs
		})

		newline(generalCategory)
		generalCategory:createPercentageSlider({
			label = "Regeneration speed modifier",
			description = text.regenerationSpeedModifier,
			min = 0.01,
			max = 2,
			configKey = "regSpeedModifier"
		})

		local decay = page:createCategory({
			description = text.decayDescription
		})

		decay:createOnOffButton({
			label = "Use Magicka speed decay feature?",
			description = text.decayDescription,
			configKey = "useDecay"
		})

		newline(generalCategory)
		decay:createSlider({
			label = "exp = %s",
			description = text.decayDescription,
			min = 0.7,
			max = 10,
			step = 0.1,
			jump = 1,
			decimalPlaces = 1,
			configKey = "decayExp"
		})

		local vampireSettings = page:createCategory({
			label = "\nVampire regeneration settings",
			description = text.vampireChanges
		})

		vampireSettings:createOnOffButton({
			label = "Changed magicka regeneration speed for Vampires?",
			description = text.vampireChanges,
			configKey = "vampireChanges"
		})

		newline(vampireSettings)
		vampireSettings:createPercentageSlider({
			label = "Day penalty to regeneration",
			description = text.vampireDayPenalty,
			min = 0,
			max = 2,
			configKey = "dayPenalty"
		})

		newline(vampireSettings)
		vampireSettings:createPercentageSlider({
			label = "Night regeneration bonus",
			description = text.vampireNightBonus,
			min = 0,
			max = 1,
			configKey = "nightBonus"
		})

		newline(page)
		page:createLogLevelOptions({
			configKey = "logLevel"
		})
	end

	do -- Morrowind style regeneration settings page
		local page = template:createSideBarPage({
			label = "Morrowind",
			showReset = true,
		})
		addSideBar(page)

		page:createCategory({ label = "\nFormula:" })
		page:createInfo({ text = text.morrowindFormula })

		page:createSlider({
			label = "base = %s",
			description = text.morrowindBase,
			min = 2.5,
			max = 15,
			step = 0.1,
			jump = 1,
			decimalPlaces = 1,
			configKey = "baseMorrowind"
		})

		newline(page)
		page:createSlider({
			label = "scale = %s",
			description = text.morrowindScale,
			min = 1.0,
			max = 2.5,
			step = 0.1,
			jump = 0.5,
			decimalPlaces = 1,
			configKey = "scaleMorrowind"
		})

		newline(page)
		page:createSlider({
			label = "cap = %s",
			description = text.morrowindCap,
			min = 0.0,
			max = 5.0,
			step = 0.1,
			jump = 0.5,
			decimalPlaces = 1,
			configKey = "capMorrowind"
		})

		newline(page)
		page:createPercentageSlider({
			label = "Combat Penalty",
			description = text.combatPenalty,
			min = 0,
			max = 1,
			configKey = "combatPenaltyMorrowind"
		})

		page:createInfo({ text = text.fatigueTermDescription })
	end

	do -- Oblivion style regeneration settings page
		local page = template:createSideBarPage({
			label = "Oblivion",
			noScroll = true,
			showReset = true,
			-- We need custom default value descriptions on this page
			showDefaultSetting = false
		})
		addSideBar(page)

		page:createCategory({ label = "\nFormula:"})
		page:createInfo({ text = text.oblivionFormula })

		page:createSlider({
			label = "a = %s%%",
			description = text.oblivionASlider,
			min = 0,
			max = 1.5,
			step = 0.01,
			jump = 0.1,
			decimalPlaces = 2,
			configKey = "magickaReturnBaseOblivion"
		})

		newline(page)
		page:createPercentageSlider({
			label = "b = %s",
			description = text.oblivionBSlider,
			min = 0.0,
			max = 0.1,
			step = 0.01,
			jump = 0.05,
			decimalPlaces = 1,
			configKey = "magickaReturnMultOblivion"
		})
	end

	do -- Skyrim style regeneration settings page
		local page = template:createSideBarPage({
			label = "Skyrim",
			noScroll = true,
			showReset = true
		})
		addSideBar(page)

		page:createCategory({ label = "\nFormula:"})
		page:createInfo({ text = text.skyrimFormula })

		page:createPercentageSlider({
			label = "a = %s",
			description = text.skyrimASlider,
			min = 0.0,
			max = 0.1,
			decimalPlaces = 1,
			configKey = "magickaReturnSkyrim"
		})

		newline(page)
		page:createPercentageSlider({
			label = "Combat Penalty",
			description = text.skyrimCombatPenalty,
			min = 0,
			max = 1,
			configKey = "combatPenaltySkyrim"
		})
	end

	do -- Logarithmic INT settings page
		local logarithmicINTPage = template:createSideBarPage({
			label = "Logarithmic INT",
			showReset = true
		})
		addSideBar(logarithmicINTPage)

		logarithmicINTPage:createCategory({
			label = "\nLogarithmic Intelligence formula",
			description = text.INTDescription
		})
		logarithmicINTPage:createInfo({ text = text.INTFormula })

		logarithmicINTPage:createSlider({
			label = "base = %s",
			description = text.INTBase,
			min = 2,
			max = 3,
			decimalPlaces = 1,
			configKey = "INTBase"
		})

		newline(logarithmicINTPage)
		logarithmicINTPage:createSlider({
			label = "scale = %s",
			description = text.INTScale,
			min = 0.7,
			max = 1.5,
			step = 0.01,
			jump = 0.05,
			decimalPlaces = 1,
			configKey = "INTScale"
		})

		newline(logarithmicINTPage)
		logarithmicINTPage:createSlider({
			label = "cap = %s",
			description = text.INTCap,
			min = 0,
			max = 6,
			decimalPlaces = 1,
			configKey = "INTCap"
		})

		newline(logarithmicINTPage)
		logarithmicINTPage:createYesNoButton({
			label = "Slower magicka regeneration while in combat?",
			description = text.combatPenaltyGeneral,
			configKey = "INTApplyCombatPenalty"
		})

		logarithmicINTPage:createPercentageSlider({
			label = "Combat Penalty",
			description = text.combatPenalty,
			min = 0,
			max = 1,
			configKey = "INTCombatPenalty"
		})

		newline(logarithmicINTPage)
		logarithmicINTPage:createYesNoButton{
			label = "Scale magicka regeneration speed with current fatigue?",
			description = text.fatigueTermDescription,
			configKey = "INTUseFatigueTerm"
		}
	end
end

event.register(tes3.event.modConfigReady, registerModConfig)
