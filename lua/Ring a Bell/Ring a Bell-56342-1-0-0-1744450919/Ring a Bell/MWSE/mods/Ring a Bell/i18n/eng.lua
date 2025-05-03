return {
	-- The mod's name
	["Ring a Bell"] = "Ring a Bell",

	["message"] = "The bell doesn't move. Maybe I should hit it with something heavy?",

	-- Put all the mcm strings here.
	-- NOTE:
	-- If the string is used in string.format with formatting codes such as %s, %.2f, etc.
	-- You need to escape them with another `%` (%%s, %%.2f, %%). A special case is
	-- their percentage (%) sign inside a label string in a MCM slider: you need to
	-- escape it twice, so four percentages (%%%%).
	["mcm"] = {
		-- General strings.
		["settings"] = "Settings",

		-- The default sidebar text. Shown when NO button, slider, etc. is hovered over.
		["sidebar"] = "\nWelcome to Ring a Bell!\n\nHover over a feature for more info.\n\nMade by:",

		-- Strings for inidividual settings:
		["semitones"] = {
			["label"] = "Sound pitch change by +/- %%s semitones.",
			["description"] = "The pitch of the bell sounds is modulated by the charge time of the hammer hit. So, the longer the hammer hit is charged, the higher the pitch of the bell sound. To disable the pitch change set this setting to 0.",
		},
		["logLevel"] = {
			["label"] = "Logging Level",
			["description"] = "Set the log level. If you've found a bug in the mod, please backup your MWSE.log, set the logging level to Trace, and replicate the bug. When reporting the bug please attach both MWSE.log files.",
		},
	},
}
