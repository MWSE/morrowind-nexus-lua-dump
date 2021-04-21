
local common = require("Units and Vagueness.common")
local modName = "Units and Vagueness"
local versionString = "v0.98"
common.version = 0.98

-- Configuration table.
local defaultConfig = {
	version = common.version,
	--keybindShowAdditionalInfo = { tes3.scanCode.leftAlt },
	useUnitConversionType = 1,
	useSmallerUnits = 1,
	potionsInMilliLitres = true,
	summarizeStacks = 0,
	useVagueGold = 3,
	useSoldItemValues = true,
	hidePettyItemValues = false,
	useWeightGoldRatio = false,
	--addWeightHintToMagicEffect = true
}
--local config = table.copy(defaultConfig)

-- 2nd parameter advantage: anything not defined in the loaded file inherits the value from defaultConfig
local config = mwse.loadConfig(modName, defaultConfig)
assert(config)

-- Set component states for new components.
--[[local importedComponents = config.components
for k, v in pairs(defaultConfig.components) do
	if (importedComponents[k] == nil) then
		importedComponents[k] = v
	end
end]]

common.config = config



-- Make sure we have the latest MWSE version.
if (mwse.buildDate < 20200926) then
	event.register("loaded", function()
		tes3.messageBox(common.dictionary.updateRequired)
	end)
	return
end



local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

-- Load translation data.
common.loadTranslation()

local function modConfigReady()
	--dm("modConfigReady")
	local template = mwse.mcm.createTemplate(modName)

	---template:saveOnClose(modName, config)
	template.onClose = function()
		mwse.saveConfig(modName, config, {indent = true})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label = "Preferences",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.2
			self.elements.sideToSideBlock.children[2].widthProportional = 0.8
		end
	}

	-- weight stuff
	local title = preferences:createCategory{
		label = string.format("%s %s", modName, versionString)
	}
	title:createInfo{
		text = common.dictionary.summary
	}

	-- weight stuff
	local weights = preferences:createCategory{
		label = "Weight Units"
	}

	weights:createDropdown{
		label = common.dictionary.configUseUnitConversionType,
		description = common.dictionary.configUseUnitConversionTypeDescription,
		options = common.dictionary.configUseUnitConversionTypeOptions,
		variable = createConfigVariable("useUnitConversionType")
	}

	weights:createDropdown{
		label = common.dictionary.configUseSmallerUnits,
		description = common.dictionary.configUseSmallerUnitsDescription,
		options = common.dictionary.configUseSmallerUnitsOptions,
		variable = createConfigVariable("useSmallerUnits")
	}

	weights:createOnOffButton{
		label = common.dictionary.configPotionsInMilliLitres,
		description = common.dictionary.configPotionsInMilliLitresDescription,
		variable = createConfigVariable("potionsInMilliLitres")
	}

	weights:createDropdown{
		label = common.dictionary.configSummarizeStacks,
		description = common.dictionary.configSummarizeStacksDescription,
		options = common.dictionary.configSummarizeStacksOptions,
		variable = createConfigVariable("summarizeStacks")
	}
	--weights.borderBottom = 12

	-- gold stuff
	local golds = preferences:createCategory{
		label = "Gold Values"
	}

	golds:createDropdown{
		label = common.dictionary.configUseVagueGold,
		description = common.dictionary.configUseVagueGoldDescription,
		options = common.dictionary.configUseVagueGoldOptions,
		variable = createConfigVariable("useVagueGold")
	}

	golds:createOnOffButton{
		label = common.dictionary.configUseSoldItemValues,
		description = common.dictionary.configUseSoldItemValuesDescription,
		variable = createConfigVariable("useSoldItemValues")
	}

	golds:createOnOffButton{
		label = common.dictionary.configHidePettyItemValues,
		description = common.dictionary.configHidePettyItemValuesDescription,
		variable = createConfigVariable("hidePettyItemValues")
	}
	--golds.borderBottom = 12

	-- gold/weight
	local goldweights = preferences:createCategory{
		label = "Gold/Weight Ratio"
	}

	goldweights:createOnOffButton{
		label = common.dictionary.configUseWeightGoldRatio,
		description = common.dictionary.configUseWeightGoldRatioDescription,
		variable = createConfigVariable("useWeightGoldRatio")
	}

	--[[preferences:createSlider{
		label = "NPC repeated bargain modifier",
		description = "fBargainOfferMulti GMST (game default: -4, suggested: -5)\n(the more you insist and fail, the more they dislike you)",
		variable = createConfigVariable("fBargainOfferMulti")
		,min = -20, max = 0
	}]]

	-- Credits
	preferences:createInfo{ text = "Credits:" }
	preferences:createInfo{ text = "Units and Vagueness Programming, Flask Icon: Insicht (insicht#3725 on Discord)" }
	preferences:createInfo{ text = "UI Expansion Programming: NullCascade, Hrnchamd, Petethegoat, Jiopsi, Remiros, Mort, Wix, abot" }

	mwse.mcm.register(template)
	mwse.log("[Units and Vagueness] Loaded configuration:")
	mwse.log(json.encode(config, { indent = true }))
end
event.register('modConfigReady', modConfigReady)











--[[ Loads the configuration file for use.
local function loadConfig()
	-- Clear any current config values.
	config = {}

	-- First, load the defaults.
	table.copy(defaultConfig, config)

	-- Then load any other values from the config file.
	local configJson = mwse.loadConfig("Units and Vagueness")
	if (configJson ~= nil) then
		if (configJson.version == nil or common.version > configJson.version) then
			configJson.components = nil
		end

		-- Merge the configs.
		table.copy(configJson, config)
	end

	-- Set component states for new components.
	local importedComponents = config.components
	for k, v in pairs(defaultConfig.components) do
		if (importedComponents[k] == nil) then
			importedComponents[k] = v
		end
	end

	common.config = config

	mwse.log("[Units and Vagueness] Loaded configuration:")
	mwse.log(json.encode(config, { indent = true }))
end
loadConfig()]]


--[[ Set up MCM.
local modConfig = require("Units and Vagueness.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig(common.dictionary.modName, modConfig)
end
event.register("modConfigReady", registerModConfig)]]


-- Run our modules.
local function onInitialized()
	dofile("Data Files/MWSE/mods/Units and Vagueness/MenuContents.lua")
	dofile("Data Files/MWSE/mods/Units and Vagueness/MenuInventory.lua")
	dofile("Data Files/MWSE/mods/Units and Vagueness/Tooltip.lua")
end
event.register("initialized", onInitialized)
