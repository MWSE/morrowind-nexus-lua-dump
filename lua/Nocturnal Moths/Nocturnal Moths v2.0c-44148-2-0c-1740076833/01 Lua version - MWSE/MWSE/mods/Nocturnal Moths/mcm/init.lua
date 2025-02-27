local log = require("logging.logger").getLogger("Nocturnal Moths") --[[@as mwseLogger]]

local config = require("Nocturnal Moths.config")
local lanterns = require("Nocturnal Moths.data")


local i18n = mwse.loadTranslations("Nocturnal Moths")

local authors = {
	{
		name = "R-Zero",
		url = "https://next.nexusmods.com/profile/Reizeron/mods",
	},
	{
		name = "C3pa",
		url = "https://next.nexusmods.com/profile/C3pa/mods",
	},
}


--- @param self mwseMCMInfo|mwseMCMHyperlink
local function center(self)
	self.elements.info.absolutePosAlignX = 0.5
end

--- Adds default text to sidebar. Has a list of all the authors that contributed to the mod.
--- @param container mwseMCMSideBarPage
local function createSidebar(container)
	container.sidebar:createInfo({
		text = i18n("mcm.sidebar"),
		postCreate = center,
	})
	for _, author in ipairs(authors) do
		container.sidebar:createHyperlink({
			text = author.name,
			url = author.url,
			postCreate = center,
		})
	end
end

local blocked = {
	[""] = true,
	["editormarker.nif"] = true,
}
---@param mesh string Lowercased mesh path
local function validLightMesh(mesh)
	return not blocked[mesh] and not lanterns[mesh]
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = i18n("Nocturnal Moths"),
		--headerImagePath = "MWSE/mods/Nocturnal Moths/mcm/Header.tga",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
	template:saveOnClose("Nocturnal Moths", config)
	template:register()

	local page = template:createSideBarPage({
		label = i18n("mcm.settings"),
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

	page:createOnOffButton({
		label = i18n("mcm.enableSound.label"),
		description = i18n("mcm.enableSound.description"),
		configKey = "enableSound",
		restartRequired = true,
		restartRequiredMessage = i18n("mcm.leaveCell")
	})

	page:createSlider({
		label = i18n("mcm.soundVolume.label"),
		description = i18n("mcm.soundVolume.description"),
		decimalPlaces = 2,
		min = 0.0,
		max = 1.0,
		step = 0.01,
		jump = 0.05,
		configKey = "soundVolume",
	})

	page:createDropdown({
		label = i18n("mcm.logLevel.label"),
		description = i18n("mcm.logLevel.description"),
		options = {
			{ label = "Trace", value = "TRACE" },
			{ label = "Debug", value = "DEBUG" },
			{ label = "Info",  value = "INFO" },
			{ label = "Warn",  value = "WARN" },
			{ label = "Error", value = "ERROR" },
			{ label = "None",  value = "NONE" },
		},
		configKey = "logLevel",
		callback = function(self)
			log:setLogLevel(self.variable.value)
		end
	})

	local whitelistPage = template:createExclusionsPage({
		label = i18n("mcm.whitelist.label"),
		description = i18n("mcm.whitelist.description"),
		leftListLabel = i18n("mcm.whitelist.leftListLabel"),
		rightListLabel = i18n("mcm.whitelist.rightListLabel"),
		configKey = "whitelist",
		filters = {{
			label = "Lights",
			callback = function()
				---@type table<string, boolean>
				local items = {}
				---@param light tes3light
				for light in tes3.iterateObjects(tes3.objectType.light) do
					local mesh = string.lower(light.mesh)
					if validLightMesh(mesh) then
						items[mesh] = true
					end
				end
				---@type string[]
				local results = {}
				for k, _ in pairs(items) do
					table.insert(results, k)
				end
				table.sort(results)
				return results
			end
		}}
	})
end

event.register(tes3.event.modConfigReady, registerModConfig)
