local I = require('openmw.interfaces')

local settingTemplate = {
    key = 'Settings'..MODNAME,
    page = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
	description = "",
    permanentStorage = true,
    settings = {
		{
			key = "CLOCK_INTERVAL",
			name = "Clock interval",
			description = "Update the clock every x minutes",
			renderer = "number",
			integer = true,
			default = 15,
			argument = {
				min = 1,
				max = 60,
			},
		},
		{
			key = "FONT_SIZE",
			name = "Font Size",
			description = "",
			renderer = "number",
			default = 23,
			argument = {
				min = 5,
				max = 100000,
			},
		},
		{
			key = "BACKGROUND_ALPHA",
			name = "Background Alpha",
			description = "",
			renderer = "number",
			default = 0.5,
			argument = {
				min = 0,
				max = 1,
			},
		},
		--{
		--	key = "BOOL",
		--	name = "bool",
		--	description = "",
		--	renderer = "checkbox",
		--	default = true
		--},
		{
			key = "SHOW_DATE",
			name = "Show Date",
			description = "",
			default = "Off", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"Off", "Morndas", "Morndas, 20.", "Heartfire", "Morndas, 20. Heartfire"}
			},
		},
	}
}

I.Settings.registerGroup(settingTemplate)

I.Settings.registerPage {
    key = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
    description = ""
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
	-- etc..
end

readAllSettings()

local updateSettings = function (_,setting)
	--print(setting.." changed to "..settingsSection:get(setting))
	readAllSettings()
	
	if timeHud then
		--timeHud.layout.content.timeHudBackground.props.alpha = BACKGROUND_ALPHA 	-- element stored in a global variable, let's access it like that instead
		--timeHud.layout.content.timeText.props.textSize = FONT_SIZE 				-- element stored in a global variable, let's access it like that instead
		timeHudBackground.props.alpha = BACKGROUND_ALPHA
		timeText.props.textSize = FONT_SIZE
		if SHOW_DATE == "Off" and dateText then
			-- remove the text
			timeFlex.content[2] = nil
			dateText = nil
		elseif SHOW_DATE ~= "Off" and not dateText then
			-- add the text
			dateText = {
				type = ui.TYPE.Text,
				name = "timeText",
				props = {
					text = "date",  -- Will be set by updateTimeDisplay
					textColor = fontColor,
					textShadow = true,
					textShadowColor = util.color.rgba(0,0,0,0.9),
					textAlignV = ui.ALIGNMENT.Center,
					textAlignH = ui.ALIGNMENT.Center,
					textSize = math.floor(FONT_SIZE * 0.9),
				},
			}		
			timeFlex.content:add(dateText)
		end
		if updateTimeDisplay then
			updateTimeDisplay(true)
			timeHud:update() -- always remember to update the root
		end
		if SHOW_DATE ~= "Off" then
		dateText.props.textSize = math.floor(FONT_SIZE * 0.9)
		end
	end		
end

settingsSection:subscribe(async:callback(updateSettings))