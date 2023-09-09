return {
	["defaultText"] = "Lorem ipsum\n<br>",
	["missingLineBreakText"] = "Current book's text is missing a <br> tag at the end. It's text might not show up properly.",
	["loadNeeded"] = "You need to load a character to perfrom this action.",
	["alreadyAdded"] = "Your current character already has that book.",

	-- Put all the mcm strings here.
	["mcm"] = {
		-- General strings.
		["default"] = "Default",
		["settings"] = "Settings",
		["modname"] = "Live Book Editing",
		["On"] = "On",
		["Off"] = "Off",

		-- The default sidebar text. Shown when NO button, slider, etc. is hovered over.
		["sidebar"] = (
			"\nWelcome to Live Book Editing!\n\n" ..
			"This mod allows you to edit book text and see your changes ingame. " ..
			"Hover over a feature for more info.\n\nMade by:"
		),

		["hotkeys"] = {
			["label"] = "Hotkeys",
			["bookKey"] = {
				["label"] = "Key combination to open a book menu.",
				["description"] = "This key combination will open a book menu with text loaded from file: \"Data files\\booktext.txt\".",
			},
			["scrollKey"] = {
				["label"] = "Key combination to open a scroll menu.",
				["description"] = "This key combination will open a scroll menu with text loaded from file: \"Data files\\scrolltext.txt\".",
			},
		},

		["testItem"] = {
			["label"] = "Test items",
			["add"] = "Add",
			["addBook"] = {
				["label"] = "Add the preview book to your character automatically.",
				["description"] = "If On, it will check if you character doesn't have the preview book in inventory and add it on game load.",
			},
			["addBookNow"] = {
				["label"] = "Add the preview book to your character now.",
				["description"] = "\nAdds the preview book to your currently loaded character.",
			},
			["addScroll"] = {
				["label"] = "Add the preview scroll to your character automatically.",
				["description"] = "If On, it will check if you character doesn't have the preview scroll in inventory and add it on game load.",
			},
			["addScrollNow"] = {
				["label"] = "Add the preview scroll to your character now.",
				["description"] = "\nAdds the preview scroll to your currently loaded character.",
			},
		},

		-- Strings for inidividual settings:
		["logLevel"] = {
			["label"] = "Logging Level",
			["description"] = "Set the log level. If you've found a bug in the mod, please backup your MWSE.log, set the logging level to Trace, and replicate the bug. When reporting the bug please attach both MWSE.log files.",
		},
	},
}
