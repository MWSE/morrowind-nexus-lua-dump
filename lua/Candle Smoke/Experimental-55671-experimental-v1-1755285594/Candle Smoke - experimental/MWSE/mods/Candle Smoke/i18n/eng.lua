return {
	-- NOTE:
	-- If your string has string.format formatting codes such as %s, %.2f, etc.
	-- You need to escape them with another `%` (%%s, %%.2f, %%). A special case is
	-- their percentage (%) sign inside a label string in a MCM slider: you need to
	-- escape it twice, so four percentages (%%%%).

	-- The mod's name
	["Candle Smoke"] = "Candle Smoke",

	-- Put all the mcm strings here.
	["mcm"] = {
		-- General strings.
		["settings"] = "Settings",

		-- The default sidebar text. Shown when NO button, slider, etc. is hovered over.
		["sidebar"] = "\nWelcome to Candle Smoke!\n\nHover over a feature for more info.\n\nMade by:",

		-- Strings for inidividual settings:
		["smokeIntensity"] = {
			["label"] = "Effect intensity",
			["description"] = "You can increase or decrease smoke effect visibility.",
		},
		["disableCarriable"] = {
			["label"] = "Disable for carriable candles",
			["description"] = "If disabled, carriable candles won't have the smoke effect applied.",
		},
	},
}
