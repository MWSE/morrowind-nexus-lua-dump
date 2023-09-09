local util = require("livebookediting.util")
local config = require("livebookediting.config")
local log = require("logging.logger").getLogger("livebookediting") --[[@as mwseLogger]]

local i18n = mwse.loadTranslations("livebookediting")
local mcmConfig = config.getConfig()



--- Creates some empty vertical space.
local function newline(container)
	container:createInfo({ text = "\n" })
end

local function center(self)
	self.elements.info.layoutOriginFractionX = 0.5
end

--- Returns the localized description for given setting. It should be available as "mcm.settingName.description" table.
---@param settingName string
---@param defaultValue any The default value to append to description string.
---@return string
local function getDescription(settingName, defaultValue)
	local default = ""
	if defaultValue then
		default = ("\n\n%s: %s."):format(
			i18n("mcm.default"),
			defaultValue
		)
	end
	return ("\n%s%s"):format(
		i18n("mcm." .. settingName .. ".description"),
		default
	)
end

local authors = {
	{
		name = "C3pa",
		url = "https://www.nexusmods.com/morrowind/users/37172285?tab=user+files",
	},
}

local function createSidebar(container)
	container.sidebar:createInfo({
		text = i18n("mcm.sidebar"),
		postCreate = center,
	})
	for _, author in ipairs(authors) do
		container.sidebar:createHyperLink({
			text = author.name,
			url = author.url,
			postCreate = center,
		})
	end
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = i18n("mcm.modname"),
		headerImagePath = "MWSE/mods/livebookediting/mcm/Header.tga",
		onClose = function()
			config.saveConfig(mcmConfig)
		end
	})
	template:register()

	local page = template:createSideBarPage({ label = i18n("mcm.settings") })
	createSidebar(page)

	newline(page)
	do -- Hotkeys category
		local hotkeys = page:createCategory({ label = i18n("mcm.hotkeys.label") })

		newline(hotkeys)
		hotkeys:createKeyBinder({
			label = i18n("mcm.hotkeys.bookKey.label"),
			description = getDescription("hotkeys.bookKey", "Alt-O"),
			allowCombinations = true,
			variable = mwse.mcm.createTableVariable({
				id = "bookKey",
				table = mcmConfig,
				restartRequired = true
			}),
		})

		newline(hotkeys)
		hotkeys:createKeyBinder({
			label = i18n("mcm.hotkeys.scrollKey.label"),
			description = getDescription("hotkeys.scrollKey", "Alt-P"),
			allowCombinations = true,
			variable = mwse.mcm.createTableVariable({
				id = "scrollKey",
				table = mcmConfig,
				restartRequired = true
			}),
		})
	end

	newline(page)
	do -- Test item category
		local testItem = page:createCategory({ label = i18n("mcm.testItem.label") })

		testItem:createOnOffButton({
			label = i18n("mcm.testItem.addBook.label"),
			description = getDescription("testItem.addBook", i18n("mcm.Off")),
			variable = mwse.mcm.createTableVariable({
				id = "addBook",
				table = mcmConfig,
				restartRequired = false,
			})
		})

		testItem:createButton({
			buttonText = i18n("mcm.testItem.add"),
			label = i18n("mcm.testItem.addBookNow.label"),
			description = i18n("mcm.testItem.addBookNow.description"),
			callback = function()
				util.addItem("book")
			end,
		})

		testItem:createOnOffButton({
			label = i18n("mcm.testItem.addScroll.label"),
			description = getDescription("testItem.addScroll", i18n("mcm.Off")),
			variable = mwse.mcm.createTableVariable({
				id = "addScroll",
				table = mcmConfig,
				restartRequired = false,
			})
		})

		testItem:createButton({
			buttonText = i18n("mcm.testItem.add"),
			label = i18n("mcm.testItem.addScrollNow.label"),
			description = i18n("mcm.testItem.addScrollNow.description"),
			callback = function()
				util.addItem("scroll")
			end,
		})
	end

	newline(page)
	page:createDropdown({
		label = i18n("mcm.logLevel.label"),
		description = getDescription("logLevel"),
		options = {
			{ label = "Trace", value = "TRACE" },
			{ label = "Debug", value = "DEBUG" },
			{ label = "Info",  value = "INFO" },
			{ label = "Warn",  value = "WARN" },
			{ label = "Error", value = "ERROR" },
			{ label = "None",  value = "NONE" },
		},
		variable = mwse.mcm.createTableVariable({ id = "logLevel", table = mcmConfig }),
		callback = function(self)
			log:setLogLevel(self.variable.value)
		end
	})
end

event.register(tes3.event.modConfigReady, registerModConfig)
