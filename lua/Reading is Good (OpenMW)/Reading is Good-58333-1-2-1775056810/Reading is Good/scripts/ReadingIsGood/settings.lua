MODNAME = "ReadingIsGood"

local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local settingsTemplate = {
	key = 'Settings' .. MODNAME,
	page = MODNAME,
	l10n = "none",
	name = "General                                                   ",
	description = "",
	permanentStorage = true,
	order = 0,
	settings = {
		{
			key = "RIG_TOGGLE",
			name = "Enable",
			description = "When disabled, skill books behave normally (vanilla +1 skill point).",
			default = true,
			renderer = "checkbox",
		},
		{
			key = "NEGATE_SKILLUP",
			name = "Negate skill gains from books",
			description = "When this is enabled, skill books will not grant a skill point.",
			default = true,
			renderer = "checkbox",
		},
		{
			key = "BOOK_BOOST",
			name = "Experience Boost for a single book",
			description = "Each skill book you read adds this as an XP multiplier for that skill.\n\n"
				.. "0.04 = 4% extra XP per book read.",
			default = 0.04,
			renderer = "number",
			argument = { min = 0.01, max = 1.0, },
		},
		{
			key = "BOOK_MAX",
			name = "Max Books Per Skill",
			description = "XP boost is capped after this many books per skill.\n"
				.. "With default settings: 5 books x 4% = 20% max boost.\n\n"
				.. "Note: Vanilla Morrowind usually has 5 skill books for each skill.\n\nMods such as Tamriel Data and OAAB add more.",
			default = 5,
			renderer = "number",
			argument = { integer = true, min = 1, max = 20, },
		},
		{
			key = "RIG_SKILLFRAMEWORK",
			name = "Allow Skill Framework Custom Books",
			description = "If Skill Framework is installed, also apply the xp boost\n"
				.. "mechanic to custom skill books registered through Skill Framework.\n\n"
				.. "Toggling this requires a restart",
			default = false,
			renderer = "checkbox",
		},
		{
			key = "RIG_INVENTORYX",
			name = "Show Skill Book Tooltips",
			description = "If Inventory Extender is installed, skill book tooltips\n"
				.. "will show if a skill book is Read/Unread,\nhow many books you've read for a skill,\nand your current XP boost.\n\n"
				.. "Toggling this requires a restart",
			default = true,
			renderer = "checkbox",
		},
		{
			key = "FETCH_PREVIOUS",
			name = "Check for previously read books",
			description = "Attempt to check what books you've read before installing this mod.\n"
				.. "Requires Quickloot 1.54+ from 03/2026\n\n"
				.. "Can not be reverted",
			default = false,
			renderer = "checkbox",
		},
		{
			key = "RIG_DEBUG",
			name = "Print Debug Messages",
			description = "Print debug information to the console.",
			default = false,
			renderer = "checkbox",
		},
	},
}

I.Settings.registerPage {
	key = MODNAME,
	l10n = "none",
	name = "Reading is Good",
	description = "Skill books give an experience percent boost instead of increasing a skill by a flat amount."
}

I.Settings.registerGroup(settingsTemplate)

function readAllSettings()
	local section = storage.playerSection(settingsTemplate.key)
	for _, entry in pairs(settingsTemplate.settings) do
		local newValue = section:get(entry.key)
		if newValue == nil then
			newValue = entry.default
		end
		_G["S_" .. entry.key] = newValue
	end
end

readAllSettings()

-- subscription
local settingsSection = storage.playerSection(settingsTemplate.key)
settingsSection:subscribe(async:callback(function(_, setting)
	local oldValue = _G["S_" .. setting]
	_G["S_" .. setting] = settingsSection:get(setting)
	-- trigger backfill when toggled on at runtime
	if setting == "FETCH_PREVIOUS" and not oldValue and _G["S_" .. setting] and fetchQuicklootBooks then
		fetchQuicklootBooks()
	end
end))
