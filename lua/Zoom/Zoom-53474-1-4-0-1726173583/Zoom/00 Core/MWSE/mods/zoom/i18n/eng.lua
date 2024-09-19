return {
	-- NOTE:
	-- If your string has string.format formatting codes such as %s, %.2f, etc.
	-- You need to escape them with another `%`. If you need a percentage (%)
	-- inside a label string in a slider you need to escape it twice, so four (%%%%).

	-- Put all the mcm strings here.
	["mcm"] = {
		-- General strings.
		["default"] = "Default",
		["settings"] = "Settings",

		-- The default sidebar text. Shown when NO button, slider, etc. is hovered over.
		["sidebar"] = "\nWelcome to Zoom!\n\nHover over a feature for more info.\n\nMade by:",

		-- Strings for inidividual settings:
		["zoomType"] = {
			["label"] = "Action type that triggers zooming:",
			["description"] = (
				"Press a button - zoom starts when a button is pressed. To stop zooming " ..
				"press the button again.\n\n" ..
				"Hold a button - zoom starts when a button is held. To stop zooming " ..
				"release the button.\n\n" ..
				"Scroll with the mouse wheel - zoom in and out by scrolling."
			),
			["options"] = {
				["press"] = "Press a button",
				["hold"] = "Hold a button",
				["scroll"] = "Scroll with the mouse wheel",

			}
		},
		["zoomKey"] = {
			["label"] = "The zoom key combination.",
			["description"] = "This key combination will trigger zooming. It's specific behavior depends on the Action type that triggers zooming setting. Used only if the Action type that triggers zooming is set to \"Press a button\" or \"Hold a button\".",
		},
		["maxZoom"] = {
			["label"] = "Max zoom: %%sx.",
			["description"] = "This is the maximal zoom percentage.",
		},
		["zoomStrength"] = {
			["label"] = "Zoom speed: %%s %%%%.",
			["description"] = "The zoom speed percentage.",
		},
		["faderOn"] = {
			["label"] = "Enable spyglass overlay?",
			["description"] = "\nIf enabled, when zooming, only a circle in the middle of the screen will be visible, while the rest of the screen will be black.\n\nDefault: Off"
		},
		["changeDrawDistance"] = {
			["label"] = "Change Draw Distance while zooming?",
			["description"] = "\nIf enabled, when zooming, your Draw Distance, distant fog start and end, far static end and very far static end values will be increased to allow seeing farther.\n\nThis setting may impact performance!\n\nDefault: Off"
		},
		["maxDrawDistance"] = {
			["label"] = "Maximum Draw Distance %%s cells.",
			["description"] = "\nIf Change Draw Distance is enabled, this is the maximal Draw Distance at maximal zoom.\n\nThis setting may impact performance!\n\nDefault: 20"
		},
		["logLevel"] = {
			["label"] = "Logging Level",
			["description"] = "Set the log level. If you've found a bug in the mod, please backup your MWSE.log, set the logging level to Trace, and replicate the bug. When reporting the bug please attach both MWSE.log files.",
		},
	},
}
