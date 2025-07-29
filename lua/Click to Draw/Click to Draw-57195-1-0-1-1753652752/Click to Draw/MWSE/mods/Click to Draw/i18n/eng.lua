return {
	-- NOTE:
	-- If your string has string.format formatting codes such as %s, %.2f, etc.
	-- You need to escape them with another `%` (%%s, %%.2f, %%). A special case is
	-- their percentage (%) sign inside a label string in a MCM slider: you need to
	-- escape it twice, so four percentages (%%%%).

	-- The mod's name
	["Click to Draw"] = "Click to Draw",

	-- Put all the mcm strings here.
	["mcm"] = {
		-- General strings.
		["settings"] = "Settings",

		-- The default sidebar text. Shown when NO button, slider, etc. is hovered over.
		["sidebar"] = "\nWelcome to Click to Draw!\n\nHover over a feature for more info.\n\nMade by:",

		-- Strings for inidividual settings:
		["draw"] = {
			["label"] = "Draw weapon binding:",
			["description"] = "This mouse binding will draw a weapon.",
		},
		["sheath"] = {
			["label"] = "Sheath a weapon/unready a spell:",
			["description"] = "This mouse binding will put away your weapon.",
		},
		["raiseHands"] = {
			["label"] = "Ready a spell:",
			["description"] = "This mouse binding will cause the player to enter spell casting stance.",
		},
	},
}
