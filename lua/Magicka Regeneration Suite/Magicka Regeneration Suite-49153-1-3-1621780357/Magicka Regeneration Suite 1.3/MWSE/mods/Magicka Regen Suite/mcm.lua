local modPath = "Magicka Regen Suite"
local config = require(modPath .. ".config")
local text = require(modPath .. ".mcmText")
local settingsTable = config.getConfig()


local function newline(component)
	component:createInfo{ text = "\n" }
end
local function postFormat(self)
    --self.elements.outerContainer.borderAllSides = self.indent
    --self.elements.outerContainer.alignY = 1.0
    --self.elements.outerContainer.layoutHeightFraction = 1.0
    self.elements.info.layoutOriginFractionX = 0.5
end
local function addSideBar(component)
    component.sidebar:createInfo{ text = text.sideBarDefault }
	component.sidebar:createHyperLink{
        text = "Made by C3pa",
        exec = "start https://www.nexusmods.com/users/37172285?tab=user+files",
        postCreate = postFormat,
    }
end
local function createTableVar(id, restart)
    return mwse.mcm.createTableVariable{ id = id, table = settingsTable, restartRequired = (restart or false) }
end


local template = mwse.mcm.createTemplate{
	name = "Magicka Regen Suite",
	headerImagePath = "MWSE/mods/Magicka Regen Suite/MCMHeader.tga"
}
template.onClose = function()
	local eventData = table.copy(settingsTable)
    config.saveConfig(eventData)
    eventData.version = nil
    event.trigger("MRS", eventData)
end

do	-- Settings
	do	-- Main settings page
		local mainSettingsPage = template:createSideBarPage{ label = "Main Settings" }
		addSideBar(mainSettingsPage)
		mainSettingsPage.noScroll = true

		mainSettingsPage:createCategory{
			label = "\nMain Settings",
			description = text.regenerationTypesDescription
		}

		mainSettingsPage:createInfo{
			text = "The magicka regeneration type I want to use...",
			description = text.regenerationTypesDescription
		}

		mainSettingsPage:createDropdown{
			options = text.regenerationTypes,
			description = text.regenerationTypesDescription,
			variable = createTableVar("regenerationType")
		}

		newline(mainSettingsPage)
		mainSettingsPage:createSlider{
			label = "Regeneration speed modifier",
			description = text.regenerationSpeedModifier,
			min = 1,
			max = 200,
			step = 1,
			jump = 10,
			variable = createTableVar("regSpeedModifier")
		}

		newline(mainSettingsPage)
		mainSettingsPage:createOnOffButton{
			label = "Use Magicka speed decay feature?",
			variable = createTableVar("useDecay"),
			description = text.decayDescription
		}

		newline(mainSettingsPage)
		mainSettingsPage:createSlider{
			label = "exp = %s",
			description = text.decayDescription,
			min = 7,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("decayExp")
		}
	end
	do	-- Morrowind style regeneration settings page
		local morrowindSettingsPage = template:createSideBarPage{ label = "Morrowind Style Regeneration" }
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
			min = 1,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("magickaReturnMultMorrowind"),
		}

		newline(morrowindSettingsPage)
		morrowindSettingsPage:createSlider{
			label = "Combat Penalty = %s",
			description = text.morrowindCombatPenalty,
			min = 1,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("combatPenaltyMorrowind"),
		}

		morrowindSettingsPage:createInfo{ text = text.fatigueTermDescription }
	end
	do	-- Oblivion style regeneration settings page
		local oblivionSettingsPage = template:createSideBarPage{ label = "Oblivion Style Regeneration" }
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
		local skyrimSettingsPage = template:createSideBarPage{ label = "Skyrim Style Regeneration" }
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
			min = 1,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("combatPenaltySkyrim"),
		}
	end
end

mwse.mcm.register(template)
