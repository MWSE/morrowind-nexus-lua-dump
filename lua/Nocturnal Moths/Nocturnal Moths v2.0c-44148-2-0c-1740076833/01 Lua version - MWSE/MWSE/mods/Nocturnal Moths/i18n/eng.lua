return {
	-- NOTE:
	-- If your string has string.format formatting codes such as %s, %.2f, etc.
	-- You need to escape them with another `%` (%%s, %%.2f, %%). A special case is
	-- their percentage (%) sign inside a label string in a MCM slider: you need to
	-- escape it twice, so four percentages (%%%%).

	-- The mod's name
	["Nocturnal Moths"] = "Nocturnal Moths",

	-- Put all the mcm strings here.
	["mcm"] = {
		-- General strings.
		["settings"] = "Settings",

		-- The default sidebar text. Shown when NO button, slider, etc. is hovered over.
		["sidebar"] = "\nWelcome to Nocturnal Moths!\n\nHover over a feature for more info.\n\nMade by:",
		["leaveCell"] = "You must leave the current cell before this change will come into effect.",

		-- Strings for inidividual settings:
		["enableSound"] = {
			["label"] = "Enable moths sound effect",
			["description"] = "When enabled, a subtle sound will be played by moths orbiting a lantern.",
		},
		["soundVolume"] = {
			["label"] = "Sound volume",
			["description"] = "Adjust moths' sound effect volume.",
		},
		["whitelist"] = {
			["label"] = "Additional lanterns",
			["description"] = "You can specify additinal lanterns that will have moths effect applied. The lists below contain lantern meshes. To easily find the mesh of a lantern you encounter in-game, consider using Selection Detail by NullCascade. Consider contacting us with additional lanterns you've applied moths to, so other users of Nocturnal Moths may benefit from this.",
			["leftListLabel"] = "Additional lights that will have moths",
			["rightListLabel"] = "Other available lights that don't have moths",
		},
		["logLevel"] = {
			["label"] = "Logging Level",
			["description"] = "Set the log level. If you've found a bug in the mod, please backup your MWSE.log, set the logging level to Trace, and replicate the bug. When reporting the bug please attach both MWSE.log files.",
		},
	},
}
