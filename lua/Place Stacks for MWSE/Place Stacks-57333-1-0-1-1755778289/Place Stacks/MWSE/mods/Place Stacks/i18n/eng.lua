return {
	-- NOTE:
	-- If your string has string.format formatting codes such as %s, %.2f, etc.
	-- You need to escape them with another `%` (%%s, %%.2f, %%). A special case is
	-- their percentage (%) sign inside a label string in a MCM slider: you need to
	-- escape it twice, so four percentages (%%%%).

	-- The mod's name
	["Place Stacks"] = "Place Stacks",
	["No items transferred!"] = "No items transferred!",
	["%s and %s"] = "%%s and %%s",
	["Stored in: %s"] = "Stored in: %%s",
	["Items"] = "Items",
	["Amount"] = "Amount",
	["Transfer Results"] = "Transfer Results",

	-- Put all the mcm strings here.
	["mcm"] = {
		-- General strings.
		["settings"] = "Settings",
		-- The default sidebar text. Shown when NO button, slider, etc. is hovered over.
		["sidebar"] = "\nWelcome to Place Stacks!\n\nHover over a feature for more info.\n\nMade by:",

		["buttonEnabled"] = {
			["label"] = "Place Stacks button:",
			["description"] = "Adds a \"Place Stacks\" button to the container contents menu."
		},
		["transferGold"] = {
			["label"] = "Store gold?",
			["description"] = "If enabled, placing stacks will also transfer the player's gold to a container if it contains gold."
		},
		["closeMenu"] = {
			["label"] = "Close container menu after transfer?",
			["description"] = "If enabled, the container contents menu will be closed after placing stacks."
		},
		["filterOwned"] = {
			["label"] = "Disallow transferring items to containers that the player doesn't have ownership access to?"
		},
		["Activate Key"] = "Activate Key",
		["activateEnabled"] = {
			["label"] = "Place stacks by holding Activate keybind?",
			["description"] = "If enabled, holding the %%s key after opening a container will transfer stacks to the container."
		},
		["activateDelay"] = {
			["label"] = "Activate delay = %%s ms",
			["description"] = "How long does the activate keybind need to be held to trigger place stacks?"
		},
		["Custom Keybind"] = "Custom Keybind",
		["keybind"] = {
			["label"] = "Keybind for place stacks",
			["description"] = "Here, you can bind a custom key to trigger the place stacks functionality. It can be used while the container contents menu is open. Optionally, you can also use it outside of the menu."
		},
		["placeStacksOutOfMenu"] = {
			["label"] = "Enable place stacks out of the contents menu?",
			["description"] = "If enabled, pressing the keybind will transfer item stacks into nearby containers."
		},
		["distanceMax"] = {
			["label"] = "The maximum distance at which a container will be considered for storing stacks",
			["description"] = "For reference, standard actor height in Morrowind is 5 feet 9 (1.77 m)."
		},
		["shortTransferReport"] = {
			["label"] = "Enable short transfer report?",
			["description"] = "If enabled, after storing stacks out of the menu, a short message box will be shown with a list of containers where the stacks of items were stored."
		},
		["detailedTransferReport"] = {
			["label"] = "Enable detailed transfer report?",
			["description"] = "If enabled, after storing stacks out of the menu, a comprehensive menu with a listing of all the items transferred will be shown."
		},
	},
}
