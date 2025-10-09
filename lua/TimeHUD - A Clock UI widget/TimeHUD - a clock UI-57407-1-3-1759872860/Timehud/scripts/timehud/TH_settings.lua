local I = require('openmw.interfaces')
local layerId = ui.layers.indexOf("HUD")
local hudLayerSize = ui.layers[layerId].size
local screenres = ui.screenSize()
local uiScale = screenres.x / hudLayerSize.x
	
local settingTemplate = {
    key = 'Settings'..MODNAME,
    page = MODNAME,
    l10n = "none",
    name = MODNAME,
	description = "",
    permanentStorage = true,
    settings = {
		{
			key = "CLOCK_INTERVAL",
			name = "Clock Interval",
			description = "Update the clock every x minutes in-game.\nDefault is 15",
			renderer = "number",
			integer = true,
			default = 15,
			argument = {
				min = 1,
				max = 60,
			},
		},
		{
			key = "HUD_LOCK",
			name = "Lock Position",
			description = "",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "HUD_X_POS",
			name = "X Position",
			description = "",
			renderer = "number",
			integer = true,
			default = math.floor(hudLayerSize.x*0.01),
		},		
		{
			key = "HUD_Y_POS",
			name = "Y Position",
			description = "",
			renderer = "number",
			integer = true,
			default = math.floor(hudLayerSize.y*(1-0.065*uiScale)),
		},			
		{
			key = "HUD_DISPLAY",
			name = "HUD Display",
			description = "When to display the HUD/widget element. Interface = when menus are pulled up",
			default = "Always", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"Always", "Interface Only", "Hide on Interface","Hide on Dialogue Only","Never"},
			},
		},
		{
			key = "FONT_SIZE",
			name = "Font Size",
			description = "Increase or decrease font size.\nDefault is 23",
			renderer = "number",
			default = 23,
			argument = {
				min = 5,
				max = 100000,
			},
		},
		{
			key = "TEXT_COLOR",
			name = "Text Color",
			description = "Change the color of the text.\nDefaults are typically: caa560 ; dfc99f\nBlue: 81CDED (blue)",
			disabled = false,
			renderer = "color",
			default =  getColorFromGameSettings("FontColor_color_normal"),
		},
		{
			key = "BACKGROUND_ALPHA",
			name = "Background Opacity",
			description = "Increase or decrease background opacity.\n0-1, default is 0.5",
			renderer = "number",
			default = 0.5,
			argument = {
				min = 0,
				max = 1,
			},
		},
		{
			key = "SHOW_DATE",
			name = "Show Date",
			description = "Different formats for displaying the date.",
			default = "Morndas, 20. Heartfire", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"Off", "Morndas", "Morndas, 20.", "Heartfire", "Morndas, 20. Heartfire"}
			},
		},
		{
			key = "DATE_ON_TOP",
			name = "Date On Top",
			description = "",
			renderer = "checkbox",
			default = false,
		},		
		{
			key = "TEXT_ALIGNMENT",
			name = "Text Alignment",
			description = "Align the time and date.\nDefault is left",
			renderer = "select",
			default = "Left",
			argument = {
				disabled = false,
				l10n = "none",
				items = {"Left", "Center", "Right"}
				},
		},
		{
			key = "CLOCK_FORMAT",
			name = "Time Format",
			description = "",
			renderer = "select",
			default = "Normal",
			argument = {
				disabled = false,
				l10n = "none",
				items = {"Normal", "12",}
				},
		},		
	}
}

I.Settings.registerGroup(settingTemplate)

I.Settings.registerPage {
    key = MODNAME,
    l10n = "none",
    name = MODNAME,
    description = "Displays the in-game time and date.\n- Hover and mousewheel to change size.\n- Click and drag to move the position.\n- Click and Shift+mousewheel to change bg opacity while in-game."
}

-- called on init and when settings change
function readAllSettings()
	--print("caching settings")
	for i, entry in pairs(settingTemplate.settings) do
		--print(entry.key.." = "..tostring(settingsSection:get(entry.key)))
		_G[entry.key] = settingsSection:get(entry.key)
	end
	-- saves all current settings values into global variables for easier access and better performance
	-- FONT_SIZE = 23 			-- instead of settingsSection:get("FONT_SIZE")
	-- BACKGROUND_ALPHA = 0.5	-- instead of settingsSection:get("BACKGROUND_ALPHA")
	-- etc.
end

readAllSettings()

local updateSettings = function (_,setting)
	--print(setting.." changed to "..settingsSection:get(setting))
	readAllSettings()
	
	if timeHud then
		--change timehud layer
		timeHud.layout.layer = HUD_LOCK and 'Scene' or 'Modal'
		timeHudBackground.props.alpha = BACKGROUND_ALPHA
		timeText.props.textSize = FONT_SIZE
		
		if setting == "DATE_ON_TOP" and dateText then
			timeFlex.content.dateText = nil
			dateText = nil
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
end

settingsSection:subscribe(async:callback(updateSettings))