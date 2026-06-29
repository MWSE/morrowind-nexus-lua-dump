local settingsTemplate = {}

local RENDERER_SELECT = "SuperSelect2"
local RENDERER_NUMBER = "SuperSlider4"

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
			renderer = RENDERER_NUMBER,
			default = 12,
			argument = {
				min = 1,
				max = 168,
				step = 1,
				default = 12,
				unit = " hrs",
				minLabel = "Fast",
				maxLabel = "Slow",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "NEEDS_CLEAN_BUFFS_DEBUFFS",
			name = "Disable Cleanliness Penalties",
			description = "Enable if you only want buffs for being clean.",
			default = "Buffs and debuffs",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Buffs and debuffs", "Only buffs", "Only debuffs" },
				width = 170,
			},
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
			description = "Wearing armor prevents you from bathing.\nDisabled by default.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "CLEAN_DISEASE_DAYS",
			name = "Days until disease from filth",
			description = "Get a random common disease if you haven't bathed for a while.\nSet to 0 to disable.",
			renderer = RENDERER_NUMBER,
			default = 7,
			argument = {
				min = 0,
				max = 60,
				step = 1,
				default = 7,
				unit = " days",
				minLabel = "Off",
				maxLabel = "Rare",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "CLEAN_SOAP_SLOAD",
			name = "Sload Soap isn't soap",
			description = "Only allow bathing with soap imported from the mainland",
			renderer = "checkbox",
			default = false,
		},		
		{
			key = "CLEAN_ENABLE_TOWELS",
			name = "Allow using towels for drying",
			description = "",
			renderer = "checkbox",
			default = true,
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
			key = "CLEAN_QUICKLOOT",
			name = "Looting in tombs and dungeons makes you dirtier",
			description = "",
			renderer = "checkbox",
			default = true,
		},
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
		description = "Configure Bathing and Cleanliness. Requires Temperature to be enabled."
	}
end

--local debugLevelNames = { "Silent", "Quiet", "Chatty", "Deep", "Trace", "Spammy" }
--TEMP_DEBUG_LEVEL = 1

-- shared across every global settings file so presets can reach any global key
G_globalSettingDefaults = G_globalSettingDefaults or {}

local function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.globalSection(template.key)
		for i, entry in pairs(template.settings) do
			local newValue = settingsSection:get(entry.key)
			if newValue == nil then
				newValue = entry.default
			end
			_G[entry.key] = newValue
			G_globalSettingDefaults[entry.key] = { section = template.key, default = entry.default }
		end
	end
end

readAllSettings()

------------------------------ Settings Event ------------------------------

for _, template in pairs(settingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.globalSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		local oldValue = _G[setting]
		_G[setting] = settingsSection:get(setting)
		if not SDHUD then return end	
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