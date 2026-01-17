local I 			= require('openmw.interfaces')
local hudLayerSize 	= getHudLayerSize()
local util 			= require('openmw.util')
local input 		= require('openmw.input')
local TextColor   	= getColorFromGameSettings("FontColor_color_normal")

local presetColors = {
    "caa560", -- fontColor_color_normal (gold)
    "d4b77f", -- goldenMix
    "dfc99f", -- FontColor_color_normal_over
    "eee2c9", -- lightText
    "253170", -- fontColor_color_journal_link
    "3a4daf", -- fontColor_color_journal_link_over
    "707ecf", -- fontColor_color_journal_link_pressed
    "81cded", -- sky blue
    "d4edfc", -- light blue
    "bfd4bc", -- light green
}

local settingsTemplate = {}
local tempKey

local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end

tempKey = "General Settings"
settingsTemplate[tempKey] = {
	key = "Settings"..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                                        ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "HOTKEYS_REQUIRE_UI",
			renderer = "checkbox",
			name = "Hotkeys require UI open",
			description = "If enabled, increase/decrease/mode hotkeys only work when the UI is visible",
			default = false,
		},
		{
			key = "HOTKEY_TIMECONTROL_TOGGLE_UI",
			renderer = "inputBinding",
			name = "[Show UI] Show/hide the time control panel",
			description = "Click and press a key",
			default = "TimeControlToggle",
			argument = { type = "action", key = "timecontrolToggleUI" },
		},
		{
			key = "HOTKEY_TIMECONTROL_INCREASE",
			renderer = "inputBinding",
			name = "[Increase] Increase time scale",
			description = "Click and press a key",
			default = "TimeControlIncrease",
			argument = { type = "action", key = "timecontrolIncrease" },
		},
		{
			key = "HOTKEY_TIMECONTROL_DECREASE",
			name = "[Decrease] Decrease time scale",
			description = "Click and press a key",
			renderer = "inputBinding",
			default = "TimeControlDecrease",
			argument = { type = "action", key = "timecontrolDecrease" },
		},
		{
			key = "HOTKEY_TIMECONTROL_TOGGLE_MODE",
			name = "[Mode] Switch between Day and Simulation TimeScale",
			description = "Click and press a key",
			renderer = "inputBinding",
			default = "TimeControlMode",
			argument = { type = "action", key = "timecontrolToggleMode" },
		},
	}
}

tempKey = "UI Settings"
settingsTemplate[tempKey] = {
	key = "Settings"..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                                         ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "SHOW_TITLE",
			name = "Show title",
			description = "Where to display the time info",
			renderer = "select",
			default = "Above Player",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Above Player", "Inside Player", "Hidden" },
			},
		},
		{
			key = "HUD_X_POS",
			name = "X Position",
			description = "You can just drag it around with the mouse",
			renderer = "number",
			integer = true,
			default = math.floor(hudLayerSize.x/2),
		},		
		{
			key = "HUD_Y_POS",
			name = "Y Position",
			description = "You can just drag it around with the mouse",
			renderer = "number",
			integer = true,
			default = math.floor(hudLayerSize.y-(100)),
		},			
		{
			key = "TEXT_COLOR",
			name = "Text color",
			description = "Change the color of the time display",
			disabled = false,
			renderer = "SuperColorPicker2",
			default = util.color.hex(TextColor:asHex()),
			argument = { presetColors = presetColors },
		},
		{
			key = "TEXT_SIZE",
			name = "Text Size",
			description = "Change the text size. Default is 14",
			renderer = "number",
			default = 14,
			argument = { min = 0, max = 100, },
		},
		{
			key = "PLAYER_WIDTH",
			name = "Widget width",
			description = "Default is 210",
			renderer = "number",
			default = 210,
			argument = { min = 50, max = 1000, },
		},
		{
			key = "PLAYER_HEIGHT",
			name = "Widget height",
			description = "Default is 55",
			renderer = "number",
			default = 55,
			argument = { min = 30, max = 500, },
		},
		{
			key = "THEME_COLOR",
			name = "Theme Color",
			description = "Change the color of the borders and buttons",
			disabled = false,
			renderer = "SuperColorPicker2",
			default = util.color.hex(TextColor:asHex()),
			argument = { presetColors = presetColors },
		},
		{
			key = "BACKGROUND_ALPHA",
			name = "Background Opacity",
			description = "Values between 0-1, default is 0.85",
			renderer = "number",
			default = 0.85,
			argument = { min = 0, max = 1, },
		},
	},	
}

for id, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

I.Settings.registerPage {
	key = MODNAME,
	l10n = "none",
	name = "Time Control",
	description = "Control day time and simulation time\nBy OwnlyMe"
}

local settingsKeyToSection = {}
for _, template in pairs(settingsTemplate) do
	for _, entry in pairs(template.settings) do
		settingsKeyToSection[entry.key] = template.key
	end
end

function setSetting(key, value)
	local sectionKey = settingsKeyToSection[key]
	if sectionKey then
		storage.playerSection(sectionKey):set(key, value)
	end
end

local function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for i, entry in pairs(template.settings) do
			_G[entry.key] = settingsSection:get(entry.key)
		end
	end
end

readAllSettings()

-- Pre-populate default keybinds if not already set
local bindingSection = storage.playerSection('OMWInputBindings')

if not bindingSection:get("TimeControlToggle") then
	bindingSection:set("TimeControlToggle", {
		device = 'keyboard',
		button = input.KEY.Y,
		type = 'action',
		key = 'timecontrolToggleUI',
	})
end

if not bindingSection:get("TimeControlDecrease") then
	bindingSection:set("TimeControlDecrease", {
		device = 'keyboard',
		button = input.KEY.Comma,
		type = 'action',
		key = 'timecontrolDecrease',
	})
end

if not bindingSection:get("TimeControlMode") then
	bindingSection:set("TimeControlMode", {
		device = 'keyboard',
		button = input.KEY.Period,
		type = 'action',
		key = 'timecontrolToggleMode',
	})
end

if not bindingSection:get("TimeControlIncrease") then
	bindingSection:set("TimeControlIncrease", {
		device = 'keyboard',
		button = input.KEY.Slash,
		type = 'action',
		key = 'timecontrolIncrease',
	})
end


for _, template in pairs(settingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.playerSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		_G[setting] = settingsSection:get(setting)
		if timeControlUI and timeControlUI.playerWidget then
			if setting == "HUD_X_POS" or setting == "HUD_Y_POS" then
				timeControlUI.updatePosition()
			else
				timeControlUI.rebuildPlayer()
			end
		end	
	end))
end