return {
	-- NOTE:
	-- If your string has string.format formatting codes such as %s, %.2f, etc.
	-- You need to escape them with another `%` (%%s, %%.2f, %%). A special case is
	-- their percentage (%) sign inside a label string in a MCM slider: you need to
	-- escape it twice, so four percentages (%%%%).

	-- The mod's name
	["Torch Hotkey Extended"] = "Torch Hotkey Extended",

	-- Put all the mcm strings here.
	["mcm"] = {
		-- The default sidebar text. Shown when NO button, slider, etc. is hovered over.
		["sidebar"] = "\nWelcome to Torch Hotkey!\n\nHover over a feature for more info.\n",
		["Made by"] = "Made by",
		["Credits from original Torch Hotkey:"] = "Credits from original Torch Hotkey:",
		["Torch Hotkey by Remiros"] = "Torch Hotkey by Remiros",
		["Scripting help from Greatness7"] = "Scripting help from Greatness7",
		["Scripting help from NullCascade"] = "Scripting help from NullCascade",
		["Users of Torch Hotkey for providing feedback"] = "Users of Torch Hotkey for providing feedback",

		-- Strings for inidividual settings:
		["hotkey"] = {
			["label"] = "Torch hotkey",
			["description"] = "This action will be used to toggle the torch equip/unequip.",
		},
	},
}
