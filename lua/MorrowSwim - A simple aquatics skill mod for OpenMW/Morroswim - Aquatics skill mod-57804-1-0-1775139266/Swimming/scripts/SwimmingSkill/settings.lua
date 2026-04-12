MODNAME = "Swimming Skill"

local util = require('openmw.util')
local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')

local RENDERER_SLIDER = "SuperSlider3"       -- alt: "number"
local RENDERER_COLOR = "SuperColorPicker2"   -- alt: "color"

local layerId = ui.layers.indexOf("Modal")
local hudSize = ui.layers[layerId].size

local tempKey
local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end

local UI_SETTINGS = {
	BREATH_UI_COLOR = true,
	BREATH_UI_DROWN_COLOR = true,
	BREATH_UI_WIDTH = true,
	BREATH_UI_X_OFFSET = true,
	BREATH_UI_Y_OFFSET = true,
	BREATH_UI_DROWN_PULSE = true,
	BREATH_UI_PULSE_SPEED = true,
	BREATH_UI_BAR_THICKNESS = true,
	BREATH_UI_BG_ALPHA = true,
	BREATH_UI_BORDER_ALPHA = true,
	BREATH_UI_TEXT_SIZE = true,
	BREATH_UI_BAR_BORDER_ALPHA = true,
	BREATH_UI_LOCK = true,
}

local presetColors = {
    "f3ed16", -- FATIGUELAG_COL yellow
    "35459f", -- MAGICKA_COL blue
    "5a0f8c", -- MAGICKALAG_COL purple
	
    "2e9594", -- water color
    "8b0000", -- drowning color
	
-- vanilla colors:
    "caa560", -- fontColor_color_normal
    "d4b77f", -- goldenMix
    "dfc99f", -- FontColor_color_normal_over
    "eee2c9", -- lightText
    "253170", -- fontColor_color_journal_link
    "3a4daf", -- fontColor_color_journal_link_over
    "707ecf", -- fontColor_color_journal_link_pressed
}

local settingsTemplate = {}

tempKey = "General"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "XP_RATE_MULT",
			name = "Leveling Speed",
			description = "Multiplier on XP gains from swimming, diving and dashing\n1.0 = default, 2.0 = twice as fast",
			renderer = RENDERER_SLIDER,
			default = 1.0,
			argument = {
				min = 0,
				max = 5,
				step = 0.1,
				default = 1.0,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Slow",
				maxLabel = "Fast",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "x",
			},
		},
		{
			key = "DEBUG_MESSAGES",
			name = "Enable debug messages",
			description = "Print debug messages to the console\nUseful for troubleshooting issues with the mod",
			renderer = "checkbox",
			default = false,
		},
	},
}

tempKey = "Speed Bonus"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "SPEED_BONUS_ENABLED",
			name = "Enable swim speed bonus",
			description = "Grants a Speed attribute bonus while swimming based on skill level",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "SPEED_BONUS_MULT",
			name = "Speed bonus multiplier",
			description = "Multiplied by skill level to determine the Speed bonus\n1.0 = full skill level as bonus (e.g. +50 at skill 50)",
			renderer = RENDERER_SLIDER,
			default = 1.0,
			argument = {
				min = 0,
				max = 5.0,
				step = 0.1,
				default = 1.0,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "None",
				maxLabel = "5x",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "x",
			},
		},
	},
}

tempKey = "Dash"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "DASH_ENABLED",
			name = "Enable underwater dash",
			description = "Gain a speed boost when pressing a specific key\n(On cost of fatigue and oxygen)",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "DASH_ON_JUMP",
			name = "Dash on jump",
			description = "Pressing jump while swimming triggers a dash",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "ENABLE_DASH_KEYBINDING",
			name = "Enable dash hotkey",
			description = "Enable the hotkey below",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "HOTKEY_DASH",
			name = "Choose a hotkey for dashing",
			description = "Click and press a key\nThis is in addition to the jump key",
			renderer = "inputBinding",
			default = "",
			argument = { type = "action", key = "swimmingSkillDashTrigger" },
		},
		{
			key = "DASH_SPEED_BASE",
			name = "Dash speed (base)",
			description = "Speed bonus at skill level 0",
			renderer = RENDERER_SLIDER,
			default = 200,
			argument = {
				min = 0,
				max = 1000,
				step = 10,
				default = 200,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "None",
				maxLabel = "Fast",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "pts",
			},
		},
		{
			key = "DASH_SPEED_PER_LEVEL",
			name = "Dash speed per level",
			description = "Additional speed per skill level",
			renderer = RENDERER_SLIDER,
			default = 12,
			argument = {
				min = 0,
				max = 50,
				step = 1,
				default = 12,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "None",
				maxLabel = "High",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "pts/lvl",
			},
		},
		{
			key = "DASH_DURATION_BASE",
			name = "Dash duration (base)",
			description = "Duration in seconds at skill level 0",
			renderer = RENDERER_SLIDER,
			default = 0.5,
			argument = {
				min = 0.1,
				max = 5.0,
				step = 0.1,
				default = 0.5,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Short",
				maxLabel = "Long",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "s",
			},
		},
		{
			key = "DASH_DURATION_PER_LEVEL",
			name = "Dash duration per level",
			description = "Additional seconds per skill level",
			renderer = RENDERER_SLIDER,
			default = 0.005,
			argument = {
				min = 0,
				max = 0.1,
				step = 0.001,
				default = 0.005,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "None",
				maxLabel = "High",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "s/lvl",
			},
		},
		{
			key = "DASH_FATIGUE_BASE",
			name = "Fatigue cost (base)",
			description = "Fatigue consumed per dash at skill level 0",
			renderer = RENDERER_SLIDER,
			default = 35,
			argument = {
				min = 0,
				max = 100,
				step = 1,
				default = 35,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Free",
				maxLabel = "Heavy",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "pts",
			},
		},
		{
			key = "DASH_FATIGUE_PER_LEVEL",
			name = "Fatigue cost per level",
			description = "Fatigue cost reduction per skill level (negative = cheaper at higher skill)",
			renderer = RENDERER_SLIDER,
			default = -0.25,
			argument = {
				min = -1,
				max = 0,
				step = 0.05,
				default = -0.25,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Cheaper",
				maxLabel = "None",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "pts/lvl",
			},
		},
		{
			key = "DASH_BREATH_COST",
			name = "Dash breath cost (seconds)",
			description = "Seconds of breath consumed per underwater dash\n0 = dashing doesn't drain breath",
			renderer = RENDERER_SLIDER,
			default = 1,
			argument = {
				min = 0,
				max = 5,
				step = 0.5,
				default = 1,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "None",
				maxLabel = "Heavy",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "s",
			},
		},
	},
}

tempKey = "Water Breathing"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "NOSE_HEIGHT_MULT",
			name = "Character height multiplier",
			description = "Controls where the 'nose level' sits relative to race height\nHigher = you can breathe in shallower water",
			renderer = RENDERER_SLIDER,
			default = 132.75,
			argument = {
				min = 50,
				max = 175,
				step = 0.25,
				default = 132.75,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Low",
				maxLabel = "High",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = " units",
			},
		},
		{
			key = "BREATH_DURATION_BASE",
			name = "Breath duration (base)",
			description = "Seconds of underwater breath at skill level 0",
			renderer = RENDERER_SLIDER,
			default = 8,
			argument = {
				min = 1,
				max = 60,
				step = 1,
				default = 8,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Short",
				maxLabel = "Long",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "s",
			},
		},
		{
			key = "BREATH_DURATION_PER_LEVEL",
			name = "Breath duration per level",
			description = "Additional seconds per skill level",
			renderer = RENDERER_SLIDER,
			default = 0.45,
			argument = {
				min = 0,
				max = 3.0,
				step = 0.05,
				default = 0.45,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "None",
				maxLabel = "High",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "s/lvl",
			},
		},
		{
			key = "BREATH_RECHARGE_DURATION",
			name = "Breath recharge time (seconds)",
			description = "How long it takes to fully recover breath after surfacing",
			renderer = RENDERER_SLIDER,
			default = 3,
			argument = {
				min = 0,
				max = 15,
				step = 0.5,
				default = 3,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Instant",
				maxLabel = "Slow",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "s",
			},
		},
		{
			key = "DROWN_DAMAGE_PERCENT",
			name = "Drowning damage (% of max HP/sec)",
			description = "Extra Health lost per second while drowning, as a percentage of max health\n(on top of vanilla damage)",
			renderer = RENDERER_SLIDER,
			default = 1.0,
			argument = {
				min = 0,
				max = 25,
				step = 0.1,
				default = 1.0,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Gentle",
				maxLabel = "Deadly",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "%/s",
			},
		},
		{
			key = "USE_MODIFY_EFFECT",
			name = "Use effect modifier instead of spell",
			description = "Uses activeEffects:modify instead of adding a spell\nIs slightly more invasive but avoids showing a water breathing icon in your spell list\nMake sure to also enable the setting below",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "VERIFY_WATERBREATHING",
			name = "Verify water breathing on load",
			description = "When loading a save, scans active spells to verify the water breathing magnitude is correct and fixes it if not",
			renderer = "checkbox",
			default = false,
		},
	},
}

tempKey = "Combat"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "COMBAT_MOD_ENABLED",
			name = "Enable underwater combat modifiers",
			description = "Skill level affects weapon skills while swimming\nLow skill = penalty, high skill = bonus",
			renderer = "checkbox",
			default = true,
		},
	},
}

tempKey = "Sound"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "SWIMMING_SFX_VOLUME",
			name = "Swimming sound volume",
			description = "Volume of all swimming and dash sounds\n0% = silent\nValues above 100% only have an effect when your effects volume x total volume is below 100%\nChange this setting to preview each sound",
			renderer = RENDERER_SLIDER,
			default = 100,
			argument = {
				min = 0,
				max = 800,
				step = 10,
				default = 100,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Silent",
				maxLabel = "Loud",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "%",
			},
		},
	},
}

tempKey = "Breath Bar UI"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                             ",
	description = "You can use the mouse to drag the bar around and use the mousewheel and shift+mousewheel while doing so",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "BREATH_UI_LOCK",
			name = "Lock UI",
			description = "Prevents you from accidentally dragging the breathing bar",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "BREATH_UI_COLOR",
			name = "Bar color",
			description = "Color of the breath bar fill",
			renderer = RENDERER_COLOR,
			default = util.color.hex("2e9594"),
			argument = {presetColors = presetColors},
		},
		{
			key = "BREATH_UI_DROWN_COLOR",
			name = "Drowning color",
			description = "Color of the bar when drowning",
			renderer = RENDERER_COLOR,
			default = util.color.hex("8b0000"),
			argument = {presetColors = presetColors},
		},
		{
			key = "BREATH_UI_WIDTH",
			name = "Bar width",
			description = "Width of the breath bar in pixels",
			renderer = RENDERER_SLIDER,
			default = 180,
			argument = {
				min = 50,
				max = hudSize.x,
				step = 1,
				default = 180,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Narrow",
				maxLabel = "Wide",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "px",
			},
		},
		{
			key = "BREATH_UI_Y_OFFSET",
			name = "Bar vertical offset",
			description = "Distance from the top of the screen in pixels",
			renderer = RENDERER_SLIDER,
			default = 36,
			argument = {
				min = 0,
				max = hudSize.y,
				step = 1,
				default = 36,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Top",
				maxLabel = "Bottom",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "px",
			},
		},
		{
			key = "BREATH_UI_X_OFFSET",
			name = "Bar horizontal offset",
			description = "Horizontal offset from center in pixels\nNegative = left, positive = right",
			renderer = RENDERER_SLIDER,
			default = 0,
			argument = {
				min = -math.floor(hudSize.x/2),
				max = math.floor(hudSize.x/2),
				step = 1,
				default = 0,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Left",
				maxLabel = "Right",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "px",
			},
		},
		{
			key = "BREATH_UI_DROWN_PULSE",
			name = "Drowning pulse effect",
			description = "Bar pulses when drowning",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "BREATH_UI_PULSE_SPEED",
			name = "Pulse speed",
			description = "How fast the bar pulses when drowning",
			renderer = RENDERER_SLIDER,
			default = 4.0,
			argument = {
				min = 0.1,
				max = 20,
				step = 0.1,
				default = 4.0,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Slow",
				maxLabel = "Fast",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "/s",
			},
		},
		{
			key = "BREATH_UI_BAR_THICKNESS",
			name = "Bar thickness",
			description = "Height of the breath bar in pixels",
			renderer = RENDERER_SLIDER,
			default = 14,
			argument = {
				min = 2,
				max = 50,
				step = 1,
				default = 14,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Thin",
				maxLabel = "Thick",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "px",
			},
		},
		{
			key = "BREATH_UI_BG_ALPHA",
			name = "Background opacity",
			description = "Opacity of the bar background\n0% = fully transparent, 100% = fully opaque",
			renderer = RENDERER_SLIDER,
			default = 50,
			argument = {
				min = 0,
				max = 100,
				step = 5,
				default = 50,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Hidden",
				maxLabel = "Opaque",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "%",
			},
		},
		{
			key = "BREATH_UI_BORDER_ALPHA",
			name = "Border opacity",
			description = "Opacity of the border decoration\n0% = fully transparent, 100% = fully opaque",
			renderer = RENDERER_SLIDER,
			default = 100,
			argument = {
				min = 0,
				max = 100,
				step = 5,
				default = 100,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Hidden",
				maxLabel = "Opaque",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "%",
			},
		},
		{
			key = "BREATH_UI_TEXT_SIZE",
			name = "Text size",
			description = "Font size of the breath label",
			renderer = RENDERER_SLIDER,
			default = 16,
			argument = {
				min = 0,
				max = 36,
				step = 1,
				default = 16,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Small",
				maxLabel = "Large",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "px",
			},
		},
		{
			key = "BREATH_UI_BAR_BORDER_ALPHA",
			name = "Bar border opacity",
			description = "Opacity of the thin border around the breath bar\n0% = fully transparent, 100% = fully opaque",
			renderer = RENDERER_SLIDER,
			default = 100,
			argument = {
				min = 0,
				max = 100,
				step = 5,
				default = 100,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Hidden",
				maxLabel = "Opaque",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "%",
			},
		},
	},
}


for id, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end
I.Settings.registerPage {
	key = MODNAME,
	l10n = "none",
	name = "Swimming Skill",
	description = "Configure the Swimming skill mod — dash, breath, combat, UI, and more"
}


function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for i, entry in pairs(template.settings) do
			local newValue = settingsSection:get(entry.key)
			if newValue == nil then
				newValue = entry.default
			end
			_G[entry.key] = newValue
		end
	end
end

readAllSettings()

-- ────────────────────────────────────────────────────────────────────────── Settings Event ──────────────────────────────────────────────────────────────────────────
for _, template in pairs(settingsTemplate) do
	local settingsSection = storage.playerSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		local oldValue = _G[setting]
		_G[setting] = settingsSection:get(setting)
		if UI_SETTINGS[setting] and not (breathElement and breathElement.layout.userData.isDragging) then
			BREATH_UI_PREVIEW_TIMER = 3
			BREATH_UI_PREVIEW_DROWN = setting == "BREATH_UI_DROWN_COLOR"
				or setting == "BREATH_UI_DROWN_PULSE"
				or setting == "BREATH_UI_PULSE_SPEED"
			if setting == "BREATH_UI_BG_ALPHA" or setting == "BREATH_UI_BORDER_ALPHA" then
				if cachedBoxTemplate then
					cachedBoxTemplate.content[1].props.alpha = BREATH_UI_BG_ALPHA / 100
					for i = 2, #cachedBoxTemplate.content - 1 do
						cachedBoxTemplate.content[i].props.alpha = BREATH_UI_BORDER_ALPHA / 100
					end
				end
			elseif setting == "BREATH_UI_BAR_BORDER_ALPHA" then
				if cachedBarBorders then
					for i = 1, #cachedBarBorders.content - 1 do
						cachedBarBorders.content[i].props.alpha = BREATH_UI_BAR_BORDER_ALPHA / 100
					end
				end
			elseif setting == "BREATH_UI_LOCK" then
				if breathElement then
					breathElement.layout.layer = BREATH_UI_LOCK and "HUD" or "Modal"
					breathElement:update()
				end
			elseif breathElement then
				createBreathUI()
				if BREATH_UI_PREVIEW_DROWN then
					updateBreathUI(0, 0)
				else
					updateBreathUI(1 - (saveData.underwaterTime / getMaxBreathDuration()), 0)
				end
			end
		end
		if setting == "SWIMMING_SFX_VOLUME" then
			local vol = SWIMMING_SFX_VOLUME / 100
			local variation = lastSoundVariation % 6
			lastSoundVariation = lastSoundVariation + 1
			-- underwater dash
			if variation == 0 then
				ambient.playSoundFile("sound/Swimming/218272__alienxxx__swish6 - Copy.wav", {
					volume = 1.1 * vol,
				})
			-- surface dash (blended)
			elseif variation == 1 then
				ambient.playSoundFile("sound/Swimming/218272__alienxxx__swish6 - Copy.wav", {
					volume = 0.85 * vol,
					pitch = 1.6,
				})
				ambient.playSoundFile("sound/Swimming/218273__alienxxx__swish5 - Copy.wav", {
					volume = 0.55 * vol,
					pitch = 1.7,
				})
			-- underwater swim A
			elseif variation == 2 then
				ambient.playSoundFile("sound/Swimming/218273__alienxxx__swish5.wav", {
					volume = 0.85 * vol,
				})
			-- underwater swim B
			elseif variation == 3 then
				ambient.playSoundFile("sound/Swimming/218272__alienxxx__swish6.wav", {
					volume = 0.85 * vol,
					pitch = 0.7,
				})
			-- surface swim A
			elseif variation == 4 then
				ambient.playSoundFile("sound/Swimming/swimLEFT.wav", {
					volume = 0.7 * vol,
				})
			-- surface swim B
			elseif variation == 5 then
				ambient.playSoundFile("sound/Swimming/swimRIGHT.wav", {
					volume = 0.7 * vol,
				})
			end
		end
		if setting == "NOSE_HEIGHT_MULT" then
			noseLevel = nil
		end
		if setting == "USE_MODIFY_EFFECT" then
			saveData.useModifyEffect = _G[setting]
			if oldValue ~= _G[setting] and saveData.waterBreathingActive then
				-- Revoke using old method, onUpdate will re-grant with new method
				if oldValue then
					playerActiveEffects:modify(-1, "waterbreathing")
				else
					playerSpells:remove('swimmingskill_waterbreathing')
				end
				saveData.waterBreathingActive = false
			end
		end
	end))
end