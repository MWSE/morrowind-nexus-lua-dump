local config = require("Magicka Regen Suite.config")
local text = require("Magicka Regen Suite.mcmText")
local mcmConfig = config.mcmGetConfig()


local function postFormat(self)
    self.elements.info.layoutOriginFractionX = 0.5
end

local function newline(component)
	component:createInfo{ text = "\n" }
end

local function addSideBar(component)
    component.sidebar:createInfo{ text = text.sideBarDefault }
	component.sidebar:createHyperLink{
        text = "Made by C3pa",
        url = "https://www.nexusmods.com/users/37172285?tab=user+files",
        postCreate = postFormat,
    }
end

local function createTableVar(id)
    return mwse.mcm.createTableVariable{ id = id, table = mcmConfig }
end

local template = mwse.mcm.createTemplate{
	name = "Magicka Regen Suite",
	headerImagePath = "MWSE/mods/Magicka Regen Suite/MCMHeader.tga",
	onClose = function()
		config.mcmSaveConfig(mcmConfig)
	end
}
template:register()

do	-- Settings
	do	-- Main settings page
		local mainSettingsPage = template:createSideBarPage{ label = "Main Settings" }
		addSideBar(mainSettingsPage)
		mainSettingsPage.noScroll = true

		do		-- General Settings Block
			local general = mainSettingsPage:createCategory{
				label = "\nGeneral",
				description = text.regenerationTypesDescription
			}

			general:createInfo{
				text = "The magicka regeneration formula I want to use...",
				description = text.regenerationFormulasDescription
			}

			general:createDropdown{
				options = text.regenerationFormula,
				description = text.regenerationFormulasDescription,
				variable = createTableVar("regenerationFormula")
			}

			newline(general)
			general:createSlider{
				label = "Regeneration speed modifier",
				description = text.regenerationSpeedModifier,
				min = 1,
				max = 200,
				step = 1,
				jump = 10,
				variable = createTableVar("regSpeedModifier")
			}

			newline(general)
			general:createOnOffButton{
				label = "Use Magicka speed decay feature?",
				variable = createTableVar("useDecay"),
				description = text.decayDescription
			}

			newline(general)
			general:createSlider{
				label = "exp = %s",
				description = text.decayDescription,
				min = 7,
				max = 100,
				step = 1,
				jump = 10,
				variable = createTableVar("decayExp")
			}
		end
		do		-- Vampires Settings Block
			local vampire = mainSettingsPage:createCategory{
				label = "\nVampire regeneration settings",
				description = text.vampireChanges
			}

			vampire:createOnOffButton{
				label = "Enable changed magicka regeneration speed for Vampires?",
				variable = createTableVar("vampireChanges"),
				description = text.vampireChanges
			}

			newline(vampire)
			vampire:createSlider{
				label = "Day penalty to regeneration",
				description = text.vampireDayPenalty,
				min = 0,
				max = 200,
				step = 5,
				jump = 20,
				variable = createTableVar("dayPenalty")
			}

			newline(vampire)
			vampire:createSlider{
				label = "Night regeneration bonus",
				description = text.vampireNightBonus,
				min = 0,
				max = 100,
				step = 5,
				jump = 20,
				variable = createTableVar("nightBonus")
			}
		end
	end
	do	-- Morrowind style regeneration settings page
		local morrowindSettingsPage = template:createSideBarPage{ label = "Morrowind" }
		addSideBar(morrowindSettingsPage)

		morrowindSettingsPage:createCategory{ label = "\nFormula:\n" }
		morrowindSettingsPage:createInfo{ text = text.morrowindFormula }

		morrowindSettingsPage:createSlider{
			label = "a = %s",
			description = text.morrowindASlider,
			min = 0,
			max = 150,
			step = 1,
			jump = 10,
			variable = createTableVar("magickaReturnBaseMorrowind"),
		}

		newline(morrowindSettingsPage)
		morrowindSettingsPage:createSlider{
			label = "b = %s",
			description = text.morrowindBSlider,
			min = 0,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("magickaReturnMultMorrowind"),
		}

		newline(morrowindSettingsPage)
		morrowindSettingsPage:createSlider{
			label = "Combat Penalty = %s",
			description = text.combatPenalty,
			min = 0,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("combatPenaltyMorrowind"),
		}

		morrowindSettingsPage:createInfo{ text = text.fatigueTermDescription }
	end
	do	-- Oblivion style regeneration settings page
		local oblivionSettingsPage = template:createSideBarPage{ label = "Oblivion" }
		addSideBar(oblivionSettingsPage)
		oblivionSettingsPage.noScroll = true

		oblivionSettingsPage:createCategory{ label = "\nFormula:\n"}
		oblivionSettingsPage:createInfo{ text = text.oblivionFormula }

		oblivionSettingsPage:createSlider{
			label = "a = %s",
			description = text.oblivionASlider,
			min = 0,
			max = 150,
			step = 1,
			jump = 10,
			variable = createTableVar("magickaReturnBaseOblivion"),
		}

		newline(oblivionSettingsPage)
		oblivionSettingsPage:createSlider{
			label = "b = %s",
			description = text.oblivionBSlider,
			min = 1,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("magickaReturnMultOblivion"),
		}
	end
	do	-- Skyrim style regeneration settings page
		local skyrimSettingsPage = template:createSideBarPage{ label = "Skyrim" }
		addSideBar(skyrimSettingsPage)
		skyrimSettingsPage.noScroll = true

		skyrimSettingsPage:createCategory{ label = "\nFormula:\n"}
		skyrimSettingsPage:createInfo{ text = text.skyrimFormula }

		skyrimSettingsPage:createSlider{
			label = "a = %s",
			description = text.skyrimASlider,
			min = 1,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("magickaReturnSkyrim"),
		}

		newline(skyrimSettingsPage)
		skyrimSettingsPage:createSlider{
			label = "Combat Penalty = %s",
			description = text.skyrimCombatPenalty,
			min = 0,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("combatPenaltySkyrim"),
		}
	end
	do -- Logarithimic WILL settings page
		local logarithmicWILLPage = template:createSideBarPage{ label = "Logarithimic WILL" }
		addSideBar(logarithmicWILLPage)

		logarithmicWILLPage:createCategory{
			label = "\nLogarithmic Willpower formula\n",
			description = ""
		}
		logarithmicWILLPage:createInfo{ text = text.WILLFormula }

		logarithmicWILLPage:createSlider{
			label = "base = %s",
			description = text.WILLBase,
			min = 11,
			max = 20,
			step = 1,
			jump = 1,
			variable = createTableVar("WILLBase")
		}

		newline(logarithmicWILLPage)
		logarithmicWILLPage:createSlider{
			label = "a = %s",
			description = text.WILLa,
			min = 1,
			max = 5,
			step = 1,
			jump = 1,
			variable = createTableVar("WILLa")
		}

		newline(logarithmicWILLPage)
		logarithmicWILLPage:createYesNoButton{
			label = "Slower magicka regeneration while in combat?",
			description = text.combatPenaltyGeneral,
			variable = createTableVar("WILLApplyCombatPenalty")
		}
		logarithmicWILLPage:createSlider{
			label = "Combat Penalty = %s",
			description = text.combatPenalty,
			min = 0,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("WILLCombatPenalty")
		}

		newline(logarithmicWILLPage)
		logarithmicWILLPage:createYesNoButton{
			label = "Scale magicka regeneration speed with current fatigue?",
			description = text.fatigueScaling,
			variable = createTableVar("WILLUseFatigueTerm")
		}
	end
	do -- Logarithimic INT settings page
		local logarithmicINTPage = template:createSideBarPage{ label = "Logarithimic INT" }
		addSideBar(logarithmicINTPage)

		logarithmicINTPage:createCategory{
			label = "\nLogarithmic Intelligence formula\n",
			description = ""
		}
		logarithmicINTPage:createInfo{ text = text.INTFormula }

		logarithmicINTPage:createSlider{
			label = "base = %s",
			description = text.INTBase,
			min = 101,
			max = 111,
			step = 1,
			jump = 1,
			variable = createTableVar("INTBase")
		}

		newline(logarithmicINTPage)
		logarithmicINTPage:createSlider{
			label = "a = %s",
			description = text.INTa,
			min = 1,
			max = 20,
			step = 1,
			jump = 5,
			variable = createTableVar("INTa")
		}

		newline(logarithmicINTPage)
		logarithmicINTPage:createSlider{
			label = "b = %s",
			description = text.INTb,
			min = 0,
			max = 100,
			step = 1,
			jump = 5,
			variable = createTableVar("INTb")
		}

		newline(logarithmicINTPage)
		logarithmicINTPage:createYesNoButton{
			label = "Slower magicka regeneration while in combat?",
			description = text.combatPenaltyGeneral,
			variable = createTableVar("INTApplyCombatPenalty")
		}
		logarithmicINTPage:createSlider{
			label = "Combat Penalty = %s",
			description = text.combatPenalty,
			min = 0,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("INTCombatPenalty")
		}

		newline(logarithmicINTPage)
		logarithmicINTPage:createYesNoButton{
			label = "Scale magicka regeneration speed with current fatigue?",
			description = text.fatigueScaling,
			variable = createTableVar("INTUseFatigueTerm")
		}
	end
end
