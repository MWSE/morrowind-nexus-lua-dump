return {
	["Command Menu"] = "Command Menu",
	["General"] = "General",
	["Search..."] = "Search...",
	["Added"] = "Added",
	["Load a game to open Command Menu."] = "Load a game to open Command Menu.",


	-- General tab
	["Engine settings"] = "Engine settings",
	["God mode"] = "God mode",
	["Collision"] = "Collision",
	["Vanity mode"] = "Vanity mode",
	["AI enabled"] = "AI enabled",
	["Fog of war on local map"] = "Fog of war on local map",
	["Wireframe mode"] = "Wireframe mode",
	["Draw cell borders"] = "Draw cell borders",
	["Draw collision boxes"] = "Draw collision boxes",
	["Draw path grid nodes"] = "Draw path grid nodes",
	["Teleportation spells enabled"] = "Teleportation spells enabled",
	["Levitation spells enabled"] = "Levitation spells enabled",

	["Mechanics"] = "Mechanics",
	["Combat enabled"] = "Combat enabled",
	["Rest interrupt enabled"] = "Rest interrupt enabled",
	["Essential actors can't be damaged"] = "Essential actors can't be damaged",
	["Always hit"] = "Always hit",
	["Casting always succeeds"] = "Casting always succeeds",
	["Spells don't consume magicka"] = "Spells don't consume magicka",
	["Enchantments don't consume charge"] = "Enchantments don't consume charge",
	["Brewing potions always succeeds"] = "Brewing potions always succeeds",
	["Self-repairing equipment always succeeds"] = "Self-repairing equipment always succeeds",
	["Picking locks always succeeds"] = "Picking locks always succeeds",
	["Player doesn't recieve Sun Damage as a Vampire"] = "Player doesn't recieve Sun Damage as a Vampire",
	["Fatiguesless jumping"] = "Fatiguesless jumping",

	["Security & Crime"] = "Security & Crime",
	["Auto unlock doors and containers"] = "Auto unlock doors and containers",
	["Current player bounty"] = "Current player bounty",
	["Clear bounty"] = "Clear bounty",
	["Stealing owned items is not a crime"] = "Stealing owned items is not a crime",
	["Picking locks isn't considered a crime"] = "Picking locks isn't considered a crime",
	["Clear stolen flag on items in player's inventory"] = "Clear stolen flag on items in player's inventory",
	["Clear"] = "Clear",
	["Stolen flag cleared."] = "Stolen flag cleared.",

	["Time & Weather"] = "Time & Weather",
	["Change current weather:"] = "Change current weather:",
	["Timescale"] = "Timescale",
	["Simulation time scale"] = "Simulation time scale",

	["Misc"] = "Misc",
	["Reset actors"] = "Reset actors",
	["Fix me"] = "Fix me",
	["Kill hostiles"] = "Kill hostiles",
	["Show all map markers"] = "Show all map markers",
	["Fill journal"] = "Fill journal",
	["Open stats review menu"] = "Open stats review menu",
	["Recharge player powers"] = "Recharge player powers",
	["All powers recharged."] = "All powers recharged.",
	["Remove magic"] = "Remove magic",
	["Removed all curses, diseases and spells."] = "Removed all curses, diseases and spells.",
	["Player can colide with other actors and projectiles?"] = "Player can colide with other actors and projectiles?",
	["Player can colide with other objects?"] = "Player can colide with other objects?",


	-- Player tab
	["Player"] = "Player",
	["Player stats"] = "Player stats",
	["Primary Attributes"] = "Primary Attributes",
	["Set x to y"] = "Set %%s to %%.0f.",
	["Derived Attributes"] = "Derived Attributes",
	["health"] = "health",
	["magicka"] = "magicka",
	["fatigue"] = "fatigue",
	["encumbrance"] = "encumbrance",
	["Skills"] = "Skills",


	-- Items tab
	["Items"] = "Items",
	["Choose items to add"] = "Choose items to add",
	["No. items to add"] = "No. items to add",


	-- Spells tab
	["Spells"] = "Spells",
	["Choose spells to learn"] = "Choose spells to learn",
	["Learned"] = "Learned",


	-- Soul Gems tab
	["Soul Gems"] = "Soul Gems",
	["Choose a soul gem to add"] = "Choose a soul gem to add",
	["Choose a Soul Gem:"] = "Choose a Soul Gem:",
	["Choose a Soul:"] = "Choose a Soul:",
	["Too large soul"] = "Selected soul is too large for currently selected soul gem. \z
		Consider choosing a creature with a smaller soul or a soul gem of higher capacity.",
	["Add"] = "Add",


	-- Teleport tab
	["Teleport"] = "Teleport",

	["Teleport to..."] = "Teleport to...",
	["Cell"] = "Cell",
	["NPC"] = "NPC",
	["Do you wish to teleport to the NPC's location or teleport the NPC in front of yourself?"] =
		"Do you wish to teleport to the NPC's location or teleport the NPC in front of yourself?",
	["Teleport %s here"] = "Teleport %%s here",
	["Teleport to %s's location"] = "Teleport to %%s's location",
	-- In the hover tooltip over the NPC's location:
		["Id"] = "Id",
		["Located at"] = "Located at",
		["Dead"] = "Dead",


	-- Factions tab
	["Factions"] = "Factions",
	["Manage faction membership"] = "Manage faction membership",
	["Status: not a member."] = "Status: not a member.",
	["Status: expelled."] = "Status: expelled.",
	["Status: member, rank"] = "Status: member, rank",
	["Join"] = "Join",
	["Leave"] = "Leave",
	["Demote"] = "Demote",
	["Promote"] = "Promote",
	["Rejoin"] = "Rejoin",
	["Expel"] = "Expel",
	["You reached top rank in this faction."] = "You reached top rank in this faction.",


	-- Quests tab
	["Quests"] = "Quests",
	["Choose a quest..."] = "Choose a quest...",
	["Selected quest"] = "Selected quest",
	["Current journal index"] = "Current journal index",
	["Journal index"] = "Journal index",
	["Quest name"] = "Quest name",
	["Finished"] = "Finished",
	["Restart"] = "Restart",


	["mcm"] = {
		-- The default sidebar text. Shown when NO button, slider, etc. is hovered over.
		["sidebar"] = "\nWelcome to Command Menu!\n\nHover over a feature for more info.\n\nMade by:",

		["openMenuKey"] = {
			["label"] = "Open Command menu key",
			["description"] = "This key combination opens the Command Menu. It can only be opened in-game.",
		},
		["sampleLandscapeKey"] = {
			["label"] = "Sample landscape texture key",
			["description"] = "Pressing this key combination shows the name of the landscape texture the player is \z
				looking at in a Messagebox.",
		},
		["filterOutDeprecated"] = {
			["label"] = "Don't list deprecated objects in Command Menu",
			["description"] = "Various asset repository mods such as Tamrial Data and OAAB Data periodically deprecate assets. \z
							These are named as \"<Deprecated>\", \"< DEPRECATED >\", etc.\n\n\z
							These objects won't be listed in the Command Menu's Items, Spells, NPC and Faction lists \z
							with this option enabled. This option also filters out template objects, usually named \z
							<Template>.",
		},
	},
}
