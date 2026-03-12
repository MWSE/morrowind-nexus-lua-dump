local I = require("openmw.interfaces")
local storage = require("openmw.storage")

local MOD_NAME = "ReadingIsGood"

I.Settings.registerPage {
	key = MOD_NAME,
	l10n = "none",
	name = "Reading is Good",
	description = "Skill books give an experience percent boost\ninstead of increasing a skill by a flat amount."
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. MOD_NAME,
	page = MOD_NAME,
	l10n = "none",
	name = "General",
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
			description = "Each skill book you read adds this as an XP multiplier for that skill.\n"
				.. "0.04 = 4% extra XP per book read.",
			default = 0.04,
			renderer = "number",
			argument = { min = 0.01, max = 1.0, },
		},
		{
			key = "BOOK_MAX",
			name = "Max Books Per Skill",
			description = "XP boost is capped after this many books per skill.\n"
				.. "With default settings: 5 books x 4% = 20% max boost.\n"
				.. "Note: Vanilla Morrowind usually has 5 skill books for each skill.\nMods such as Tamriel Data and OAAB add more.",
			default = 5,
			renderer = "number",
			argument = { integer = true, min = 1, max = 20, },
		},
		{
			key = "RIG_SKILLFRAMEWORK",
			name = "Allow Skill Framework Custom Books",
			description = "If Skill Framework is installed, also apply the xp boost\n"
				.. "mechanic to custom skill books registered through Skill Framework.\n"
				.. "Toggling this requires a restart",
			default = false,
			renderer = "checkbox",
		},
		{
			key = "RIG_INVENTORYX",
			name = "Show Skill Book Tooltips",
			description = "If Inventory Extender is installed, skill book tooltips\n"
				.. "will show if a skill book is Read/Unread,\nhow many books you've read for a skill,\nand your current XP boost.\n"
				.. "Toggling this requires a restart",
			default = true,
			renderer = "checkbox",
		},
		{
			key = "FETCH_PREVIOUS",
			name = "Check for previously read books",
			description = "Attempt to check what books you've read before installing this mod.\n"
				.. "Requires Quickloot 1.54+ from 03/2026\n"
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