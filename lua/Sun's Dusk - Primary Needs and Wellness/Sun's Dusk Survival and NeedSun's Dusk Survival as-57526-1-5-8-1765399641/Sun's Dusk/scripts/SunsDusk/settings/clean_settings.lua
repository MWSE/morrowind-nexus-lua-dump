local settingsTemplate = {}

settingsTemplate.CLEAN = {
	key = "Settings"..MODNAME.."CLEAN",
	page = MODNAME.."CLEAN",
	l10n = "none",
	name = "Bathing and Cleanliness                                                 ",
	permanentStorage = true,
	order = 0,
	settings = {
			{
			key = "NEEDS_CLEAN",
			name = "Enable Bathing",
			description = "Requires temperature",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "CLEAN_HOURS_PER_STAGE", 
			name = "Hours per cleanliness stage",
			description = "There are 6 stages. Lower = get dirty faster. Higher = stay clean longer.\nDefault is 12 hrs which requires bathing at least twice a week",
			renderer = "number",
			default = 12,
			argument = { min = 1, max = 168, integer = true, },
		},
		{
			key = "CLEAN_LOCATION_MODIFIER",
			name = "Location affects dirtiness rate",
			description = "Caves, mines, tombs, and sewers will make you get dirty faster.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "CLEAN_WEATHER_MODIFIER",
			name = "Weather affects dirtiness rate",
			description = "Ash storms, blight storms, and blizzards will make you get dirty faster.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "CLEAN_NEKKI",
			name = "Clothing (or nothing) is required to bathe",
			description = "Must be wearing clothing or nothing to bathe.\nHelmet and footwear are excluded. Dry yourself off with a towel to prevent from getting cold/wet after bathing.\nDisabled by default.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "CLEAN_DISEASE_DAYS",
			name = "Days until disease from filth",
			description = "Get a random common disease if you haven't bathed for a while.\nSet to 0 to disable.",
			renderer = "number",
			default = 10,
			argument = { min = 0, max = 60, integer = true, },
		},
		{
			key = "CLEAN_SOAP_SLOAD",
			name = "Sload Soap isn't soap",
			description = "Only allow bathing with soap imported from the mainland",
			renderer = "checkbox",
			default = false,
		},		
	},
}
	
settingsTemplate.CLEAN_UI = {
	key = "Settings"..MODNAME.."CLEAN_UI",
	page = MODNAME.."CLEAN",
	l10n = "none",
	name = "Compatibility",
	permanentStorage = true,
	order = 1,
	settings = {
		{
			key = "C_QUICKLOOT",
			name = "Looting in tombs and dungeons makes you dirtier (Coming Soon)",
			description = "",
			renderer = "checkbox",
			default = true,
		},
--[[		{
			key = "C_COLOR",
			name = "Color of Cleanliness",
			description = "Change the color of the icon. Black (recommended for Classic background style) is 000000.\nDefault is white (FFFFFF).",
			disabled = false,
			default = util.color.hex("FFFFFF"), 
			renderer = "SuperColorPicker2",
			argument = {presetColors = presetColors},
		},
		{
			key = "C_BACKGROUND",
			name = "Background style",
			description = "",
			default = "No Background", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "No Background", "Classic", "Shadow" },
			},
		},
		{
			key = "C_BACKGROUND_COLOR",
			name = "Classic background color",
			description = "Background icon color if using Classic background style.\n\nDefault Morrowind colors include caa560 and dfc99f but I recommend ffcd7b for a 'vanilla' feel.",
			disabled = false,
			default = util.color.hex("ffcd7b"), 
			renderer = "SuperColorPicker2",
			argument = {presetColors = presetColors},
		},	]]		
	}
}



if world then
	for id, template in pairs(settingsTemplate) do
		I.Settings.registerGroup(template)
	end
else
	I.Settings.registerPage {
		key = MODNAME.."CLEAN",
		l10n = "none",
		name = "Sun's Dusk: Bathing",
		description = "" -- UI settings for Sun's Dusk
	}
end

--local debugLevelNames = { "Silent", "Quiet", "Chatty", "Deep", "Trace" }
--TEMP_DEBUG_LEVEL = 1


local function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.globalSection(template.key)
		for i, entry in pairs(template.settings) do
			_G[entry.key] = settingsSection:get(entry.key)
		end
	end
end

readAllSettings()

-- ────────────────────────────────────────────────────────────────────────── Settings Event ──────────────────────────────────────────────────────────────────────────

for _, template in pairs(settingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.globalSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		local oldValue = _G[setting]
		_G[setting] = settingsSection:get(setting)
		if not SDHUD then return end
		
		-- will be in local context:
		-- local sectionName = ... 
		-- local settingsSection = ...
		
		--print(sectionName.."\\"..setting.." changed to "..tostring(settingsSection:get(setting)))
		--_G[setting] = settingsSection:get(setting)

		
		for _, func in pairs(G_settingsChangedJobs or {}) do
			func(sectionName, setting, oldValue)
		end
		if G_refreshWidgetJobs then
			for _, func in pairs(G_refreshWidgetJobs) do
				func()
			end
			G_updateSDHUD()
			for _, func in pairs(G_refreshWidgetJobs) do
				func()
			end
		end
	end))
end
