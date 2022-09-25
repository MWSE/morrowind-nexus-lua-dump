local config = require("Magicka Regen Suite.config")
local text = require("Magicka Regen Suite.mcmText")
local mcmConfig = config.mcmGetConfig()


local function newline(component)
	component:createInfo{ text = "\n" }
end

local function addSideBar(component)
    component.sidebar:createInfo{ text = text.sideBarDefault }
	component.sidebar:createHyperLink{
        text = "Made by C3pa",
        url = "https://www.nexusmods.com/users/37172285?tab=user+files",
        postCreate = function(self)
			self.elements.info.layoutOriginFractionX = 0.5
		end,
    }
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
				variable = mwse.mcm.createTableVariable({ id = "regenerationFormula", table = mcmConfig })
			}

			newline(general)
			general:createSlider{
				label = "Regeneration speed modifier: %s %%",
				description = text.regenerationSpeedModifier,
				min = 1,
				max = 200,
				step = 1,
				jump = 10,
				variable = mwse.mcm.createTableVariable({ id = "regSpeedModifier", table = mcmConfig })
			}

			newline(general)
			general:createOnOffButton{
				label = "Use Magicka speed decay feature?",
				variable = mwse.mcm.createTableVariable({ id = "useDecay", table = mcmConfig }),
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
				variable = mwse.mcm.createTableVariable({ id = "decayExp", table = mcmConfig })
			}
		end
		do		-- Vampires Settings Block
			local vampire = mainSettingsPage:createCategory{
				label = "\nVampire regeneration settings",
				description = text.vampireChanges
			}

			vampire:createOnOffButton{
				label = "Changed magicka regeneration speed for Vampires?",
				variable = mwse.mcm.createTableVariable({ id = "vampireChanges", table = mcmConfig }),
				description = text.vampireChanges
			}

			newline(vampire)
			vampire:createSlider{
				label = "Day penalty to regeneration: %s %%",
				description = text.vampireDayPenalty,
				min = 0,
				max = 200,
				step = 5,
				jump = 20,
				variable = mwse.mcm.createTableVariable({ id = "dayPenalty", table = mcmConfig })
			}

			newline(vampire)
			vampire:createSlider{
				label = "Night regeneration bonus: %s %%",
				description = text.vampireNightBonus,
				min = 0,
				max = 100,
				step = 5,
				jump = 20,
				variable = mwse.mcm.createTableVariable({ id = "nightBonus", table = mcmConfig })
			}
		end
	end
	do	-- Morrowind style regeneration settings page
		local morrowindSettingsPage = template:createSideBarPage{ label = "Morrowind" }
		addSideBar(morrowindSettingsPage)

		morrowindSettingsPage:createCategory{ label = "\nFormula:\n" }
		morrowindSettingsPage:createInfo{ text = text.morrowindFormula }

		morrowindSettingsPage:createSlider{
			label = "base = %s",
			description = text.morrowindBase,
			min = 25,
			max = 150,
			step = 1,
			jump = 10,
			variable = mwse.mcm.createTableVariable({ id = "baseMorrowind", table = mcmConfig }),
		}

		newline(morrowindSettingsPage)
		morrowindSettingsPage:createSlider{
			label = "scale = %s",
			description = text.morrowindScale,
			min = 10,
			max = 25,
			step = 1,
			jump = 5,
			variable = mwse.mcm.createTableVariable({ id = "scaleMorrowind", table = mcmConfig }),
		}

		newline(morrowindSettingsPage)
		morrowindSettingsPage:createSlider{
			label = "cap = %s",
			description = text.morrowindCap,
			min = 0,
			max = 50,
			step = 1,
			jump = 10,
			variable = mwse.mcm.createTableVariable({ id = "capMorrowind", table = mcmConfig }),
		}

		newline(morrowindSettingsPage)
		morrowindSettingsPage:createSlider{
			label = "Combat Penalty: %s %%",
			description = text.combatPenalty,
			min = 0,
			max = 100,
			step = 1,
			jump = 10,
			variable = mwse.mcm.createTableVariable({ id = "combatPenaltyMorrowind", table = mcmConfig }),
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
			variable = mwse.mcm.createTableVariable({ id = "magickaReturnBaseOblivion", table = mcmConfig }),
		}

		newline(oblivionSettingsPage)
		oblivionSettingsPage:createSlider{
			label = "b = %s",
			description = text.oblivionBSlider,
			min = 1,
			max = 100,
			step = 1,
			jump = 10,
			variable = mwse.mcm.createTableVariable({ id = "magickaReturnMultOblivion", table = mcmConfig }),
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
			variable = mwse.mcm.createTableVariable({ id = "magickaReturnSkyrim", table = mcmConfig }),
		}

		newline(skyrimSettingsPage)
		skyrimSettingsPage:createSlider{
			label = "Combat Penalty: %s %%",
			description = text.skyrimCombatPenalty,
			min = 0,
			max = 100,
			step = 1,
			jump = 10,
			variable = mwse.mcm.createTableVariable({ id = "combatPenaltySkyrim", table = mcmConfig }),
		}
	end
	do -- Logarithimic INT settings page
		local logarithmicINTPage = template:createSideBarPage{ label = "Logarithimic INT" }
		addSideBar(logarithmicINTPage)

		logarithmicINTPage:createCategory{
			label = "\nLogarithmic Intelligence formula\n",
			description = text.INTDescription
		}
		logarithmicINTPage:createInfo{ text = text.INTFormula }

		logarithmicINTPage:createSlider{
			label = "base = %s",
			description = text.INTBase,
			min = 20,
			max = 30,
			step = 1,
			jump = 1,
			variable = mwse.mcm.createTableVariable({ id = "INTBase", table = mcmConfig })
		}

		newline(logarithmicINTPage)
		logarithmicINTPage:createSlider{
			label = "scale = %s",
			description = text.INTScale,
			min = 7,
			max = 15,
			step = 1,
			jump = 1,
			variable = mwse.mcm.createTableVariable({ id = "INTScale", table = mcmConfig })
		}

		newline(logarithmicINTPage)
		logarithmicINTPage:createSlider{
			label = "cap = %s",
			description = text.INTCap,
			min = 0,
			max = 60,
			step = 1,
			jump = 5,
			variable = mwse.mcm.createTableVariable({ id = "INTCap", table = mcmConfig })
		}

		newline(logarithmicINTPage)
		logarithmicINTPage:createYesNoButton{
			label = "Slower magicka regeneration while in combat?",
			description = text.combatPenaltyGeneral,
			variable = mwse.mcm.createTableVariable({ id = "INTApplyCombatPenalty", table = mcmConfig })
		}
		logarithmicINTPage:createSlider{
			label = "Combat Penalty: %s %%",
			description = text.combatPenalty,
			min = 0,
			max = 100,
			step = 1,
			jump = 10,
			variable = mwse.mcm.createTableVariable({ id = "INTCombatPenalty", table = mcmConfig })
		}

		newline(logarithmicINTPage)
		logarithmicINTPage:createYesNoButton{
			label = "Scale magicka regeneration speed with current fatigue?",
			description = text.fatigueScaling,
			variable = mwse.mcm.createTableVariable({ id = "INTUseFatigueTerm", table = mcmConfig })
		}
	end
end
