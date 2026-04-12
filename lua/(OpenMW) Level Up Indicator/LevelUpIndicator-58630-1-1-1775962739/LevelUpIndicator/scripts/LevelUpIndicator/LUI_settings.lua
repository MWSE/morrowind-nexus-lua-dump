local G, F, lib = G, F, lib

local RENDERER_SLIDER = "SuperSlider3"       -- alt: "number"
local RENDERER_COLOR = "SuperColorPicker2"   -- alt: "color"

local layerId = ui.layers.indexOf("Modal")
local hudSize = ui.layers[layerId].size -- layer id and hud size might change when player resizes the window (very rare, so negligible)

local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end

local PREVIEW_SETTINGS = {
	ARROW_LOCK = true,
	ARROW_SIZE = true,
	ARROW_COLOR = true,
	ARROW_X_OFFSET = true,
	ARROW_Y_OFFSET = true,
	ARROW_FADE_IN = true,
	ARROW_HOLD = true,
	ARROW_FADE_OUT = true,
	ARROW_VARIATION = true,
	ARROW_GRAYSCALE = true,
	ARROW_PULSES = true,
}

local FADE_SETTINGS = {
	ARROW_FADE_IN = true,
	ARROW_HOLD = true,
	ARROW_FADE_OUT = true,
	ARROW_PULSES = true,
}

local presetColors = {
	-- standard colors:
    "caa560", -- fontColor_color_normal
    "d4b77f", -- goldenMix
    "dfc99f", -- FontColor_color_normal_over
    "eee2c9", -- lightText
    "253170", -- fontColor_color_journal_link
    "3a4daf", -- fontColor_color_journal_link_over
    "707ecf", -- fontColor_color_journal_link_pressed
}

local settingsTemplate = {}

local tempKey = "General"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer' .. MODNAME .. tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey .. "                                             ", -- fix: forces certain column width in the settings
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "ARROW_ENABLED",
			name = "Enabled",
			description = "Show an arrow indicator when you can level up after a skill increase",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "ARROW_SIZE",
			name = "Arrow size",
			description = "Width and height of the arrow in pixels",
			renderer = RENDERER_SLIDER,
			default = 40,
			argument = {
				min = 12,
				max = 128,
				step = 1,
				default = 40,
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
			key = "ARROW_VARIATION",
			name = "Arrow variation",
			description = "Lets you choose among a variety of arrows",
			renderer = RENDERER_SLIDER,
			default = 1,
			argument = {
				min = 1,
				max = 11,
				step = 1,
				default = 1,
				width = 150,
				thickness = 15,
			},
		},
		{
			key = "ARROW_GRAYSCALE",
			name = "Grayscale arrow",
			description = "Use a grayscale variation of the arrow for better tinting support",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "ARROW_COLOR",
			name = "Arrow tint",
			description = "Tint applied to the arrow",
			renderer = RENDERER_COLOR,
			default = util.color.hex("dfc99f"), -- FontColor_color_normal_over
			argument = { presetColors = presetColors },
		},
		{
			key = "ARROW_X_OFFSET",
			name = "Horizontal offset",
			description = "Horizontal offset from center in pixels\nNegative = left, positive = right",
			renderer = RENDERER_SLIDER,
			default = 0,
			argument = {
				min = -math.floor(hudSize.x / 2),
				max = math.floor(hudSize.x / 2),
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
			key = "ARROW_Y_OFFSET",
			name = "Vertical offset",
			description = "Distance from the bottom of the screen in pixels",
			renderer = RENDERER_SLIDER,
			default = -5,
			argument = {
				min = -hudSize.y,
				max = 8,
				step = 1,
				default = -5,
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
			key = "ARROW_LOCK",
			name = "Lock position",
			description = "Unlock to enable drag and drop.\nYou can use the mousewheel when dragging.",
			renderer = "checkbox",
			default = true,
		},
	},
}

tempKey = "Animation"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer' .. MODNAME .. tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey .. "                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "ARROW_FADE_IN",
			name = "Fade in duration",
			description = "How long the arrow takes to appear",
			renderer = RENDERER_SLIDER,
			default = 0.5,
			argument = {
				min = 0.05,
				max = 3.0,
				step = 0.05,
				default = 0.5,
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
			key = "ARROW_HOLD",
			name = "Hold duration",
			description = "How long the arrow stays fully visible or pulses",
			renderer = RENDERER_SLIDER,
			default = 4.7,
			argument = {
				min = 0.1,
				max = 7.0,
				step = 0.1,
				default = 4.7,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Brief",
				maxLabel = "Long",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "s",
			},
		},
		{
			key = "ARROW_PULSES",
			name = "Pulse count",
			description = "How many times the arrow pulses during the hold duration\n0 = disables pulsing",
			renderer = RENDERER_SLIDER,
			default = 3,
			argument = {
				min = 0,
				max = 10,
				step = 1,
				default = 3,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Off",
				maxLabel = "Many",
				width = 150,
				thickness = 15,
				bottomRow = true,
			},
		},
		{
			key = "ARROW_FADE_OUT",
			name = "Fade out duration",
			description = "How long the arrow takes to disappear",
			renderer = RENDERER_SLIDER,
			default = 0.7,
			argument = {
				min = 0.05,
				max = 5.0,
				step = 0.05,
				default = 0.7,
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
	},
}

I.Settings.registerPage {
	key = MODNAME,
	l10n = "none",
	name = "Level Up Indicator",
	description = "Shows an arrow when a skill levels up and you can level up your character",
}
for _, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

-- read all settings into the S table
local function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for _, entry in pairs(template.settings) do
			local newValue = settingsSection:get(entry.key)
			if newValue == nil then
				newValue = entry.default
			end
			S[entry.key] = newValue
		end
	end
end

readAllSettings()

-- setting changes
for _, template in pairs(settingsTemplate) do
	local settingsSection = storage.playerSection(template.key)
	settingsSection:subscribe(async:callback(function(_, setting)
		S[setting] = settingsSection:get(setting)
		
		
		-- live preview AFTER mod was initialized (F.showArrow was declared)
		if F.showArrow then
			if PREVIEW_SETTINGS[setting] then
				local notifyMsg = core.getGMST('sNotifyMessage39')
				if notifyMsg and notifyMsg ~= "" then
					local skillRecords = core.stats.Skill.records
					local randomSkill = skillRecords[math.random(#skillRecords)]
					local skillStat = types.Player.stats.skills[randomSkill.id](self)
					ui.showMessage(string.format(notifyMsg, randomSkill.name, skillStat.base))
					
					-- flushing 2/3 of the ui messages
					ui.showMessage("")
					ui.showMessage("")
				end
				if FADE_SETTINGS[setting] then
					G.arrowTimer = 0
				end
				F.showArrow()
			end
		end
	end))
end