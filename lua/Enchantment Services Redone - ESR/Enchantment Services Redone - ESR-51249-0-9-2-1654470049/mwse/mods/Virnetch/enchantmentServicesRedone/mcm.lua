
local common = require("Virnetch.enchantmentServicesRedone.common")


--- Returns the default value for a setting
--- @param id string The setting to get the value for, subtables within the config file can be separated with dots.
--- @param valueMult number Optional. A multiplier for the value stored in the config file.
--- @return string defaultValue The default value of the setting. Booleans are converted to sOn/sOff.
local function getDefaultSetting(id, valueMult)
	local defaultValue = common.defaultConfig
	local keys = string.split(id, "%.")
	for _, key in ipairs(keys) do
		defaultValue = defaultValue[key]
	end

	if defaultValue == true then
		defaultValue = tes3.findGMST(tes3.gmst.sOn).value
	elseif defaultValue == false then
		defaultValue = tes3.findGMST(tes3.gmst.sOff).value
	elseif valueMult and tonumber(defaultValue) then
		defaultValue = valueMult * tonumber(defaultValue)
	end

	return tostring(defaultValue)
end

--- Returns a string of commonly used information for a mcm setting, including its default value and if the setting requires the game to be restarted
--- @param id string The setting to get the value for, subtables within the config file can be separated with dots.
--- @param restartRequired? boolean Optional. True if the setting requires the game to be restarted.
--- @param valueMult? number Optional. A multiplier for the value stored in the config file.
--- @return string
local function descriptionDefaults(id, restartRequired, valueMult)
	local defaultSetting = getDefaultSetting(id, valueMult)

	local description = "\n\n"..common.i18n("mcm.default", { defaultSetting = defaultSetting })
	if restartRequired then
		description = description.."\n"..common.i18n("mcm.restartRequired")
	end

	return description
end

local function updateSliderNumber(self, value)
	self.elements.label.text = self.label .. ": " .. value
end

local function setSliderLabelAsHundredth(self)
	if self.elements.slider then
		local number = tonumber( self.elements.slider.widget.current + self.min ) / 100
		updateSliderNumber(self, string.format("%.2f", number))
	end
end

local offererConfig = {
	deciphering = {
		variable = mwse.mcm.createTableVariable{
			id = "offerers",
			table = common.config.deciphering
		},
		checkIfOffers = common.offersDeciphering,
		buttonLabel = common.i18n("service.deciphering.name")
	},
	transcription = {
		variable = mwse.mcm.createTableVariable{
			id = "offerers",
			table = common.config.transcription
		},
		checkIfOffers = common.offersTranscription,
		buttonLabel = common.i18n("service.transcription.name")
	},
	recharge = {
		variable = mwse.mcm.createTableVariable{
			id = "offerers",
			table = common.config.recharge
		},
		checkIfOffers = common.offersRecharge,
		buttonLabel = common.i18n("service.recharge.name")
	},
	blankScrolls = {
		variable = mwse.mcm.createTableVariable{
			id = "barterers",
			table = common.config.itemAdditions.blankScrolls
		},
		checkIfOffers = common.bartersBlankScrolls,
		buttonLabel = common.i18n("mcm.category.blankScrolls")
	}
}



local template = mwse.mcm.createTemplate(common.mod.name)
template:saveOnClose("enchantmentServicesRedone", common.config)

local pageGeneral = template:createSideBarPage{
	label = common.i18n("mcm.page.general.label"),
	-- description = common.i18n("mcm.page.general.description")
}

-- Add the default sidebar description
do
	-- Mod name, version and link
	local header = pageGeneral.sidebar:createCategory(common.i18n("mcm.mainDescription.header", { version = common.mod.version }))
	header:createHyperlink{
		text = common.i18n("mcm.link.esr.link"),
		url = common.i18n("mcm.link.esr.link"),
	}

	-- Main description
	header:createInfo{ text = common.i18n("mcm.mainDescription.description") }

	-- Link to svengineer99's original mod
	local svengineer99 = pageGeneral.sidebar:createCategory(common.i18n("mcm.mainDescription.svengineer99"))
	svengineer99:createHyperlink{
		text = common.i18n("mcm.link.Enchantment_Services.name"),
		url = common.i18n("mcm.link.Enchantment_Services.link"),
	}

	-- Links to recommended mods
	local linksCategory = pageGeneral.sidebar:createCategory(common.i18n("mcm.category.modLinks"))
	linksCategory:createHyperlink{
		text = common.i18n("mcm.link.OAAB_Data.name"),
		url = common.i18n("mcm.link.OAAB_Data.link"),
	}
	linksCategory:createHyperlink{
		text = common.i18n("mcm.link.OAAB_Integrations.name"),
		url = common.i18n("mcm.link.OAAB_Integrations.link"),
	}
	linksCategory:createHyperlink{
		text = common.i18n("mcm.link.buyingGame.name"),
		url = common.i18n("mcm.link.buyingGame.link"),
	}
end


-- General Settings
do

	local generalCategory = pageGeneral:createCategory(common.i18n("mcm.category.general"))
	generalCategory:createOnOffButton{	-- modEnabled
		label = common.i18n("mcm.general.modEnabled.label"),
		description = common.i18n("mcm.general.modEnabled.description")
			.. descriptionDefaults("modEnabled", true),
		restartRequired = true,
		variable = mwse.mcm.createTableVariable{
			id = "modEnabled",
			table = common.config
		}
	}

	generalCategory:createOnOffButton{	-- showTooltips
		label = common.i18n("mcm.general.showTooltips.label"),
		description = common.i18n("mcm.general.showTooltips.description")
			.. descriptionDefaults("showTooltips"),
	--	restartRequired = true,
		variable = mwse.mcm.createTableVariable{
			id = "showTooltips",
			table = common.config
		}
	}

	local gmstCategory = pageGeneral:createCategory(common.i18n("mcm.category.gmst"))
	gmstCategory:createOnOffButton{		-- changePassiveRecharge
		label = common.i18n("mcm.general.changePassiveRecharge.label"),
		description = common.i18n("mcm.general.changePassiveRecharge.description")
			.. descriptionDefaults("changePassiveRecharge", true),
		restartRequired = true,
		variable = mwse.mcm.createTableVariable{
			id = "changePassiveRecharge",
			table = common.config
		}
	}

	gmstCategory:createSlider{			-- passiveRecharge
		label = common.i18n("mcm.general.passiveRecharge.label"),
		description = common.i18n("mcm.general.passiveRecharge.description")
			.. descriptionDefaults("passiveRecharge"),
		max = 100,
		min = 0,
		step = 5,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "passiveRecharge",
			table = common.config
		},
		postCreate = function(self)
			if self.elements.slider then
				local newValue = tonumber( self.elements.slider.widget.current + self.min ) / 1000
				updateSliderNumber(self, string.format("%.3f", newValue))
			end
		end,
		updateValueLabel = function(self)
			if self.elements.slider then
				local newValue = tonumber( self.elements.slider.widget.current + self.min ) / 1000
				if (
					common.config.modEnabled
					and common.config.changePassiveRecharge
					and not math.isclose(newValue, tes3.findGMST(tes3.gmst.fMagicItemRechargePerSecond).value, 0.0001)
				) then
					tes3.messageBox(string.format("fMagicItemRechargePerSecond: %.3f", newValue))
					tes3.findGMST(tes3.gmst.fMagicItemRechargePerSecond).value = newValue
				end
				updateSliderNumber(self, string.format("%.3f", newValue))
			end
		end
	}

	local miscCategory = pageGeneral:createCategory(common.i18n("mcm.category.misc"))
	miscCategory:createSlider{			-- dispositionFactor
		label = common.i18n("mcm.general.dispositionFactor.label"),
		description = common.i18n("mcm.general.dispositionFactor.description")
			.. descriptionDefaults("dispositionFactor"),
		max = 50,
		min = 0,
		variable = mwse.mcm.createTableVariable{
			id = "dispositionFactor",
			table = common.config
		}
	}

	miscCategory:createDropdown{		-- logLevel
		label = "Logging Level",
		description = "Set the log level."
			.. descriptionDefaults("logLevel"),
		options = {
			{ label = "TRACE", value = "TRACE"},
			{ label = "DEBUG", value = "DEBUG"},
			{ label = "INFO", value = "INFO"},
			{ label = "ERROR", value = "ERROR"},
			{ label = "NONE", value = "NONE"},
		},
		variable = mwse.mcm.createTableVariable{
			id = "logLevel",
			table = common.config
		},
		callback = function(self)
			common.log:setLogLevel(self.variable.value)
		end
	}
end

-- Settings for Deciphering
do
	local serviceName = common.i18n("service.deciphering.name")
	local pageDeciphering = template:createSideBarPage{
		label = serviceName,
		description = common.i18n("mcm.page.service.description", {
			serviceName = serviceName,
			serviceDescription = common.i18n("service.deciphering.descriptionLong")
		})
	}

	local serviceCategory = pageDeciphering:createCategory(common.i18n("mcm.category.service"))
	serviceCategory:createOnOffButton{	-- enableService
		label = common.i18n("mcm.service.enableService.label", {serviceName = serviceName}),
		description = common.i18n("mcm.service.enableService.description", {serviceName = serviceName})
			.. descriptionDefaults("deciphering.enableService"),
		variable = mwse.mcm.createTableVariable{
			id = "enableService",
			table = common.config.deciphering
		}
	}

	serviceCategory:createSlider{		-- costMult
		label = common.i18n("mcm.service.costMult.label"),
		description = common.i18n("mcm.service.deciphering.costMult.description")
			.. descriptionDefaults("deciphering.costMult", false, 0.01),
		max = 200,
		min = 0,
		step = 5,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "costMult",
			table = common.config.deciphering
		},
		postCreate = setSliderLabelAsHundredth,
		updateValueLabel = setSliderLabelAsHundredth
	}

	serviceCategory:createOnOffButton{	-- enableChance
		label = common.i18n("mcm.service.enableChance.label"),
		description = common.i18n("mcm.service.deciphering.enableChance.description")
			.. descriptionDefaults("deciphering.enableChance"),
		variable = mwse.mcm.createTableVariable{
			id = "enableChance",
			table = common.config.deciphering
		}
	}

	serviceCategory:createSlider{		-- chanceRequired
		label = common.i18n("mcm.service.deciphering.chanceRequired.label"),
		description = common.i18n("mcm.service.deciphering.chanceRequired.description")
			.. descriptionDefaults("deciphering.chanceRequired"),
		max = 200,
		min = 0,
		step = 5,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "chanceRequired",
			table = common.config.deciphering
		}
	}

	serviceCategory:createOnOffButton{	-- npcLearns
		label = common.i18n("mcm.service.deciphering.npcLearns.label"),
		description = common.i18n("mcm.service.deciphering.npcLearns.description")
			.. descriptionDefaults("deciphering.npcLearns"),
		variable = mwse.mcm.createTableVariable{
			id = "npcLearns",
			table = common.config.deciphering
		}
	}

	local miscCategory = pageDeciphering:createCategory(common.i18n("mcm.category.misc"))
	miscCategory:createOnOffButton{		-- showSourceInTooltip
		label = common.i18n("mcm.service.deciphering.showSourceInTooltip.label"),
		description = common.i18n("mcm.service.deciphering.showSourceInTooltip.description")
			.. descriptionDefaults("deciphering.showSourceInTooltip"),
		variable = mwse.mcm.createTableVariable{
			id = "showSourceInTooltip",
			table = common.config.deciphering
		}
	}

	miscCategory:createDropdown{		-- sourceTextToShowInTooltip
		label = common.i18n("mcm.service.deciphering.sourceTextToShowInTooltip.label"),
		description = common.i18n("mcm.service.deciphering.sourceTextToShowInTooltip.description"),
		options = {
			{
				label = common.i18n("mcm.service.deciphering.sourceTextToShowInTooltip.options.nothing"),
				value = "nothing"
			},
			{
				label = common.i18n("mcm.service.deciphering.sourceTextToShowInTooltip.options.full"),
				value = "full"
			},
			{
				label = common.i18n("mcm.service.deciphering.sourceTextToShowInTooltip.options.oneLine"),
				value = "oneLine"
			},
			{
				label = common.i18n("mcm.service.deciphering.sourceTextToShowInTooltip.options.fullEnglish"),
				value = "fullEnglish"
			},
			{
				label = common.i18n("mcm.service.deciphering.sourceTextToShowInTooltip.options.oneLineEnglish"),
				value = "oneLineEnglish"
			}
		},
		variable = mwse.mcm.createTableVariable{
			id = "sourceTextToShowInTooltip",
			table = common.config.deciphering
		}
	}

	miscCategory:createButton{			-- resetOfferers
		buttonText = common.i18n("mcm.service.resetOfferers.buttonText"),
		label = common.i18n("mcm.service.resetOfferers.label"),
		description = common.i18n("mcm.service.resetOfferers.description", {
			serviceName = common.i18n("service.deciphering.name"),
			offerersPageLabel = common.i18n("mcm.page.offerers.label")
		}),
		callback = function()
			-- common.config.deciphering.offerers = common.defaultConfig.deciphering.offerers
			offererConfig.deciphering.variable:set(common.defaultConfig.deciphering.offerers)
			tes3.messageBox(common.i18n("mcm.service.resetOfferers.message", { serviceName = common.i18n("service.deciphering.name") }))
		end
	}
end

-- Settings for Transcription
do
	local serviceName = common.i18n("service.transcription.name")
	local pageTranscription = template:createSideBarPage{
		label = serviceName,
		description = common.i18n("mcm.page.service.description", {
			serviceName = serviceName,
			serviceDescription = common.i18n("service.transcription.descriptionLong")
		})
	}

	local generalCategory = pageTranscription:createCategory(common.i18n("mcm.category.general"))
	generalCategory:createOnOffButton{	-- enable
		label = common.i18n("mcm.service.enable.label", {serviceName = serviceName}),
		description = common.i18n("mcm.service.enable.description", {serviceName = serviceName})
			.. descriptionDefaults("transcription.enable", true),
		restartRequired = true,
		variable = mwse.mcm.createTableVariable{
			id = "enable",
			table = common.config.transcription
		}
	}

	generalCategory:createOnOffButton{	-- requireScroll
		label = common.i18n("mcm.service.transcription.requireScroll.label"),
		description = common.i18n("mcm.service.transcription.requireScroll.description")
			.. descriptionDefaults("transcription.requireScroll"),
		variable = mwse.mcm.createTableVariable{
			id = "requireScroll",
			table = common.config.transcription
		}
	}

--[[
	generalCategory:createOnOffButton{	-- requireSoulGem
		label = common.i18n("mcm.service.transcription.requireSoulGem.label"),
		description = common.i18n("mcm.service.transcription.requireSoulGem.description")
			.. descriptionDefaults("transcription.requireSoulGem", false),
		variable = mwse.mcm.createTableVariable{
			id = "requireSoulGem",
			table = common.config.transcription
		}
	}
 ]]

	local serviceCategory = pageTranscription:createCategory(common.i18n("mcm.category.service"))
	serviceCategory:createOnOffButton{	-- enableService
		label = common.i18n("mcm.service.enableService.label", {serviceName = serviceName}),
		description = common.i18n("mcm.service.enableService.description", {serviceName = serviceName})
			.. descriptionDefaults("transcription.enableService"),
		variable = mwse.mcm.createTableVariable{
			id = "enableService",
			table = common.config.transcription
		}
	}

	serviceCategory:createSlider{		-- costMult
		label = common.i18n("mcm.service.costMult.label"),
		description = common.i18n("mcm.service.transcription.costMult.description")
			.. descriptionDefaults("transcription.costMult", false, 0.01),
		max = 200,
		min = 0,
		step = 5,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "costMult",
			table = common.config.transcription
		},
		postCreate = setSliderLabelAsHundredth,
		updateValueLabel = setSliderLabelAsHundredth
	}

	serviceCategory:createOnOffButton{	-- enableChance
		label = common.i18n("mcm.service.enableChance.label"),
		description = common.i18n("mcm.service.enableChance.description", {serviceName = common.i18n("service.transcription.name")})
			.. descriptionDefaults("transcription.enableChance"),
		variable = mwse.mcm.createTableVariable{
			id = "enableChance",
			table = common.config.transcription
		}
	}

	serviceCategory:createSlider{		-- chanceRequired
		label = common.i18n("mcm.service.transcription.chanceRequired.label"),
		description = common.i18n("mcm.service.transcription.chanceRequired.description")
			.. descriptionDefaults("transcription.chanceRequired"),
		max = 200,
		min = 0,
		step = 5,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "chanceRequired",
			table = common.config.transcription
		}
	}


	local pcCategory = pageTranscription:createCategory(common.i18n("mcm.category.player"))
	pcCategory:createOnOffButton{		-- enablePlayer
		label = common.i18n("mcm.service.transcription.enablePlayer.label"),
		description = common.i18n("mcm.service.transcription.enablePlayer.description")
			.. descriptionDefaults("transcription.enablePlayer", true),
		restartRequired = true,
		variable = mwse.mcm.createTableVariable{
			id = "enablePlayer",
			table = common.config.transcription
		}
	}

	pcCategory:createSlider{		-- playerChanceMult
		label = common.i18n("mcm.service.transcription.playerChanceMult.label"),
		description = common.i18n("mcm.service.transcription.playerChanceMult.description")
			.. descriptionDefaults("transcription.playerChanceMult", false, 0.01),
		max = 200,
		min = 0,
		step = 5,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "playerChanceMult",
			table = common.config.transcription
		},
		postCreate = setSliderLabelAsHundredth,
		updateValueLabel = setSliderLabelAsHundredth
	}

	pcCategory:createSlider{			-- experienceMult
		label = common.i18n("mcm.service.transcription.experienceMult.label"),
		description = common.i18n("mcm.service.transcription.experienceMult.description")
			.. descriptionDefaults("transcription.experienceMult", false, 0.01),
		max = 200,
		min = 0,
		step = 5,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "experienceMult",
			table = common.config.transcription
		},
		postCreate = setSliderLabelAsHundredth,
		updateValueLabel = setSliderLabelAsHundredth
	}

	local miscCategory = pageTranscription:createCategory(common.i18n("mcm.category.misc"))
	miscCategory:createOnOffButton{		-- customName
		label = common.i18n("mcm.service.transcription.customName.label"),
		description = common.i18n("mcm.service.transcription.customName.description")
			.. descriptionDefaults("transcription.customName"),
		variable = mwse.mcm.createTableVariable{
			id = "customName",
			table = common.config.transcription
		}
	}

	miscCategory:createOnOffButton{		-- showOriginalText
		label = common.i18n("mcm.service.transcription.showOriginalText.label"),
		description = common.i18n("mcm.service.transcription.showOriginalText.description")
			.. descriptionDefaults("transcription.showOriginalText", true),
		variable = mwse.mcm.createTableVariable{
			id = "showOriginalText",
			table = common.config.transcription
		}
	}

	miscCategory:createOnOffButton{		-- preventScripted
		label = common.i18n("mcm.service.transcription.preventScripted.label"),
		description = common.i18n("mcm.service.transcription.preventScripted.description")
			.. descriptionDefaults("transcription.preventScripted"),
		variable = mwse.mcm.createTableVariable{
			id = "preventScripted",
			table = common.config.transcription
		}
	}

	miscCategory:createButton{			-- resetOfferers
		buttonText = common.i18n("mcm.service.resetOfferers.buttonText"),
		label = common.i18n("mcm.service.resetOfferers.label"),
		description = common.i18n("mcm.service.resetOfferers.description", {
			serviceName = common.i18n("service.transcription.name"),
			offerersPageLabel = common.i18n("mcm.page.offerers.label")
		}),
		callback = function()
			-- common.config.transcription.offerers = common.defaultConfig.transcription.offerers
			offererConfig.transcription.variable:set(common.defaultConfig.transcription.offerers)
			tes3.messageBox(common.i18n("mcm.service.resetOfferers.message", { serviceName = common.i18n("service.transcription.name") }))
		end
	}
end

-- Settings for Recharge
do
	local serviceName = common.i18n("service.recharge.name")
	local pageRecharge = template:createSideBarPage{
		label = serviceName,
		description = common.i18n("mcm.page.service.description", {
			serviceName = serviceName,
			serviceDescription = common.i18n("service.recharge.descriptionLong")
		})
	}

	local serviceCategory = pageRecharge:createCategory(common.i18n("mcm.category.service"))
	serviceCategory:createOnOffButton{	-- enableService
		label = common.i18n("mcm.service.enableService.label", {serviceName = serviceName}),
		description = common.i18n("mcm.service.enableService.description", {serviceName = serviceName})
			.. descriptionDefaults("recharge.enableService"),
		variable = mwse.mcm.createTableVariable{
			id = "enableService",
			table = common.config.recharge
		}
	}

	serviceCategory:createSlider{		-- costMult
		label = common.i18n("mcm.service.costMult.label"),
		description = common.i18n("mcm.service.recharge.costMult.description")
			.. descriptionDefaults("recharge.costMult", false, 0.01),
		max = 200,
		min = 0,
		step = 5,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "costMult",
			table = common.config.recharge
		},
		postCreate = setSliderLabelAsHundredth,
		updateValueLabel = setSliderLabelAsHundredth
	}

	serviceCategory:createOnOffButton{	-- enableChance
		label = common.i18n("mcm.service.enableChance.label"),
		description = common.i18n("mcm.service.enableChance.description", {serviceName = common.i18n("service.recharge.name")})
			.. descriptionDefaults("recharge.enableChance"),
		variable = mwse.mcm.createTableVariable{
			id = "enableChance",
			table = common.config.recharge
		}
	}

	serviceCategory:createSlider{		-- chanceRequired
		label = common.i18n("mcm.service.recharge.chanceRequired.label"),
		description = common.i18n("mcm.service.recharge.chanceRequired.description")
			.. descriptionDefaults("recharge.chanceRequired"),
		max = 200,
		min = 0,
		step = 5,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "chanceRequired",
			table = common.config.recharge
		}
	}

	local miscCategory = pageRecharge:createCategory(common.i18n("mcm.category.misc"))
	miscCategory:createButton{			-- resetOfferers
		buttonText = common.i18n("mcm.service.resetOfferers.buttonText"),
		label = common.i18n("mcm.service.resetOfferers.label"),
		description = common.i18n("mcm.service.resetOfferers.description", {
			serviceName = common.i18n("service.recharge.name"),
			offerersPageLabel = common.i18n("mcm.page.offerers.label")
		}),
		callback = function()
			-- common.config.recharge.offerers = common.defaultConfig.recharge.offerers
			offererConfig.recharge.variable:set(common.defaultConfig.recharge.offerers)
			tes3.messageBox(common.i18n("mcm.service.resetOfferers.message", { serviceName = common.i18n("service.recharge.name") }))
		end
	}
end

-- Settings for Item Additions
do
	local pageItemAdditions = template:createSideBarPage{
		label = common.i18n("mcm.page.items.label")
	}

	local blankScrollsCategory = pageItemAdditions:createCategory(common.i18n("mcm.category.blankScrolls"))
	blankScrollsCategory:createOnOffButton{	-- blankScrolls.enabled
		label = common.i18n("mcm.itemAdditions.blankScrolls.enabled.label"),
		description = common.i18n("mcm.itemAdditions.blankScrolls.enabled.description")
			.. descriptionDefaults("itemAdditions.blankScrolls.enabled", true),
		restartRequired = true,
		variable = mwse.mcm.createTableVariable{
			id = "enabled",
			table = common.config.itemAdditions.blankScrolls
		}
	}

	blankScrollsCategory:createSlider{		-- blankScrolls.frequency
		label = common.i18n("mcm.itemAdditions.frequency.label"),
		description = common.i18n("mcm.itemAdditions.frequency.description")
			.. descriptionDefaults("itemAdditions.blankScrolls.frequency", true),
		max = 10,
		min = 1,
		step = 1,
		jump = 1,
		variable = mwse.mcm.createTableVariable{
			id = "frequency",
			table = common.config.itemAdditions.blankScrolls
		}
	}

	blankScrollsCategory:createButton{		-- resetOfferers
		buttonText = common.i18n("mcm.service.resetOfferers.buttonText"),
		label = common.i18n("mcm.service.resetOfferers.label"),
		description = common.i18n("mcm.service.resetOfferers.description", {
			serviceName = common.i18n("mcm.category.blankScrolls"),
			offerersPageLabel = common.i18n("mcm.page.offerers.label")
		}),
		callback = function()
			-- common.config.recharge.offerers = common.defaultConfig.recharge.offerers
			offererConfig.blankScrolls.variable:set(common.defaultConfig.itemAdditions.blankScrolls.barterers)
			tes3.messageBox(common.i18n("mcm.service.resetOfferers.message", { serviceName = common.i18n("mcm.category.blankScrolls") }))
		end
	}
end

-- Service Offerers exclusions page
do
	-- Get the defaults for each service
	local defaultOfferers = {
		deciphering = {},
		transcription = {},
		recharge = {},
		blankScrolls = {}
	}
	for offerer in tes3.iterateObjects({
		tes3.objectType.creature,
		tes3.objectType.npc
	}) do
		if not offerer.isInstance then
			local offererId = offerer.id:lower()
			for serviceId, config in pairs(offererConfig) do
				if config.checkIfOffers(offerer, false) then
					table.insert(defaultOfferers[serviceId], offererId)
				end
			end
		end
	end

	-- The filter is the same for all buttons: all NPCs and creatures
	local function getPossibleOfferers()
		local possibleOfferers = {}
		for offerer in tes3.iterateObjects({
			tes3.objectType.creature,
			tes3.objectType.npc
		}) do
			if not offerer.isInstance then
				local offererId = offerer.id:lower()
				table.insert(possibleOfferers, offererId)
			end
		end
		table.sort(possibleOfferers)
		return possibleOfferers
	end

	-- The filters for the exclusion page
	local filterButtons = {}
	for serviceId, config in pairs(offererConfig) do
		filterButtons[#filterButtons+1] = {
			serviceId = serviceId,
			label = config.buttonLabel,
			callback = getPossibleOfferers
		}
	end

	--- Checks which of the filters/buttons is active to determine which config value we are altering
	--- @return string
	local function getSelectedServiceId()
		if not template.currentPage.elements.filterList then
			-- Starts at the first filter
			return filterButtons[1].serviceId
		end
		for k, button in pairs(template.currentPage.elements.filterList.children) do
			if button.widget.state == 4 then
				return filterButtons[k].serviceId
			end
		end
	end

	template:createExclusionsPage{
		label = common.i18n("mcm.page.offerers.label"),
		description = common.i18n("mcm.page.offerers.description"),
		leftListLabel = common.i18n("mcm.page.offerers.leftListLabel"),
		rightListLabel = common.i18n("mcm.page.offerers.rightListLabel"),
		variable = mwse.mcm.createVariable{
			get = function()
				local serviceId = getSelectedServiceId()
				if serviceId then
					-- Get the current `offerers` table from the config of the selected service
					local offerers = table.deepcopy(offererConfig[serviceId].variable:get())
					for _, offererId in ipairs(defaultOfferers[serviceId]) do
						if offerers[offererId] == nil then
							-- These are true by default, but not stored in the current config.
							-- Add them so that they show up in the left list
							offerers[offererId] = true
						end
					end
					return offerers
				end
				return {}
			end,
			set = function(self, newOfferers)
				local serviceId = getSelectedServiceId()
				if serviceId then
					-- Get the old offerers and compare it to the new variable
					-- to figure out what was changed
					local oldOfferers = self:get()

					-- Change from nil to false to allow disabling the service
					-- for those that have it by default
					for id in pairs(oldOfferers) do
						if oldOfferers[id] and not newOfferers[id] then
							common.log:debug("%s Disabled for %s", serviceId, id)
							newOfferers[id] = false
						end
					end
					for id in pairs(newOfferers) do
						if newOfferers[id] and not oldOfferers[id] then
							common.log:debug("%s Enabled for %s", serviceId, id)
						end
					end

					-- Remove offerers that are at their default values so they
					-- aren't stored in the config
					for id in pairs(newOfferers) do
						if newOfferers[id] and table.find(defaultOfferers[serviceId], id) then
							-- True in config and True by default
							newOfferers[id] = nil
						elseif not newOfferers[id] and not table.find(defaultOfferers[serviceId], id) then
							-- False in config and false by default
							newOfferers[id] = nil
						end
					end

					-- Set the actual config variable
					offererConfig[serviceId].variable:set(newOfferers)
				end
			end
		},
		filters = filterButtons
	}
end

mwse.mcm.register(template)