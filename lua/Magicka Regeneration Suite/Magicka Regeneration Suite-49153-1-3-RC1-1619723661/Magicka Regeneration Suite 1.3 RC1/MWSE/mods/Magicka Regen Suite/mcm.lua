local configPath = "Magicka Regen Suite.config"
local config = require(configPath)
local settingsTable = config.getConfig()
local multiplied = false
local regenerationTypes = {
	{ label = "Morrowind style", value = 0 },
    { label = "Oblivion style", value = 1 },
    { label = "Skyrim style", value = 2 }
}
local sideBarDefault =
[[

Welcome to Magica Regeneration Suite!

Use the configuration menu to adjust various features and coefficients.

Hover over individual settings to see more information.

The game must be restarted before any change will come into effect.

]]
local regenerationTypesDescription = "\nRegeneration type determines with what magicka regeneration "..
"scales. \n\nIn Skyrim, it scales with "..
"maximum magicka. Maximum magicka depends on intelligence, so in Skyrim style magicka regeneration "..
"speed scales with intelligence. \n\nIn Oblivion it scales with willpower and intelligence. \n\nIn "..
"Morrowind style regeneration it scales with willpower, intelligence, and your character's "..
"current fatigue. \n\nIn addition, Morrowind and Skyrim regeneration styles reduce magicka "..
"regeneration while in combat.\n\n"..
"Now you can also use magicka regeneration formula as in Knu's Natural Magicka Regeneration. "..
"To get this choose:\n\n"..
"Regeneration type: Oblivion style\n"..
"Turn Magicka Decay On\n"..
"Set exp = 20\n"..
"On Oblivion regeneration setting page set:\n"..
"a = 0 and b = 10"
local decayDescription = "\nMakes magicka regeneration speed lower, the fuller magicka is. "..
"Formula for this mechanic is:\n\n"..
"restored' = restored * ( 1 - currentMagicka / maxMagicka ) ^ (exp / 10)\n\n"..
"Where restored magicka is the amount of magicka you would regenerate per second without this feature turned on. "..
"restored' is final amount of magicka restored per second. "..
"\n\nexp is the value you can tweak. Setting it to a higher value makes your magicka regen slow down a lot sooner. "..
"When exp = 1 then your magicka decays linearly.\n\n"..
"By default this feature is off and exp = 20"

local function createTableVar(id, restart)
    return mwse.mcm.createTableVariable{ id = id, table = settingsTable, restartRequired = (restart or false) }
end
local function newline(ref)
	ref:createInfo{text = "\n"}
end
local function postFormat(self)
    --self.elements.outerContainer.borderAllSides = self.indent
    --self.elements.outerContainer.alignY = 1.0
    --self.elements.outerContainer.layoutHeightFraction = 1.0
    self.elements.info.layoutOriginFractionX = 0.5
end
local function addSideBar(component)
    component.sidebar:createInfo{ text = sideBarDefault}
	component.sidebar:createHyperLink{
        text = "Made by C3pa",
        exec = "start https://www.nexusmods.com/users/37172285?tab=user+files",
        postCreate = postFormat,
    }
end
local function coefToPercentages()
	for i,v in pairs(settingsTable) do
		if i ~= "Version" and i ~= "regenerationType" and i ~= "bDecay" then
			if i == "fMagickaReturnSkyrim" or i == "fMagickaReturnMultOblivion" or i == "fMagickaReturnMultMorrowind" then
				settingsTable[i] = v * 1000
			elseif i == "fDecayExp" then
				settingsTable[i] = v * 10
			else
				settingsTable[i] = v * 100
			end
		end
	end
end

if (not multiplied) then
	coefToPercentages()
	multiplied = true
end
local template = mwse.mcm.createTemplate{
	name = "Magicka Regen Suite",
	headerImagePath = "MWSE/mods/Magicka Regen Suite/MCMHeader.tga"
}
template:register()

do	-- Settings
	do	-- Main Settings page
		local mainSettingsPage = template:createSideBarPage{ label = "Main Settings" }
		addSideBar(mainSettingsPage)
		mainSettingsPage.noScroll = true

		mainSettingsPage:createCategory{
			label = "\nMain Settings",
			description = regenerationTypesDescription
		}

		mainSettingsPage:createInfo{
			text = "The magicka regeneration type I want to use...",
			description = regenerationTypesDescription
		}

		mainSettingsPage:createDropdown{
			options = regenerationTypes,
			description = regenerationTypesDescription,
			variable = createTableVar("regenerationType")
		}

		newline(mainSettingsPage)
		mainSettingsPage:createSlider{
			label = "Regeneration speed modifier",
			description = (
				"\nUse this to quickly adjust regeneration speed of your "..
				"chosen regeneration style. At 100 % it has no effect. "..
				"\n\nFor much more precise control over individual coefficients, "..
				"please see each page.\n\nDefault: 100 %"
			),
			min = 1,
			max = 200,
			step = 1,
			jump = 10,
			variable = createTableVar("regenerationSpeedModifier")
		}

		newline(mainSettingsPage)
		mainSettingsPage:createOnOffButton{
			label = "Use Magicka speed decay feature?",
			variable = createTableVar("bDecay"),
			description = decayDescription
		}

		newline(mainSettingsPage)
		mainSettingsPage:createSlider{
			label = "exp = %s",
			description = decayDescription,
			min = 7,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("fDecayExp")
		}
	end
	do	-- Morrowind style regeneration settings
		local morrowindSettingsPage = template:createSideBarPage{ label = "Morrowind Style Regeneration" }
		addSideBar(morrowindSettingsPage)

		morrowindSettingsPage:createCategory{ label = "\nFormula:\n"}
		morrowindSettingsPage:createInfo{
			text = "Magicka % regenerated per second\n\n = ( (a / 100) + (b / 1000) x Willpower ) x fatigueTerm*\n\n"
		}

		morrowindSettingsPage:createSlider{
			label = "a = %s",
			description = (
				"\nRepresents base % of total magicka regenerated per second."..
				"\n\nDefault: 25\nIn Oblivion, this value is: 75"
			),
			min = 0,
			max = 150,
			step = 1,
			jump = 10,
			variable = createTableVar("fMagickaReturnBaseMorrowind"),
		}

		newline(morrowindSettingsPage)
		morrowindSettingsPage:createSlider{
			label = "b = %s",
			description = (
				"\nWillpower modifier to % of total magicka regenerated per second."..
				"\n\nDefault: 10\nIn Oblivion, this value is: 20"
			),
			min = 1,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("fMagickaReturnMultMorrowind"),
		}

		newline(morrowindSettingsPage)
		morrowindSettingsPage:createSlider{
			label = "Combat Penalty = %s",
			description = (
				"\nMagicka regeneration is lowered in combat. This setting "..
				"controls how much it is slower in battle. "..
				"\n\n100 % - no penalty to regeneration in combat\n\n"..
				"1 % - magicka regenerates 1 % of its standard "..
				"regeneration speed"..
				"\n\nDefault: 33 %"),
			min = 1,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("fCombatPenaltyMorrowind"),
		}

		morrowindSettingsPage:createInfo{ text = "\n\n*fatigueTerm is used in many game formulas."..
		"\n\nfatigueTerm = fFatigueBase - fFatigueMult x ( currentFatigue / maxFatigue )"..
		"\n\nWhere fFatigueBase and fFatigueMult are game settings present in vanilla Morrowind. "..
		"By default, their values are 1.25 and 0.5. \n\nAll right, what this means you might ask. "..
		"Well, it means your magicka regenerates 25 % faster at full fatigue and 25 % slower at empty fatigue."}
	end
	do	-- Oblivion style regeneration settings
		local oblivionSettingsPage = template:createSideBarPage{ label = "Oblivion Style Regeneration" }
		addSideBar(oblivionSettingsPage)
		oblivionSettingsPage.noScroll = true

		oblivionSettingsPage:createCategory{ label = "\nFormula:\n"}
		oblivionSettingsPage:createInfo{
			text = "Magicka % regenerated per second\n\n = (a / 100) + (b / 1000) x Willpower\n\n"
		}

		oblivionSettingsPage:createSlider{
			label = "a = %s",
			description = (
				"\nRepresents base % of total magicka regenerated per second."..
				"\n\nDefault (in Oblivion): 75\n"..
				"Default (in Natural Magicka Regeneration): 0"
			),
			min = 0,
			max = 150,
			step = 1,
			jump = 10,
			variable = createTableVar("fMagickaReturnBaseOblivion"),
		}

		newline(oblivionSettingsPage)
		oblivionSettingsPage:createSlider{
			label = "b = %s",
			description = (
				"\nWillpower modifier to % of total magicka regenerated per second."..
				"\n\nDefault (in Oblivion): 20\n"..
				"Default (in Natural Magicka Regeneration): 10"
			),
			min = 1,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("fMagickaReturnMultOblivion"),
		}
	end
	do	-- Skyrim style regeneration settings
		local skyrimSettingsPage = template:createSideBarPage{ label = "Skyrim Style Regeneration" }
		addSideBar(skyrimSettingsPage)
		skyrimSettingsPage.noScroll = true

		skyrimSettingsPage:createCategory{ label = "\nFormula:\n"}
		skyrimSettingsPage:createInfo{ text = "Magicka % regenerated per second\n\n = a / 10\n\n"}

		skyrimSettingsPage:createSlider{
			label = "a = %s",
			description = (
				"\nModify percentage of maximum magicka which characters regenerate per second."..
				"\n\nDefault (in Skyrim): 30 "),
			min = 1,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("fMagickaReturnSkyrim"),
		}

		newline(skyrimSettingsPage)
		skyrimSettingsPage:createSlider{
			label = "Combat Penalty = %s",
			description = (
				"\nMagicka regeneration is lowered in combat. This setting "..
				"controls how much it is slower in battle. "..
				"\n\n100 % - no penalty to regeneration in combat\n\n"..
				"1 % - magicka regenerates 1 % of its standard "..
				"regeneration speed"..
				"\n\nDefault (in Skyrim): 33 %"),
			min = 1,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("fCombatPenaltySkyrim"),
		}
	end
end

template.onClose = function()
	local t = {}
	for i,v in pairs(settingsTable) do
		if i ~= "Version" and i ~= "regenerationType" and i ~= "bDecay" then
			if i == "fMagickaReturnSkyrim" or i == "fMagickaReturnMultOblivion" or i == "fMagickaReturnMultMorrowind" then
				t[i] = v / 1000
			elseif i == "fDecayExp" then
				t[i] = v / 10
			else
				t[i] = v / 100
			end
		else
			t[i] = v
		end
	end
	config.saveConfig(t)
end