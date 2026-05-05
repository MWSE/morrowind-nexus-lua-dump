local RENDERER_SLIDER = "SuperSlider3" -- Alt: "number"
 
local settingsTemplate = {
	key = "Settings" .. MOD_NAME,
	page = MOD_NAME,
	l10n = "none",
	name = "Settings                                                      ",
	description = "",
	permanentStorage = true,
	settings = {
		{
			key = "CONVERSION_CHANCE",
			name = "Book Conversion Chance",
			description = "Chance for a book to be converted into a tome\nwhen entering a cell for the first time.",
			renderer = RENDERER_SLIDER,
			default = 5,
			argument = { min = 0, max = 100, step = 1, default = 5, showDefaultMark = true, showResetButton = false, minLabel = "Never", maxLabel = "Always", width = 150, thickness = 15, bottomRow = true, unit = "%", },
		},
		{
			key = "CONVERSION_DECLINE",
			name = "Conversion Decline",
			description = "After a tome is converted, multiplier to increase chance of getting another.", -- Multiplier on conversion chance after each converted book
			renderer = RENDERER_SLIDER,
			default = 0.7,
			argument = { min = 0, max = 1, step = 0.05, default = 0.7, showDefaultMark = true, showResetButton = false, width = 150, thickness = 15, bottomRow = true, },
		},
		{
			key = "MIN_CAST_CHANCE",
			name = "Minimum Cast Chance for Spawns",
			description = "Spell tomes spawn based on your cast chance for the spell they contain\nSet the minimum cast chance a spell must have for its tome to appear\nLowering this will give you a wider variety of spells.",
			renderer = RENDERER_SLIDER,
			default = 50,
			argument = { min = 0, max = 500, step = 1, default = 50, showDefaultMark = true, showResetButton = false, width = 150, thickness = 15, bottomRow = true, unit = "%", },
		},
		{
			key = "MAX_CAST_CHANCE",
			name = "Maximum Cast Chance for Spawns",
			description = "Spell tomes spawn based on your cast chance for the spell they contain\nSet the maximum cast chance a spell must have for its tome to appear\nIncreasing this will give you a wider variety of spells.",
			renderer = RENDERER_SLIDER,
			default = 200,
			argument = { min = 0, max = 500, step = 1, default = 200, showDefaultMark = true, showResetButton = false, width = 150, thickness = 15, bottomRow = true, unit = "%", },
		},
		{
			key = "ADD_TO_ENCHANTERS",
			name = "Enchanters Sell Tomes",
			description = "Set to 0 to disable Enchanters selling tomes.",
			renderer = RENDERER_SLIDER,
			default = 2,
			argument = { min = 0, max = 20, step = 1, default = 3, showDefaultMark = true, showResetButton = false, minLabel = "None", maxLabel = "Many", width = 150, thickness = 15, bottomRow = true, },
		},
		{
			key = "ADD_TO_BOOKSELLERS",
			name = "Booksellers sell tomes",
			description = "Set to 0 to disable Booksellers selling tomes.",
			renderer = RENDERER_SLIDER,
			default = 3,
			argument = { min = 0, max = 20, step = 1, default = 3, showDefaultMark = true, showResetButton = false, minLabel = "None", maxLabel = "Many", width = 150, thickness = 15, bottomRow = true, },
		},
		{
			key = "NPC_CLASS_CHANCE",
			name = "NPC Class Chance",
			description = "Chance for NPCs to have spell tomes based on class.\n\nSet to 0 to disable which is recommended if using WARES.",
			renderer = RENDERER_SLIDER,
			default = 15,
			argument = { min = 0, max = 100, step = 1, default = 15, showDefaultMark = true, showResetButton = false, minLabel = "Never", maxLabel = "Always", width = 150, thickness = 15, bottomRow = true, unit = "%", },
		},
		{
			key = "RARE_SPAWN_CHANCE",
			name = "Rare Tome Spawn Chance",
			description = "Chance for rare or quest-locked spells to be eligible for spawning.\n\nDisabled by default. To enable, increase the number.",
			renderer = RENDERER_SLIDER,
			default = 0,
			argument = { min = 0, max = 100, step = 1, default = 0, showDefaultMark = true, showResetButton = false, minLabel = "Off", maxLabel = "Often", width = 150, thickness = 15, bottomRow = true, unit = "%", },
		},	
-- add new settings page here		
		{
			key = "INSIGHT_MULT",
			name = "Insight Effect",
			description = "If you have the Unofficial Tamriel Rebuilt Spells, casting Insight will improve the quality of spell tomes that appear.\n\nYou can change the strength (multiplier) of this effect or set to 0 to disable.",
			renderer = RENDERER_SLIDER,
			default = 1,
			argument = { min = 0, max = 10, step = 0.25, default = 1, showDefaultMark = true, showResetButton = false, width = 150, thickness = 15, bottomRow = true, },
		},
		{
			key = "TEACH_COMPANIONS",
			name = "Companions Learn from Tomes",
			description = "Companions can learn spells from spell tomes in their inventory.\n\nRequires Follower Detection Utility.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "MOS_TOME_WEIGHT",
			name = "Merits of Service: Tome Reward Weight",
			description = "If Merits of Service is installed, this controls how often spell tomes are picked as a faction quest reward, relative to skill and attribute rewards (which default to weight 1).\n\nSet to 0 to disable tome rewards.",
			renderer = RENDERER_SLIDER,
			default = 1,
			argument = { min = 0, max = 10, step = 0.25, default = 1, showDefaultMark = true, showResetButton = false, width = 150, thickness = 15, bottomRow = true, },
		},
		{
			key = "MOS_MIN_TOMES",
			name = "Merits of Service: Min Tomes per Reward",
			description = "Minimum number of tomes granted when a Merits of Service tome reward fires.",
			renderer = RENDERER_SLIDER,
			default = 1,
			argument = { min = 1, max = 5, step = 1, default = 1, showDefaultMark = true, showResetButton = false, width = 150, thickness = 15, bottomRow = true, },
		},
		{
			key = "MOS_MAX_TOMES",
			name = "Merits of Service: Max Tomes per Reward",
			description = "Maximum number of tomes granted when a Merits of Service tome reward fires.",
			renderer = RENDERER_SLIDER,
			default = 1,
			argument = { min = 1, max = 5, step = 1, default = 1, showDefaultMark = true, showResetButton = false, width = 150, thickness = 15, bottomRow = true, },
		},
		{
			key = "BLACKLISTED_CELLS",
			name = "Blacklisted Cells",
			description = "Must be set before entering the cell. Separated by semicolons.",
			default = "Tel Uvirith Tower Lower; Tel Uvirith Tower Upper",
			renderer = "textLine",
		},
	},
}
 
if world then
	I.Settings.registerGroup(settingsTemplate)
else
	I.Settings.registerPage {
		key = MOD_NAME,
		l10n = "none",
		name = MOD_NAME,
		description = "",
	}
end
 
local settingsSection = storage.globalSection(settingsTemplate.key)
  
-- cache settings into S table
local function readAllSettings()
	for _, entry in pairs(settingsTemplate.settings) do
		local value = settingsSection:get(entry.key)
		if value == nil then
			value = entry.default
		end
		S[entry.key] = value
	end
end
 
readAllSettings()
 
-- keep S in sync with changes
settingsSection:subscribe(async:callback(function(_, setting)
	if setting then
		local value = settingsSection:get(setting)
		S[setting] = value
	else
		readAllSettings()
	end
end))