local I = require('openmw.interfaces')
local layerId = ui.layers.indexOf("HUD")
local hudLayerSize = ui.layers[layerId].size
local screenres = ui.screenSize()
local uiScale = screenres.x / hudLayerSize.x
local util = require('openmw.util')
local TextColor   = getColorFromGameSettings("FontColor_color_normal")

-- Load localization
L = require('scripts.timehud.TH_locale')



local tempKey
local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end

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

tempKey = "Time and Date"
settingsTemplate[tempKey] = {
    key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = L("settings.timedate", "Time and Date").."                                             ", -- lol
	permanentStorage = true,
	order = getOrder(),
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
			default = 12,
		},		
		{
			key = "HUD_Y_POS",
			name = L("settings.pos.y", "Y Position"),
			description = "",
			renderer = "number",
			integer = true,
			default = math.floor(hudLayerSize.y-(105)),
		},			
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
			description = L("settings.text.color.desc", "Change the color of the text.\nDefaults are typically: caa560 ; dfc99f\nBlue: 81CDED (blue)"),
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
			key = "CLOCK_INTERVAL",
			name = L("settings.clock.interval", "Clock Interval"),
			description = L("settings.clock.interval.desc", "Update the clock every x minutes in-game.\nDefault is 15"),
			renderer = "number",
			integer = true,
			default = 15,
			argument = { min = 1, max = 60, },
		},
		{
			key = "SHOW_DATE",
			name = L("settings.date.show", "Show Date"),
			description = L("settings.date.show.desc", "Different formats for displaying the date."),
			default = "Morndas, 20. Heartfire", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Off", "Morndas", "Morndas, 20.", "Heartfire", "Morndas, Heartfire", "Morndas, 20. Heartfire", "Morndas, 20.9.427" }
			},
		},
		{
			key = "DATE_ON_TOP",
			name = L("settings.date.top", "Date On Top"),
			description = "",
			renderer = "checkbox",
			default = false,
		},		
		{ 
			key = "TEXT_ALIGNMENT",
			name = L("settings.text.align", "Text Alignment"),
			description = L("settings.text.align.desc", "Align the time and date.\nDefault is left"),
			renderer = "select",
			default = "Left",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Left", "Center", "Right" }
				},
		},
		{
			key = "CLOCK_FORMAT",
			name = L("settings.time.format", "Time Format"),
			description = "",
			renderer = "select",
			default = "Normal",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Normal", "12", "Text" }
				},
		},
		{
			key = "HUD_EXTERIOR",
			name = L("settings.exterior", "Only display the time when you're outside"),
			description = "",
			renderer = "checkbox",
			default = false,
		},
	},
}

tempKey = "   " --- idk if key can have space
settingsTemplate[tempKey] = {
    key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = L("settings.sunsdusk", "Sun's Dusk Enjoyers").."                                             ", -- lol
	permanentStorage = true,
	order = getOrder(),
	settings = {
			{
			key = "SD_TEMP",
			name = L("settings.temp.display", "Temperature Display"),
			description = "",
			default = "External Temp", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Hidden", "External Temp", "Player Temp", "Current > Target" },
			},
		},
		{
			key = "SD_TEMP_STATE",
			name = L("settings.temp.state", "Display temperature state"),
			description = L("settings.temp.state.desc", "Display if you're freezing, cold, chilly, comfortable, warm, hot, or scorching"),
			renderer = "checkbox",
			default = true,
		},	
	},
}
-- Settings Migration
local legacySection = storage.playerSection('Settings'..MODNAME)
if legacySection:get("FONT_SIZE") then
	for id, template in pairs(settingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for i, entry in pairs(template.settings) do
			settingsSection:set(entry.key, legacySection:get(entry.key) or entry.default)
		end
	end
	legacySection:reset()
end

for id, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end
I.Settings.registerPage {
	key = MODNAME,
	l10n = "none",
	name = L("mod.name", "TimeHUD"),
	description = L("mod.desc", "Displays the in-game time, date, and (Sun's Dusk enjoyers only) temperature\n- Click and drag to move the position.\n- Click and mousewheel to change size.\n- Click and Shift+mousewheel to change bg opacity while in-game.")
}

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
for _, template in pairs(settingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.playerSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		local oldValue = _G[setting]
		_G[setting] = settingsSection:get(setting)
		--print(setting.." changed to "..settingsSection:get(setting))
		--readAllSettings()
	
		-- If language changed, recreate the HUD to apply translations
		if setting == "LANGUAGE" and timeHud then
			if updateTimeDisplay then
				updateTimeDisplay(true)
			end
			return
		end
	
		if timeHud then
			--change timehud layer
			timeHud.layout.layer = HUD_LOCK and 'Scene' or 'Modal'
			timeHudBackground.props.alpha = BACKGROUND_ALPHA
			timeText.props.textSize = FONT_SIZE
			
			if setting == "TEXT_ALIGNMENT" then
				if TEXT_ALIGNMENT == "Left" then
					timeHud.layout.props.anchor = v2(0, 0)
				elseif TEXT_ALIGNMENT == "Center" then
					timeHud.layout.props.anchor = v2(0.5, 0)
				elseif TEXT_ALIGNMENT == "Right" then
					timeHud.layout.props.anchor = v2(1, 0)
				end
			end
			
			if setting == "DATE_ON_TOP" and dateText then
				timeFlex.content.dateText = nil
				dateText = nil
			elseif setting == "HUD_X_POS" or setting == "HUD_Y_POS" then
				timeHud.layout.props.position = v2(HUD_X_POS, HUD_Y_POS)
			end
			
			if SHOW_DATE == "Off" and dateText then
				-- remove the text
				timeFlex.content.dateText = nil
				dateText = nil
			elseif SHOW_DATE ~= "Off" and not dateText then
				-- add the text
				dateText = {
					type = ui.TYPE.Text,
					name = "dateText",
					props = {
						text = "date",
						textColor = TEXT_COLOR,
						textShadow = true,
						textShadowColor = util.color.rgba(0,0,0,0.9),
						textAlignV = ui.ALIGNMENT.Start,
						textAlignH = ui.ALIGNMENT.Start,
						textSize = math.floor(FONT_SIZE * 0.9),
					},
				}
				if DATE_ON_TOP then
					timeFlex.content:insert(1, dateText)
				else
					timeFlex.content:add(dateText)
				end
			end
			if SHOW_DATE ~= "Off" then
				dateText.props.textSize = math.floor(FONT_SIZE * 0.9)
			end
			
			if updateTimeDisplay then -- if function is available (mod already initialized)
				updateTimeDisplay(true)
				--timeHud:update()
			end
			
			if UiModeChanged then  -- if function is available (mod already initialized)
				data = {
					newMode = I.UI.getMode(),
				}	
				UiModeChanged(data) -- calls timeHud:update()
			end	
		end	
	end))
end