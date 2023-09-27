local metadata = toml.loadMetadata("AURA")
local configPath = metadata.package.name
local config = require("tew.AURA.config")
local defaults = require("tew.AURA.defaults")
local util = require("tew.AURA.util")
local version = metadata.package.version
local soundBuilder = require("tew.AURA.soundBuilder")
local messages = require(config.language).messages

local function registerVariable(id, tab)
	return mwse.mcm.createTableVariable {
		id = id,
		table = tab or config
	}
end

local template = mwse.mcm.createTemplate {
	name = metadata.package.name,
	headerImagePath = "\\Textures\\tew\\AURA\\AURA_logo.tga" }

local page = template:createPage { label = messages.mainSettings, noScroll = true }
page:createCategory {
	label = string.format("%s %s %s %s.\n%s \n\n%s:", metadata.package.name, version, messages.by, util.getAuthors(metadata.package.authors), messages.mainLabel, messages.settings)
}
page:createDropdown {
	label = messages.modLanguage,
	options = {
		{ label = "EN", value = "tew.AURA.i18n.en" },
		{ label = "FR", value = "tew.AURA.i18n.fr" }
	},
	restartRequired = true,
	variable = registerVariable("language")
}
page:createYesNoButton {
	label = messages.enableDebug,
	variable = registerVariable("debugLogOn"),
	restartRequired = true
}
page:createKeyBinder{
	label = string.format("%s\n%s = %s", messages.volumeSave, messages.default, "V"),
	allowCombinations = false,
	variable = registerVariable("volumeSave"),
	restartRequired = true
}
page:createYesNoButton {
	label = messages.enableOutdoor,
	variable = registerVariable("moduleAmbientOutdoor"),
	restartRequired = true
}
page:createYesNoButton {
	label = messages.enableInterior,
	variable = registerVariable("moduleAmbientInterior"),
	restartRequired = true
}
page:createYesNoButton {
	label = messages.enablePopulated,
	variable = registerVariable("moduleAmbientPopulated"),
	restartRequired = true
}
page:createYesNoButton {
	label = messages.enableInteriorWeather,
	variable = registerVariable("moduleInteriorWeather"),
	restartRequired = true
}
page:createYesNoButton {
	label = messages.enableServiceVoices,
	variable = registerVariable("moduleServiceVoices"),
	restartRequired = true
}
page:createYesNoButton {
	label = messages.enableUI,
	variable = registerVariable("moduleUI"),
	restartRequired = true
}
page:createYesNoButton {
	label = messages.enableContainers,
	variable = registerVariable("moduleContainers"),
	restartRequired = true
}
page:createYesNoButton {
	label = messages.enablePC,
	variable = registerVariable("modulePC"),
	restartRequired = true
}
page:createYesNoButton {
	label = messages.enableMisc,
	variable = registerVariable("moduleMisc"),
	restartRequired = true
}

local flushButton = page:createButton {
	buttonText = messages.refreshManifest,
	callback = function()
		soundBuilder.flushManifestFile()
	end,
}

local pageOA = template:createPage { label = messages.OA }
pageOA:createCategory {
	label = string.format("%s\n\n%s:", messages.OADesc, messages.settings)
}
--[[
pageOA:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.OAVol, messages.default, defaults.OAvol, messages.volume),
	min = 0,
	max = 200,
	step = 1,
	jump = 10,
	variable = registerVariable("OAvol")
}
--]]
pageOA:createYesNoButton {
	label = messages.playInteriorAmbient,
	variable = registerVariable("playInteriorAmbient"),
	restartRequired = true
}

local pageIA = template:createPage { label = messages.IA }
pageIA:createCategory {
	label = string.format("%s\n\n%s:", messages.IADesc, messages.settings)
}
--[[
pageIA:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.IAVol, messages.default, defaults.intVol, messages.volume),
	min = 0,
	max = 200,
	step = 1,
	jump = 10,
	variable = registerVariable("intVol")
}
--]]
pageIA:createYesNoButton {
	label = messages.enableTaverns,
	variable = registerVariable("interiorMusic"),
	restartRequired = true
}

template:createExclusionsPage {
	label = messages.tavernsBlacklist,
	description = messages.tavernsDesc,
	toggleText = messages.toggle,
	leftListLabel = messages.tavernsDisabled,
	rightListLabel = messages.tavernsEnabled,
	showAllBlocked = false,
	variable = mwse.mcm.createTableVariable {
		id = "disabledTaverns",
		table = config,
	},

	filters = {

		{
			label = messages.tavernsEnabled,
			callback = (
				function()
					local enabledTaverns = {}
					for cell in tes3.iterate(tes3.dataHandler.nonDynamicData.cells) do
						if cell.isInterior then
							for npc in cell:iterateReferences(tes3.objectType.npc) do
								if (npc.object.class.id == "Publican"
									or npc.object.class.id == "T_Sky_Publican"
									or npc.object.class.id == "T_Cyr_Publican") then
									table.insert(enabledTaverns, cell.name)
								end
							end
						end
					end

					-- Remove duplicated tavern names
					table.sort(enabledTaverns)
					local previous
					local duplicates = {}
					for k, v in pairs(enabledTaverns) do
						if v == previous then
							table.insert(duplicates, k, v)
						end
						previous = v
					end
					for k, _ in pairs(duplicates) do
						table.remove(enabledTaverns, k - 1)
					end

					return enabledTaverns
				end
				)
		},

	}
}

--[[
local pagePA = template:createPage { label = messages.PA }
pagePA:createCategory {
	label = string.format("%s\n\n%s:", messages.PADesc, messages.settings)
}
pagePA:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.PAVol, messages.default, defaults.popVol, messages.volume),
	min = 0,
	max = 200,
	step = 1,
	jump = 10,
	variable = registerVariable("popVol")
}

local pageIW = template:createPage { label = messages.IW }
pageIW:createCategory {
	label = string.format("%s\n\n%s:", messages.IWDesc, messages.settings)
}
pageIW:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.IWVol, messages.default, defaults.IWvol, messages.volume),
	min = 0,
	max = 200,
	step = 1,
	jump = 10,
	variable = registerVariable("IWvol")
}
--]]

local pageSV = template:createPage { label = messages.SV }
pageSV:createCategory {
	label = string.format("%s\n\n%s:", messages.SVDesc, messages.settings)
}
pageSV:createYesNoButton {
	label = messages.enableRepair,
	variable = registerVariable("serviceRepair"),
}
pageSV:createYesNoButton {
	label = messages.enableSpells,
	variable = registerVariable("serviceSpells"),
}
pageSV:createYesNoButton {
	label = messages.enableTraining,
	variable = registerVariable("serviceTraining"),
}
pageSV:createYesNoButton {
	label = messages.enableSpellmaking,
	variable = registerVariable("serviceSpellmaking"),
}
pageSV:createYesNoButton {
	label = messages.enableEnchantment,
	variable = registerVariable("serviceEnchantment"),
}
pageSV:createYesNoButton {
	label = messages.enableTravel,
	variable = registerVariable("serviceTravel"),
}
pageSV:createYesNoButton {
	label = messages.enableBarter,
	variable = registerVariable("serviceBarter"),
}
pageSV:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.serviceChance, messages.default, defaults.serviceChance, messages.chance),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("serviceChance")
}
pageSV:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.SVVol, messages.default, defaults.volumes.misc.SVvol, messages.volume),
	min = 0,
	max = 200,
	step = 1,
	jump = 10,
	variable = registerVariable("SVvol", config.volumes.misc)
}

local pagePC = template:createPage { label = messages.PC }
pagePC:createCategory {
	label = string.format("%s\n\n%s:", messages.PCDesc, messages.settings)
}
pagePC:createYesNoButton {
	label = messages.enableHealth,
	variable = registerVariable("PChealth"),
}
pagePC:createYesNoButton {
	label = messages.enableFatigue,
	variable = registerVariable("PCfatigue"),
}
pagePC:createYesNoButton {
	label = messages.enableMagicka,
	variable = registerVariable("PCmagicka"),
}
pagePC:createYesNoButton {
	label = messages.enableDisease,
	variable = registerVariable("PCDisease"),
}
pagePC:createYesNoButton {
	label = messages.enableBlight,
	variable = registerVariable("PCBlight"),
}
pagePC:createYesNoButton {
	label = messages.enableTaunts,
	variable = registerVariable("PCtaunts"),
}
pagePC:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.vsVol, messages.default, defaults.volumes.misc.vsVol, messages.volume),
	min = 0,
	max = 200,
	step = 1,
	jump = 10,
	variable = registerVariable("vsVol", config.volumes.misc)
}
pagePC:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.tauntChance, messages.default, defaults.tauntChance, messages.chance),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("tauntChance")
}
pagePC:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.tVol, messages.default, defaults.volumes.misc.tVol, messages.volume),
	min = 0,
	max = 200,
	step = 1,
	jump = 10,
	variable = registerVariable("tVol", config.volumes.misc)
}

local pageC = template:createPage { label = messages.containers }
pageC:createCategory {
	label = string.format("%s\n\n%s:", messages.containersDesc, messages.settings)
}
pageC:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.CVol, messages.default, defaults.volumes.misc.Cvol, messages.volume),
	min = 0,
	max = 200,
	step = 1,
	jump = 10,
	variable = registerVariable("Cvol", config.volumes.misc)
}

local pageUI = template:createPage { label = messages.UI }
pageUI:createCategory {
	label = string.format("%s\n\n%s:", messages.UIDesc, messages.settings)
}
pageUI:createYesNoButton {
	label = messages.UITraining,
	variable = registerVariable("UITraining"),
}
pageUI:createYesNoButton {
	label = messages.UITravel,
	variable = registerVariable("UITravel"),
}
pageUI:createYesNoButton {
	label = messages.UISpells,
	variable = registerVariable("UISpells"),
}
pageUI:createYesNoButton {
	label = messages.UIBarter,
	variable = registerVariable("UIBarter"),
}
pageUI:createYesNoButton {
	label = messages.UIEating,
	variable = registerVariable("UIEating"),
}
pageUI:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.UIVol, messages.default, defaults.volumes.misc.UIvol, messages.volume),
	min = 0,
	max = 200,
	step = 1,
	jump = 10,
	variable = registerVariable("UIvol", config.volumes.misc)
}

local pageMisc = template:createPage { label = messages.misc }
pageMisc:createCategory {
	label = string.format("%s\n\n%s:", messages.miscDesc, messages.settings)
}
pageMisc:createYesNoButton {
	label = string.format("%s %s ", messages.rainSounds, messages.WtS),
	variable = registerVariable("rainSounds"),
}
pageMisc:createYesNoButton {
	label = string.format("%s", messages.rainOnStaticsSounds),
	variable = registerVariable("playRainOnStatics"),
}
pageMisc:createYesNoButton {
	label = string.format("%s %s", messages.windSounds, messages.WtS),
	variable = registerVariable("windSounds"),
}
pageOA:createYesNoButton {
	label = messages.playInteriorWind,
	variable = registerVariable("playInteriorWind"),
	restartRequired = true
}

--[[
pageMisc:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.windVol, messages.default, defaults.windVol, messages.volume),
	min = 0,
	max = 200,
	step = 1,
	jump = 10,
	variable = registerVariable("windVol")
}
--]]
pageMisc:createYesNoButton {
	label = messages.playSplash,
	variable = registerVariable("playSplash"),
}
pageMisc:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.splashVol, messages.default, defaults.volumes.misc.splashVol, messages.volume),
	min = 0,
	max = 200,
	step = 1,
	jump = 10,
	variable = registerVariable("splashVol", config.volumes.misc)
}
pageMisc:createYesNoButton {
	label = messages.playYurtFlap,
	variable = registerVariable("playYurtFlap"),
}
pageMisc:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.yurtVol, messages.default, defaults.volumes.misc.yurtVol, messages.volume),
	min = 0,
	max = 200,
	step = 1,
	jump = 10,
	variable = registerVariable("yurtVol", config.volumes.misc)
}

pageMisc:createYesNoButton {
	label = messages.underwaterRain,
	variable = registerVariable("underwaterRain"),
	restartRequired = true
}

template:saveOnClose(configPath, config)
mwse.mcm.register(template)
