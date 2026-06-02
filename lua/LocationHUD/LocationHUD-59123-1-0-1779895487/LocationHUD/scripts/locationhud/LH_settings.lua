local I = require('openmw.interfaces')
local layerId = ui.layers.indexOf("HUD")
local hudLayerSize = ui.layers[layerId].size
local util = require('openmw.util')

-- parse "r g b" GMST into a util.color, fall back to white
local TextColor
do
	local result = core.getGMST("FontColor_color_normal")
	local rgb = {}
	if result then
		for color in string.gmatch(result, '(%d+)') do
			table.insert(rgb, tonumber(color))
		end
	end
	if #rgb == 3 then
		TextColor = util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
	else
		TextColor = util.color.rgb(1, 1, 1)
	end
end

L = require('scripts.locationhud.LH_locale')

local tempKey
local settingsTemplate = {}
local presetColors = {
	"d4edfc", -- thirst
	"bfd4bc", -- hunger
	"cfbddb", -- sleep
	"81cded", -- fav color of blue
	"caa560", -- fontColor_color_normal
	"d4b77f", -- goldenMix
	"dfc99f", -- FontColor_color_normal_over
	"eee2c9", -- lightText
	"253170", -- fontColor_color_journal_link
	"3a4daf", -- fontColor_color_journal_link_over
	"707ecf", -- fontColor_color_journal_link_pressed
}

tempKey = "General"
settingsTemplate[tempKey] = {
	key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = L("settings.general", "General").."                                          ", -- lol
	permanentStorage = true,
	order = 1,
	settings = {
		{
			key = "LANGUAGE",
			name = L("settings.language", "Language"),
			description = L("settings.language.desc", "Select the display language. Settings menu labels will update after restarting"),
			default = "English",
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "English", "German", "French", "Russian", "Polish", "Hungarian", "Spanish", "Italian", "Czech", "Portuguese", "Romanian", "Japanese", "ChineseSimplified" },
			},
		},
		{
			key = "HUD_DISPLAY",
			name = L("settings.hud.display", "HUD Display"),
			description = L("settings.hud.display.desc", "When to display the HUD/widget element. Interface = when menus are pulled up"),
			default = "Always",
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Always", "Interface Only", "Hide on Interface", "Hide on Dialogue Only", "Never" },
			},
		},
		{
			key = "HUD_LOCK",
			name = L("settings.lock", "Lock Position"),
			description = "",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "HUD_X_POS",
			name = L("settings.pos.x", "X Position"),
			description = "",
			renderer = "number",
			integer = true,
			default = math.floor(hudLayerSize.x),
		},
		{
			key = "HUD_Y_POS",
			name = L("settings.pos.y", "Y Position"),
			description = "",
			renderer = "number",
			integer = true,
			default = math.floor(hudLayerSize.y - 100),
		},
		{
			key = "HUD_EXTERIOR",
			name = L("settings.exterior", "Only display when you're outside"),
			description = "",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "HOLD_DURATION",
			name = L("settings.hold.duration", "Display Duration"),
			description = L("settings.hold.duration.desc", "How long before the text begins to fade.\nDefault (vanilla) is 4.6"),
			renderer = "number",
			default = 4.6,
			argument = { min = 0, max = 60, },
		},
		{
			key = "FADE_DURATION",
			name = L("settings.fade.duration", "Fade Duration"),
			description = L("settings.fade.duration.desc", "Seconds the text is faded out.\nDefault is 1"),
			renderer = "number",
			default = 1,
			argument = { min = 0, max = 60, },
		},
	},
}

tempKey = "Appearance"
settingsTemplate[tempKey] = {
	key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = L("settings.appearance", "Appearance").."                                          ", -- lol
	permanentStorage = true,
	order = 2,
	settings = {
		{
			key = "FONT_SIZE",
			name = L("settings.font.size", "Font Size"),
			description = L("settings.font.size.desc", "Increase or decrease font size.\nDefault is 23"),
			renderer = "number",
			default = 23,
			argument = { min = 5, max = 100000, },
		},
		{
			key = "TEXT_COLOR",
			name = L("settings.text.color", "Text Color"),
			description = L("settings.text.color.desc", "Change the color of the text."),
			disabled = false,
			renderer = "SuperColorPicker2",
			default = util.color.hex(TextColor:asHex()),
			argument = {presetColors = presetColors},
		},
		{
			key = "BACKGROUND_ALPHA",
			name = L("settings.bg.opacity", "Background Opacity"),
			description = L("settings.bg.opacity.desc", "Increase or decrease background opacity.\n0-1, default is 0.5"),
			renderer = "number",
			default = 0.5,
			argument = { min = 0, max = 1, },
		},
		{
			key = "TEXT_ALIGNMENT",
			name = L("settings.text.align", "Text Alignment"),
			description = L("settings.text.align.desc", "Align the text.\nDefault is right"),
			renderer = "select",
			default = "Right",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Left", "Center", "Right" }
			},
		},
	},
}

tempKey = "Border"
settingsTemplate[tempKey] = {
	key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = L("settings.border.section", "Border").."                                              ", -- lol
	permanentStorage = true,
	order = 3,
	settings = {
		{
			key = "HUD_BORDER",
			name = L("settings.border", "Border"),
			renderer = "checkbox",
			default = false,
		},
		{
			key = "HUD_BORDER_STYLE",
			name = L("settings.border.style", "Border Style"),
			description = L("settings.border.style.desc", "Changes the texture and the pixel size.\n\nSame styles as Quickloot"),
			renderer = "select",
			default = "thin",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "thin", "normal", "thick", "verythick" }
			},
		},
		{
			key = "HUD_BORDER_COLOR",
			name = L("settings.border.color", "Border Color"),
			description = "",
			renderer = "SuperColorPicker2",
			default = util.color.hex("FFFFFF"),
			argument = {presetColors = presetColors},
		},
		{
			key = "HUD_PADDING",
			name = L("settings.padding", "Padding"),
			description = L("settings.padding.desc", "Inner spacing around the text in pixels. Applied to both x and y.\nDefault is 4"),
			renderer = "number",
			integer = true,
			default = 4,
			argument = { min = 0, max = 50, },
		},
	},
}

for id, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

I.Settings.registerPage {
	key = MODNAME,
	l10n = "none",
	name = L("mod.name", "LocationHUD"),
	description = L("mod.desc", "Displays your location when entering a new area.\n- Click and drag to move the position.\n- Click and mousewheel to change size.\n- Click and Shift+mousewheel to change bg opacity while in-game.")
}

-- read current values into globals
for _, template in pairs(settingsTemplate) do
	local settingsSection = storage.playerSection(template.key)
	for i, entry in pairs(template.settings) do
		local val = settingsSection:get(entry.key)
		if val == nil then
			val = entry.default
		end
		_G[entry.key] = val
	end
end
for _, template in pairs(settingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.playerSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		local oldValue = _G[setting]
		_G[setting] = settingsSection:get(setting)

		if setting == "LANGUAGE" and locationHud then
			if updateLocationDisplay then
				updateLocationDisplay(true)
			end
			return
		end

		if setting == "HUD_BORDER" or setting == "HUD_BORDER_STYLE" or setting == "HUD_BORDER_COLOR" or setting == "HUD_PADDING" then
			if createLocationHud then
				createLocationHud()
			end
			return
		end

		if locationHud then
			-- change layer for lock state
			locationHud.layout.layer = HUD_LOCK and 'Scene' or 'Modal'
			locationHudBackground.props.alpha = BACKGROUND_ALPHA
			locationText.props.textSize = FONT_SIZE

			if setting == "TEXT_ALIGNMENT" then
				if TEXT_ALIGNMENT == "Left" then
					locationHud.layout.props.anchor = v2(0, 0)
				elseif TEXT_ALIGNMENT == "Center" then
					locationHud.layout.props.anchor = v2(0.5, 0)
				elseif TEXT_ALIGNMENT == "Right" then
					locationHud.layout.props.anchor = v2(1, 0)
				end
			end

			if setting == "HUD_X_POS" or setting == "HUD_Y_POS" then
				locationHud.layout.props.position = v2(HUD_X_POS, HUD_Y_POS)
			end

			if updateLocationDisplay then -- if function is available (mod already initialized)
				updateLocationDisplay(true)
			end

			if UiModeChanged then  -- if function is available (mod already initialized)
				data = {
					newMode = I.UI.getMode(),
				}
				UiModeChanged(data) -- calls locationHud:update()
			end
		end
	end))
end
