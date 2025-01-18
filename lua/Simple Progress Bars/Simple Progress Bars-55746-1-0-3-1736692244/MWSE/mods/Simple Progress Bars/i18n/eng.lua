return {
	["mod.name"] = "Simple Progress Bars",
	["mod.auth.label"] = "Author: ",
	["mod.vers.label"] = "Version: ",

	["mod.info1"] = "This mod can add various informative bars to the game HUD. You can configure position, appearance and select what bars to show",
	["mod.info2"] = "No bars are shown by default. To see anything added by this mod, you have to select the bars from from the list in 'Select bars' tab first",
	["mod.info3"] = "The following bars are supported:\n- Skill progression\n- Armor durability (by slot)\n- A few character stats",


	["cfg.settings.label"] = "Settings",

	["cfg.settings.system.label"] = "System",
	["cfg.settings.enable.label"] = "Enable",
	["cfg.settings.enable.description"] = "Enable or disable this mod alltogether (requires restart)",
	["cfg.settings.logging.label"] = "Logging level",
	["cfg.settings.logging.description"] = "Set the logging level. Keep on NONE or ERROR unless you are debugging. Any level above WARN adds 'Debug' tab with additional debugging options",
	
	["cfg.settings.position.label"] = "Bars position",
	["cfg.settings.positionx.label"] = "X Position (horizontal)",
	["cfg.settings.positionx.description"] = "Set bars position along horizontal axis",
	["cfg.settings.positiony.label"] = "Y Position (vertical)",
	["cfg.settings.positiony.description"] = "Set bars position along vertical axis",

	["cfg.settings.appearance.label"] = "Bars appearance",
	["cfg.settings.mode.label"] = "Bars layout",
	["cfg.settings.mode.description"] = "Select bars layout. The options are:\n\n- Minimalist: only show the bars\n- Compact: show bars and icons\n- Labeled: show bars and labels\n- Full: show everything",

	["cfg.settings.mode.minimal"] = "Minimalist (bars only)",
	["cfg.settings.mode.compact"] = "Compact (bars & icons)",
	["cfg.settings.mode.labeled"] = "Labeled (bars & labels)",
	["cfg.settings.mode.maximal"] = "Full (everything)",

	["cfg.settings.munchkin.label"] = "Show countdowns where applicable",
	["cfg.settings.munchkin.description"] = "Show estimated time remaining to a skill levelup or armor depletion",
	["cfg.settings.width.label"] = "Width",
	["cfg.settings.width.description"] = "Set bars width",
	["cfg.settings.padding.label"] = "Padding",
	["cfg.settings.padding.description"] = "Set the blank spacing between bars",
	
	["cfg.selector.label"] = "Select bars",

	["cfg.selector.left.label"] = "Show values",
	["cfg.selector.right.label"] = "Possible values",
	["cfg.selector.description"] = "Select the values to show as bars. The list includes all Skills, even the custom ones. Armor slots are limited to those from vanilla game. The armor slots and total armor rating are only shown if the armor is present. Hower the bars in game to get more info",

	["cfg.debug.label"] = "Debug",

	["cfg.debug.info1"] = "Debugging panel",
	["cfg.debug.info2"] = "This tab allows configuring various debugging options, including logging level and debug output, and test some options in-game. Whatever you do, don't enable logging per tick unless you're completely sure what you're doing",
	["cfg.debug.info3"] = "Set logging level to NONE or ERROR to hide this tab. You can change logging level any time on the general settings tab",

	["cfg.debug.general.label"] = "General",
	["cfg.debug.dump.label"] = "Dump cache",
	["cfg.debug.dump.description"] = "Dump cache to MWSE.log. The game needs to be loaded or the cache will be empty",

	["cfg.debug.timestamp.label"] = "Print timestamps",
	["cfg.debug.timestamp.description"] = "Add timestamps to any logging output",
	["cfg.debug.logtick.label"] = "Log ticks",
	["cfg.debug.logtick.description"] = "This mod processes game data and updates the bars in ticks, generally equivalent to one second. This option enables debug output for each tick. Don't keep this ON, as the log will grow very big very fast",
	["cfg.debug.output.label"] = "Debug output",
	["cfg.debug.output.description"] = "Select where the debug output goes, to MWSE.log or to in-game console",
	
	["cfg.debug.testing.label"] = "Testing",
	["cfg.debug.testing.description"] = "Load the game and modify or test styling and values",

	["cfg.debug.testbar.show"] = "Show the testing bar",
	["cfg.debug.testbar.hideother"] = "Hide the other bars",
	["cfg.debug.testbar.revert"] = "Revert test bar colors",
	["cfg.debug.testbar.value"] = "Test bar value",
	
	["cfg.debug.symbol.label"] = "Label symbol width",
	["cfg.debug.symbol.description"] = "Change the arbitrary average font symbol 'width' metric for in-game label width calculation.  Will affect all labels.\n\nThe label width is calculated to avoid using the latest MWSE tes3ui.textLayout methods.\n\nDefault value: 75",


	["pref.armor"] = "Armor",
	["pref.skill"] = "Skill",
	["pref.char"] = "Character",

	["slot.helmet"] = "Helmet",
	["slot.cuirass"] = "Cuirass",
	["slot.pauldronleft"] = "Left pauldron",
	["slot.pauldronright"] = "Right pauldron",
	["slot.greaves"] = "Greaves",
	["slot.boots"] = "Boots",
	["slot.gauntletleft"] = "Left gauntlet",
	["slot.gauntletright"] = "Right gauntlet",
	["slot.shield"] = "Shield",
	["slot.bracerleft"] = "Left bracer",
	["slot.bracerright"] = "Right bracer",

	["char.level"] = "Next level",
	["char.weight"] = "Encumbrance",
	["char.armor"] = "Armor rating summary",
	["char.armorvsunarmored"] = "Armor rating vs Unarmored",
	["char.armorbroken"] = "Armor in worst condition",
	["char.bounty"] = "Bounty",
	["char.reputation"] = "Reputation",


	["tooltip.lvl.title"] = "Progress to next level",
	["tooltip.weight.title"] = "Encumbrance",
	["tooltip.bounty.title"] = "Bounty on player's head",
	["tooltip.rep.title"] = "Player's reputation",
	["tooltip.ar.title"] = "Armor rating summary",
	["tooltip.arua.title"] = "Armor rating vs max Unarmored",
	["tooltip.arworst.title"] = "Armor piece in worst condition",
	["tooltip.test.title"] = "Test bar",

	["tooltip.ar.stats"] = "Detailed stats:",
	["tooltip.ar.current"] = "The current rating: ",
	["tooltip.ar.max"] = "Maximum armor rating: ",
	["tooltip.ar.ua"] = "Unarmored contribution: ",
	["tooltip.ar.uamax"] = "Unarmored maximum (with no armor): ",

	["tooltip.lvl.of"] = " of ",
	["tooltip.lvl.to"] = " to next level",

	["tooltip.timer.h"] = "h",
	["tooltip.timer.m"] = "m",
	["tooltip.timer.s"] = "s",

	["tooltip.ar.note"] = "The stats represent current and maximum armor ratings including Unarmored slots. Maximum rating is what it would be if all the armor pieces were undamaged. Vanilla formulas are used for all calculations",
	["tooltip.arw.note"] = "The list represents all pieces of armor currently worn on player, along with their condition and effective contribution to armor rating. The one with the worst % condition is displayed on the bar",
	["tooltip.rep.note"] = "Your current overall renown status in the world",
	["tooltip.bounty.note"] = "Visit your local Thieves Guild representative to remove",
	["tooltip.weight.note"] = "Total weight your character carries. You can't move when it exceeds your carry capacity",
	["tooltip.lvl.note"] = "The progress to next level is a sum of minor and major skills level-ups. Points above 10 are transferred to next lvl. Skill-ups that count towards attribute multiplier are not preserved however",
}
