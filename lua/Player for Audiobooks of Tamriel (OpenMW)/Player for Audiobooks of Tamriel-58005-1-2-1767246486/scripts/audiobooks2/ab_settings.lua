local I 			= require('openmw.interfaces')
local hudLayerSize 	= getHudLayerSize()
--local screenres 	= ui.screenSize()
--local uiScale 		= screenres.x / hudLayerSize.x
local util 			= require('openmw.util')
local input 		= require('openmw.input')
local TextColor   	= getColorFromGameSettings("FontColor_color_normal")

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
	name = tempKey.."                                                        ", -- lol
	permanentStorage = true,
	order = getOrder(),
	settings = {
        {
            key = "HOTKEY_AUDIOBOOKS2_PLAY",
            renderer = "inputBinding",
            name = "[Play/Pause] Choose a hotkey for playing an audiobook", 
			-- if UI mode is not book and file is playing, pressing this key will pause (same action as pressing pause button)
            description = "Click and press a key",
            default = "AudioPlay",
            argument = { type = "action", key = "audiobooks2PlayTrigger" },
        },
        {
            key = "HOTKEY_AUDIOBOOKS2_STOP",
            name = "[Stop/Rewind] Choose a hotkey to stop/rewind an audiobook",
            description = "Click and press a key",
            renderer = "inputBinding",
            default = "AudioPrev",
            argument = { type = "action", key = "audiobooks2StopTrigger" },
        },
        {
            key = "HOTKEY_AUDIOBOOKS2_NEXT",
            name = "[Next] Choose a hotkey to play the queued audiobook",
            description = "Click and press a key",
            renderer = "inputBinding",
            default = "AudioNext",
            argument = { type = "action", key = "audiobooks2NextTrigger" },
        },
		{
			key = "REWIND_STOPS",
			name = "Rewind stops the audiobook",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "PLAYER_VOLUME",
			name = "Volume",
			description = "in % (0-100)",
			renderer = "number",
			default = 100,
			argument = { min = 0, max = 100, },
		},
		{
			key = "AUTOPLAY",
			name = "Autoplay",
			description = "Automatically start playing when opening a book with an audiobook",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "QUEUE_BOOKS",
			name = "Automatically queue books",
			description = "Queued book can be cleared with a rightclick on 'Next'\nCan also press 'Next' to queue the book on the screen (via keybind or ui button)",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "AUTO_PLAY_NEXT",
			name = "Auto-play queued book",
			description = "Automatically play the queued book when the current one finishes",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "AUTO_CLOSE_THRESHOLD",
			name = "Auto-close threshold (seconds)",
			description = "Close the player when closing the book if played for less than this many seconds. 0 = disabled.",
			renderer = "number",
			default = 0,
			argument = { min = 0, max = 3600, },
		},
	}
}

tempKey = "UI Settings"
settingsTemplate[tempKey] = {
	key = "Settings"..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",                                                          --
	name = tempKey.."			     									", -- lol
	permanentStorage = true,
	order = getOrder(),
	settings = {
		--{
		--	key = "HUD_DISPLAY",
		--	name = "HUD Display",
		--	description = "When to display the Audiobook UI. Interface = when menus are pulled up",
		--	default = "Always", 
		--	renderer = "select",
		--	argument = {
		--		disabled = false,
		--		l10n = "none", 
		--		items = { "Always", "Interface Only", "Hide on Interface", "Hide on Dialogue Only", "Never" },
		--	},
		--},
		-- set default position to middle of screen below book UI/message boxes maybe ? idk
		{
			key = "SHOW_TITLE",
			name = "Show title",
			description = "Where to display the audiobook title",
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
			description = "Change the color of the currently playing Book name.\nDefaults are typically: caa560 ; dfc99f", -- \nBlue: 81CDED (blue)
			disabled = false,
			renderer = "SuperColorPicker2",
			default = util.color.hex(TextColor:asHex()),
			argument = { presetColors = presetColors },
		},
		{
			key = "TEXT_SIZE",
			name = "Text Size",
			description = "Change the text size of the currently playing Book name.\nDefault is 14",
			renderer = "number",
			default = 14,
			argument = { min = 0, max = 100000, },
		},
		{
			key = "PLAYER_WIDTH",
			name = "Player width",
			description = "Default is 210",
			renderer = "number",
			default = 210,
			argument = { min = 0, max = 100000, },
		},
		{
			key = "PLAYER_HEIGHT",
			name = "Player height",
			description = "Default is 55",
			renderer = "number",
			default = 55,
			argument = { min = 0, max = 100000, },
		},
		{
			key = "THEME_COLOR",
			name = "Theme Color",
			description = "Change the color of the borders and the buttons.\nDefaults are typically: caa560 ; dfc99f", -- \nBlue: 81CDED (blue)
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
--[[	{ 
			key = "TEXT_ALIGNMENT",
			name = "Text Alignment",
			description = "Align the time and date.\nDefault is left",
			renderer = "select",
			default = "Left",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Left", "Center", "Right" }
				},
		}, ]]
	},	
}

for id, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

I.Settings.registerPage {
	key = MODNAME,
	l10n = "none",
	name = "Audiobooks of Tamriel",
	description = "Audiobook player\nBy OwnlyMe"
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


-- called on init and when settings change
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

if not bindingSection:get("AudioPlay") then
	bindingSection:set("AudioPlay", {
		device = 'keyboard',
		button = 261,  -- AudioPlay Media key
		type = 'action',
		key = 'audiobooks2PlayTrigger',
	})
end

if not bindingSection:get("AudioPrev") then
	bindingSection:set("AudioPrev", {
		device = 'keyboard',
		button = 259,  -- AudioPrev Media key
		type = 'action',
		key = 'audiobooks2StopTrigger',
	})
end

if not bindingSection:get("AudioNext") then
	bindingSection:set("AudioNext", {
		device = 'keyboard',
		button = 258,  -- AudioNext Media key
		type = 'action',
		key = 'audiobooks2NextTrigger',
	})
end

for _, template in pairs(settingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.playerSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		_G[setting] = settingsSection:get(setting)
		if audiobookPlayer and audiobookPlayer.playerWidget then
			if setting == "HUD_X_POS" or setting == "HUD_Y_POS" then
				audiobookPlayer.updatePosition()
			elseif setting ~= "PLAYER_VOLUME" then
				audiobookPlayer.rebuildPlayer()
			end
		end	
	end))
end

--setSetting("HOTKEY_AUDIOBOOKS2_PLAY", "X")
--print(HOTKEY_AUDIOBOOKS2_PLAY)