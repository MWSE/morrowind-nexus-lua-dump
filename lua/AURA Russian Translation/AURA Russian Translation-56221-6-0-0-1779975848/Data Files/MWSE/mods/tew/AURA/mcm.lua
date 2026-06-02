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
		table = tab or config,
	}
end

local template = mwse.mcm.createTemplate {
	name = metadata.package.name,
	headerImagePath = "\\Textures\\tew\\AURA\\AURA_logo.tga" }

local page = template:createPage { label = messages.mainSettings, noScroll = false }
page:createCategory {
	label = string.format("%s %s %s %s.\n%s \n\n%s:", metadata.package.name, version, messages.by, util.getAuthors(metadata.package.authors), messages.mainLabel, messages.settings),
}
page:createDropdown {
	label = messages.modLanguage,
	options = {
		{ label = "EN", value = "tew.AURA.i18n.en" },
		{ label = "FR", value = "tew.AURA.i18n.fr" },
		{ label = "RUS", value = "tew.AURA.i18n.rus" }
	},
	restartRequired = true,
	variable = registerVariable("language"),
}
page:createYesNoButton {
	label = messages.enableDebug,
	variable = registerVariable("debugLogOn"),
	restartRequired = true,
}
page:createKeyBinder {
	label = string.format("%s\n%s = %s", messages.volumeSave, messages.default, "V"),
	allowCombinations = false,
	variable = registerVariable("volumeSave"),
	restartRequired = true,
}
page:createYesNoButton {
	label = messages.enableOutdoor,
	variable = registerVariable("moduleAmbientOutdoor"),
	restartRequired = true,
}
page:createYesNoButton {
	label = messages.enableInterior,
	variable = registerVariable("moduleAmbientInterior"),
	restartRequired = true,
}
page:createYesNoButton {
	label = messages.enablePopulated,
	variable = registerVariable("moduleAmbientPopulated"),
	restartRequired = true,
}
page:createYesNoButton {
	label = messages.enableInteriorWeather,
	variable = registerVariable("moduleInteriorWeather"),
	restartRequired = true,
}
page:createYesNoButton {
	label = messages.enableSoundsOnStatics,
	variable = registerVariable("moduleSoundsOnStatics"),
	restartRequired = true,
}
page:createYesNoButton {
	label = messages.enableServiceVoices,
	variable = registerVariable("moduleServiceVoices"),
	restartRequired = true,
}
page:createYesNoButton {
	label = messages.enableUI,
	variable = registerVariable("moduleUI"),
	restartRequired = true,
}
page:createYesNoButton {
	label = messages.enableContainers,
	variable = registerVariable("moduleContainers"),
	restartRequired = true,
}
page:createYesNoButton {
	label = messages.enablePC,
	variable = registerVariable("modulePC"),
	restartRequired = true,
}
page:createYesNoButton {
	label = messages.enableMisc,
	variable = registerVariable("moduleMisc"),
	restartRequired = true,
}

local flushButton = page:createButton {
	buttonText = messages.refreshManifest,
	callback = function()
		soundBuilder.flushManifestFile()
	end,
}

local pageOA = template:createPage { label = messages.OA }
pageOA:createCategory {
	label = string.format("%s\n\n%s:", messages.OADesc, messages.settings),
}
--[[
pageOA:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.OAVol, messages.default, defaults.OAvol, messages.volume),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("OAvol")
}
--]]
pageOA:createYesNoButton {
	label = messages.playInteriorAmbient,
	variable = registerVariable("playInteriorAmbient"),
	restartRequired = true,
}

local pageIA = template:createPage { label = messages.IA }
pageIA:createCategory {
	label = string.format("%s\n\n%s:", messages.IADesc, messages.settings),
}
--[[
pageIA:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.IAVol, messages.default, defaults.intVol, messages.volume),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("intVol")
}
--]]
pageIA:createYesNoButton {
	label = messages.enableInteriorToExterior,
	variable = registerVariable("moduleInteriorToExterior"),
	restartRequired = true,
}

local pageSS = template:createPage { label = messages.SS }
pageSS:createCategory {
	label = string.format("%s\n\n%s:", messages.SSDesc, messages.settings),
}
pageSS:createYesNoButton {
	label = string.format("%s", messages.rainOnStaticsSounds),
	variable = registerVariable("playRainOnStatics"),
	restartRequired = true,
}
pageSS:createYesNoButton {
	label = string.format("%s", messages.shelterRain),
	variable = registerVariable("playRainInsideShelter"),
	restartRequired = true,
}
pageSS:createYesNoButton {
	label = string.format("%s", messages.shelterWind),
	variable = registerVariable("playWindInsideShelter"),
	restartRequired = true,
}
pageSS:createYesNoButton {
	label = string.format("%s", messages.shelterWeather),
	variable = registerVariable("shelterWeather"),
	restartRequired = true,
}
pageSS:createYesNoButton {
	label = string.format("%s", messages.ropeBridge),
	variable = registerVariable("playRopeBridge"),
	restartRequired = true,
}
pageSS:createYesNoButton {
	label = string.format("%s", messages.photodragons),
	variable = registerVariable("playPhotodragons"),
	restartRequired = true,
}
pageSS:createYesNoButton {
	label = string.format("%s", messages.bannerFlap),
	variable = registerVariable("playBannerFlap"),
	restartRequired = true,
}

--[[
local pagePA = template:createPage { label = messages.PA }
pagePA:createCategory {
	label = string.format("%s\n\n%s:", messages.PADesc, messages.settings)
}
pagePA:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.PAVol, messages.default, defaults.popVol, messages.volume),
	min = 0,
	max = 100,
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
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("IWvol")
}
--]]

local pageSV = template:createPage { label = messages.SV }
pageSV:createCategory {
	label = string.format("%s\n\n%s:", messages.SVDesc, messages.settings),
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
	variable = registerVariable("serviceChance"),
}
pageSV:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.SVVol, messages.default, defaults.volumes.misc.SVvol, messages.volume),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("SVvol", config.volumes.misc),
}

local pagePC = template:createPage { label = messages.PC }
pagePC:createCategory {
	label = string.format("%s\n\n%s:", messages.PCDesc, messages.settings),
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
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("vsVol", config.volumes.misc),
}
pagePC:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.tauntChance, messages.default, defaults.tauntChance, messages.chance),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("tauntChance"),
}
pagePC:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.tVol, messages.default, defaults.volumes.misc.tVol, messages.volume),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("tVol", config.volumes.misc),
}

local pageC = template:createPage { label = messages.containers }
pageC:createCategory {
	label = string.format("%s\n\n%s:", messages.containersDesc, messages.settings),
}
pageC:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.CVol, messages.default, defaults.volumes.misc.Cvol, messages.volume),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("Cvol", config.volumes.misc),
}

local pageUI = template:createPage { label = messages.UI }
pageUI:createCategory {
	label = string.format("%s\n\n%s:", messages.UIDesc, messages.settings),
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
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("UIvol", config.volumes.misc),
}

local pageMisc = template:createPage { label = messages.misc }
pageMisc:createCategory {
	label = string.format("%s\n\n%s:", messages.miscDesc, messages.settings),
}
pageMisc:createYesNoButton {
	label = string.format("%s %s ", messages.rainSounds, messages.WtS),
	variable = registerVariable("rainSounds"),
	restartRequired = true,
}
pageMisc:createYesNoButton {
	label = string.format("%s %s", messages.windSounds, messages.WtS),
	variable = registerVariable("windSounds"),
	restartRequired = true,
}
pageOA:createYesNoButton {
	label = messages.playInteriorWind,
	variable = registerVariable("playInteriorWind"),
	restartRequired = true,
}
pageMisc:createYesNoButton {
	label = messages.altitudeWind,
	variable = registerVariable("altitudeWind"),
	restartRequired = true,
}
pageMisc:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.altitudeWindVolMin, messages.default, defaults.volumes.misc.altitudeWindVolMin, messages.volume),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("altitudeWindVolMin", config.volumes.misc),
}
pageMisc:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.altitudeWindVolMax, messages.default, defaults.volumes.misc.altitudeWindVolMax, messages.volume),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("altitudeWindVolMax", config.volumes.misc),
}
pageMisc:createYesNoButton {
	label = messages.playSplash,
	variable = registerVariable("playSplash"),
}
pageMisc:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.splashVol, messages.default, defaults.volumes.misc.splashVol, messages.volume),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("splashVol", config.volumes.misc),
}
pageMisc:createYesNoButton {
	label = messages.playYurtFlap,
	variable = registerVariable("playYurtFlap"),
	restartRequired = true,
}
pageMisc:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.yurtVol, messages.default, defaults.volumes.misc.yurtVol, messages.volume),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("yurtVol", config.volumes.misc),
}

pageMisc:createYesNoButton {
	label = messages.underwaterRain,
	variable = registerVariable("underwaterRain"),
	restartRequired = true,
}
pageMisc:createYesNoButton {
	label = messages.thunderSounds,
	variable = registerVariable("thunderSounds"),
	restartRequired = true,
}
pageMisc:createYesNoButton {
	label = messages.thunderSoundsDelay,
	variable = registerVariable("thunderSoundsDelay"),
}
pageMisc:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.thunderVolMin, messages.default, defaults.volumes.misc.thunderVolMin, messages.volume),
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = registerVariable("thunderVolMin", config.volumes.misc),
}
pageMisc:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.thunderVolMax, messages.default, defaults.volumes.misc.thunderVolMax, messages.volume),
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = registerVariable("thunderVolMax", config.volumes.misc),
}
pageMisc:createYesNoButton {
	label = messages.floraSounds,
	variable = registerVariable("floraSounds"),
	restartRequired = true,
}
pageMisc:createSlider {
	label = string.format("%s %s = %s%%. %s %%", messages.floraVol, messages.default, defaults.volumes.misc.floraVol, messages.volume),
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = registerVariable("floraVol", config.volumes.misc),
}

template:saveOnClose(configPath, config)
mwse.mcm.register(template)
