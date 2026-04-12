local G, F, lib = G, F, lib

local RENDERER_SLIDER = "SuperSlider3"
local RENDERER_COLOR  = "SuperColorPicker2"

local layerId = ui.layers.indexOf("HUD")
local hudSize = ui.layers[layerId].size

local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end

local PREVIEW_SETTINGS = {
	BAR_LENGTH = true,
	BAR_LENGTH_PER_CAPACITY = true,
	BAR_THICKNESS = true,
	BAR_X_OFFSET = true,
	BAR_Y_OFFSET = true,
	BAR_LOCK = true,
	BAR_VERTICAL = true,
	BAR_BORDER_THICKNESS = true,
	BAR_SHOW_ICON = true,
	BAR_TEXT_MODE = true,
	BAR_TEXT_POSITION = true,
	BAR_THRESHOLD = true,
	BAR_COLOR_LOW = true,
	BAR_COLOR_MID = true,
	BAR_COLOR_HIGH = true,
	BAR_BG_COLOR = true,
	BAR_TEXT_COLOR = true,
	BAR_FLASH_DURATION = true,
	BAR_FLASH_COLOR = true,
}

local presetColors = {
	-- status gradient colors for the bar
	"44cc44", -- green
	"f3ed16", -- yellow
	"ff6600", -- orange
	"8b0000", -- dark red
	"222222", -- near-black (bg)
	"ffffff", -- white
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
	name = tempKey .. "                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "BAR_ENABLED",
			name = "Enabled",
			description = "Show the bar on the HUD",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "BAR_LENGTH",
			name = "Bar length",
			description = "Bar length",
			renderer = RENDERER_SLIDER,
			default = 120,
			argument = {
				min = 0,
				max = hudSize.x,
				step = 2,
				default = 120,
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
			key = "BAR_LENGTH_PER_CAPACITY",
			name = "Length per capacity",
			description = "Extra pixels added to bar length per point of max encumbrance",
			renderer = RENDERER_SLIDER,
			default = 0,
			argument = {
				min = 0,
				max = 2,
				step = 0.05,
				default = 0,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Off",
				maxLabel = "Large",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "px",
			},
		},
		{
			key = "BAR_THICKNESS",
			name = "Bar thickness",
			description = "Bar thickness. Icon and text scale with this",
			renderer = RENDERER_SLIDER,
			default = 16,
			argument = {
				min = 1,
				max = 80,
				step = 1,
				default = 16,
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
			key = "BAR_VERTICAL",
			name = "Vertical bar",
			description = "Vertical bar with the icon below",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "BAR_BORDER_THICKNESS",
			name = "Border thickness",
			description = "Border around the bar. 0 hides it",
			renderer = RENDERER_SLIDER,
			default = 1,
			argument = {
				min = 0,
				max = 4,
				step = 1,
				default = 1,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "None",
				maxLabel = "Thick",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "px",
			},
		},
		{
			key = "BAR_SHOW_ICON",
			name = "Show icon",
			description = "Show the sack icon next to the bar",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "BAR_TEXT_MODE",
			name = "Text format",
			description = "What to show inside the bar",
			renderer = "select",
			default = "123 / 234",
			argument = {
				l10n = "none",
				items = { "Off", "123", "123/234", "123 / 234" },
			},
		},
		{
			key = "BAR_TEXT_POSITION",
			name = "Text position",
			description = "Where the weight text is placed",
			renderer = "select",
			default = "Center",
			argument = {
				l10n = "none",
				items = { "Left", "Center", "Right", "Right outside" },
			},
		},
		{
			key = "BAR_X_OFFSET",
			name = "Horizontal offset",
			description = "Offset from center",
			renderer = RENDERER_SLIDER,
			default = -76,
			argument = {
				min = -math.floor(hudSize.x / 2),
				max = math.floor(hudSize.x / 2),
				step = 1,
				default = -76,
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
			key = "BAR_Y_OFFSET",
			name = "Vertical offset",
			description = "Offset from the bottom of the screen",
			renderer = RENDERER_SLIDER,
			default = 0,
			argument = {
				min = -hudSize.y,
				max = 8,
				step = 1,
				default = 0,
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
			key = "BAR_LOCK",
			name = "Lock position",
			description = "Unlock to drag. Mousewheel while dragging resizes the bar",
			renderer = "checkbox",
			default = false,
		},
	},
}

tempKey = "Colors"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer' .. MODNAME .. tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey .. "                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "BAR_THRESHOLD",
			name = "Warning threshold",
			description = "When the bar starts turning red",
			renderer = RENDERER_SLIDER,
			default = 75,
			argument = {
				min = 5,
				max = 100.0,
				step = 5,
				default = 75,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Low",
				maxLabel = "High",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "%",
			},
		},
		{
			key = "BAR_COLOR_LOW",
			name = "Low color",
			description = "Color when empty",
			renderer = RENDERER_COLOR,
			default = util.color.hex("caa560"), -- fontColor_color_normal
			argument = { presetColors = presetColors },
		},
		{
			key = "BAR_COLOR_MID",
			name = "Mid color",
			description = "Color at the threshold",
			renderer = RENDERER_COLOR,
			default = util.color.hex("d4b77f"), -- goldenMix
			argument = { presetColors = presetColors },
		},
		{
			key = "BAR_COLOR_HIGH",
			name = "High color",
			description = "Color when fully loaded",
			renderer = RENDERER_COLOR,
			default = util.color.hex("8b0000"), -- dark red
			argument = { presetColors = presetColors },
		},
		{
			key = "BAR_BG_COLOR",
			name = "Background color",
			description = "Empty bar color",
			renderer = RENDERER_COLOR,
			default = util.color.hex("070707"),
			argument = { presetColors = presetColors },
		},
		{
			key = "BAR_TEXT_COLOR",
			name = "Text color",
			description = "Text color",
			renderer = RENDERER_COLOR,
			default = util.color.hex("eee2c9"),
			argument = { presetColors = presetColors },
		},
		{
			key = "BAR_FLASH_COLOR",
			name = "Flash color",
			description = "Color flashed on weight change",
			renderer = RENDERER_COLOR,
			default = util.color.hex("eee2c9"),
			argument = { presetColors = presetColors },
		},
		{
			key = "BAR_FLASH_DURATION",
			name = "Flash duration",
			description = "Flash duration on weight change. 0 = off.",
			renderer = RENDERER_SLIDER,
			default = 0.35,
			argument = {
				min = 0,
				max = 1.5,
				step = 0.05,
				default = 0.35,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Fast",
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
	name = "Encumbrance Bar",
	description = "",
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
			if newValue == nil then newValue = entry.default end
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
		if F.rebuildBar and PREVIEW_SETTINGS[setting] then
			F.rebuildBar()
		end
	end))
end