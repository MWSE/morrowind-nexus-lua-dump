--[[
	Sample mod
	@author		
	@version	0.10
	@changelog	0.10 Initial version

	The goal of this mod is to give a starting template with some examples to create a MWSE Lua mod
	with a Mod Config Menu (MCM) for Morrowind. It tries to use the best practices.

	The mod itself doesn't do much, it captures CombatStarted and MouseButtonDown to show how to manage events.
	It is probably not compatible with OpenMW

	MWSE Lua ref https://mwse.github.io/MWSE/
	Lua https://www.lua.org/docs.html

	Mod folders structure

	|-- Data Files
	|	|-- <modName>.txt
	|	|-- <modName>-metadata.toml
	|	|-- MWSE
	|	|	|-- config
	|	|	|	|-- <modName>.json
	|	|	|-- mods
	|	|	|	|-- <modName>
	|	|	|	|	|-- main.lua
	|	|	|	|-- i18n
	|	|	|	|	|-- deu.lua
	|	|	|	|	|-- eng.lua
	|	|	|	|	|-- fra.lua

	Folder i18n is only needed if you use mod translation
	<modName>.txt is an optional readme text file, its location is not explictely defined

	You can find more lua mod examples at https://github.com/Hrnchamd/MWSE-Lua-mods
	You can also check my mod Morrowind Mouse Control at https://www.nexusmods.com/morrowind/mods/48254

	DEBUG
	You can add logDebug to log infos in MWSE.log by setting debugMode to true in the config <modName>.json. Otherwise it should be set to false.
	In case of issues with you mod, check MWSE.log flie in Morrowind folder, you will see
]]--


-- Adapts settings to your mod
local modName = "Sample Mod"	-- MUST be same as the mod folder 
local modVersion = "V0.10"
local modConfig = modName	-- file name for MCM config file
local modAuthor= "me"


--[[

	Mod translation
	https://mwse.github.io/MWSE/guides/mod-translations/
	
	Translation in not complete because I'm lazy, it's just to show how it works

]]--

-- returns a table of transation, you acces a translation by its key: i18n("HELP_ATTACKED")
local i18n = mwse.loadTranslations(modName)


--[[

	mod config

]]

-- list of values for the MCM dropdown menu
local modifierKeyOptions = {
	{ label = "NONE", value = 0 },
	{ label = "Cycle Spells", value = 1 },
	{ label = "Cycle Weapons", value = 2 },
}

-- Define mod config default values
local modDefaultConfig = {
	modEnabled = true,
	--
	timeScale = 25,
	mwCtrlAction = modifierKeyOptions[1]["value"],	-- BEWARE table index start at 1 so I selected the first value (NONE)
	myText = "my sample text",
	debugMode = true	-- true for debugging purpose should be false for mod release, it could be a MCM option, currently you have to change its value in the config file
}


-- Load config file, and fill in default values for missing elements.
local config = mwse.loadConfig(modConfig)
if (config == nil) then
	config = modDefaultConfig
else
	for key, value in pairs(modDefaultConfig) do
		if (config[key] == nil) then
			config[key] = value
		end
	end
end


--[[

		Helper functions

]]--


--- Log a string as Info level
-- @param msg string to be logged as Info in MWSE.log
local function logInfo(msg)
	-- https://www.lua.org/pil/5.2.html
	-- TODO get ride of string.format in calling 
	--s = string.format('[' .. modName .. '] ' .. 'INFO ' .. fmt, unpack(arg))
	--mwse.log(s)
	mwse.log('[' .. modName .. '] ' .. 'INFO ' .. msg)
end


--- Log a message to MWSE.log if debug mode is enabled
-- @param msg string to be logged as Info in MWSE.log
local function logDebug(msg)
	if (config.debugMode) then
		mwse.log('[' .. modName .. '] ' .. 'DEBUG ' .. msg)
	end
end


--[[

	event handlers

]]

--- Callback function for MouseButtonDown event
-- https://mwse.github.io/MWSE/events/mouseButtonDown/
-- @param e event
local function onMouseButtonDown(e)
	-- only in game
	if tes3.menuMode() then
		return
	end
	
	-- mod must be enabled
	if not config.modEnabled then
		return
	end

	if (e.button == 3) then
		tes3.messageBox(i18n("BUTTON_4"))
	end
	
	if (e.button == 4) then
		tes3.messageBox(i18n("BUTTON_5"))
	end
end


--- Callback function for CombatStarted event
-- https://mwse.github.io/MWSE/events/combatStarted/
-- @param e event
local function onCombatStarted(e)
	-- mod must be enabled
	if not config.modEnabled then
		return
	end

	-- Sometimes it's useful to log debug info (only logged when debugMode is true)
	logDebug(string.format("onCombatStarted event - actor %d, target %d", e.actor.actorType, e.target.actorType))

	-- https://mwse.github.io/MWSE/references/actor-types/
	-- is the attacking actor is not the player ?
	if (e.actor.actorType ~= tes3.actorType.player) then
		tes3.messageBox(i18n("HELP_ATTACKED"))
	else
		tes3.messageBox(i18n("BEWARE_SCUM"))
	end
end


--[[
	constructor
]]

local function initialize()
	-- registers needed events, better to use tes.event reference instead of the name https://mwse.github.io/MWSE/references/events/
	event.register(tes3.event.mouseButtonDown, onMouseButtonDown)
	event.register(tes3.event.combatStarted, onCombatStarted)
	logInfo(modName .. " " .. modVersion .. " initialized")
end
event.register(tes3.event.initialized, initialize)


--[[
	mod config menu

	https://easymcm.readthedocs.io/en/latest/

]]

---
-- @param id name of the variable
-- @return a TableVariable
local function createtableVar(id)
	return mwse.mcm.createTableVariable{
		id = id,
		table = config
	}  
end


--- Create the MCM menu
-- Basic UI, more fancier can be created like hiding parts of UI based on settings
-- UI should be transalated also
local function registerModConfig()
    local template = mwse.mcm.createTemplate(modName)
	template:saveOnClose(modConfig, config)
	
	-- https://easymcm.readthedocs.io/en/latest/components/pages/classes/SideBarPage.html
	local page = template:createSideBarPage{
		label = "Sidebar Page",
		description = modName .. " " .. modVersion
	}

	-- You can create categories to group settings
	-- https://easymcm.readthedocs.io/en/latest/components/categories/classes/Category.html
	local catMain = page:createCategory(modName)
	catMain:createYesNoButton {
		label = "Enable " .. modName,
		description = "Allows you to Enable or Disable this mod",
		variable = createtableVar("modEnabled"),
		defaultSetting = true,
	}

	local catSettings = page:createCategory("Mod Settings")
	catSettings:createSlider {
		label = "Time Scale",
		description = "Changes the speed of the day/night cycle.",
		min = 0,
		max = 50,
		step = 1,
		jump = 5,
		variable = createtableVar("timeScale")
	}

	-- didn't find ref for this setting
	catSettings:createDropdown {
		label = "Action for CTRL + MouseWheel",
		description = "Select the wanted action when using mouse wheel while holding CTRL key down",
		options = modifierKeyOptions,	  
		variable = createtableVar("mwCtrlAction"),
		defaultSetting = 0,
	}

	-- https://easymcm.readthedocs.io/en/latest/components/settings/classes/TextField.html
	catSettings:createTextField {
		label = "Text input",
		description = "Enter a text",
		variable = createtableVar("myText")
	}

	-- https://easymcm.readthedocs.io/en/latest/components/settings/classes/KeyBinder.html
	catSettings:createKeyBinder {
		label = "Assign Keybind",
		allowCombinations = true,
		defaultSetting = {
			keyCode = tes3.scanCode.k,
			--These default to false
			isShiftDown = true,
			isAltDown = false,
			isControlDown = false,
		},
		variable = createtableVar("myKeybind")
	}

	mwse.mcm.register(template)
end

event.register(tes3.event.modConfigReady, registerModConfig)
