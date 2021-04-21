local config = require("OEA.OEA5 Bash.config")

local template = mwse.mcm.createTemplate({ name = "Lua Lockbashing" })
template:saveOnClose("Lua_Lockbashing", config)

local sidebarDefault = 
(
	"These options allow you to adjust aspects of the new item loss feature, and if you even want it at all, along with "..
	"some other settings, such as how you want lock tooltips to be handled."
)

local page = template:createSideBarPage
{
	description = sidebarDefault
}

page:createDropdown({
	label = "How would you like to handle lock tooltips?",
	options = {
		{ label = "0 Do it yourself", value = 0 },
		{ label = "1 Pause Menu flicker", value = 1 },
		{ label = "2 Forced, and exact, update", value = 2 }
	},
	defaultSetting = 1,
	variable = mwse.mcm:createTableVariable({ id = "tooltip", table = config }),
	description = "These options control how the refreshing of tooltips is handled. Option 0 means that no relevant code runs, "..
		"and you have to look away from the item and back yourself to see the new lock level. Option 1 means that when you lock bash, the pause menu will briefly flicker on "..
		"and then off again to refresh the tooltip. Sometimes, you will have to exit the pause menu yourself. Option 2 means that "..
		"the tooltip text is overwritten by the code, to state that it's unlocked or what the new level is. This new text, however, will always be "..
		"the exact lock level of the item, which is a problem if you use Locks and Traps Detection, because you may be gaining information you "..
		"are not supposed to have. Finally. thanks to Zobator for coming up with Option 2's code."
})

page:createTextField{
	label = "Strength Multiplier",
	variable = mwse.mcm:createTableVariable{
		id = "OldMult", 
		table = config
	},
	numbersOnly = true,
	description = "When lock bashing, your weapons degrade by an amount equal to your strength times this number. If you use fists, your hand-to-hand skill instead "..
			"is damaged by an amount equal to your strength divided by 10, rounded down. In Greatness7's original mod, the value of this multiplier was 3, however "..
			"you can change it to whatever you like."
}

page:createYesNoButton{
	label = "Should you be able to bash with fists?",
	variable = mwse.mcm:createTableVariable{
		id = "Hand",
		table = config
	},
	description = "With this, you are able to bash a lock even without a weapon, by using unarmed attacks. Your chances are much worse, "..
			"and instead of weapon condition your Hand-to-Hand skill is indefinitely damaged. This feature was not a part "..
			"of Greatness7's original mod, but it is on by default since it was a feature in Daggerfall."
}

page:createYesNoButton{
	label = "Do you want degredation and item loss on at all?",
	variable = mwse.mcm:createTableVariable{
		id = "Break",
		table = config
	},
	description = "With this feature enabled, each failed or successful bash hit increases the percent by which weapons and armor degrade, "..
			"and the chance that some number of other items may be removed. This was not a part of Greatness7's original mod, but rather "..
			"a request made by the Nexus user Stiffkittin."
}

page:createSlider{
	label = "Degradation Multiplier",
	variable = mwse.mcm:createTableVariable{
		id = "DegMult", 
		table = config
	},
	min = 0,
	max = 20,
	step = 1,
	jump = 5,
	description = "Degradation is done by reducing the condition of the weapon or armor by a percentage equal to this number times "..
		"the number of hits on the container, divided by the number of weapons and armor in that container."
}

page:createSlider{
	label = "Minimum Destruction Chance",
	variable = mwse.mcm:createTableVariable{
		id = "MinChance", 
		table = config
	},
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	description = "This is the minimum chance that a non-degradable item is destroyed entirely. Each hit on the container increases it, up to the maximum. "..
		"This chance applies to each item in the container, up to the maximum amount of items you can lose. "..
		"It also ignores potions, ingredients, and arrows (see below)."
}

page:createSlider{
	label = "Maximum Destruction Chance",
	variable = mwse.mcm:createTableVariable{
		id = "MaxChance", 
		table = config
	},
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	description = "This is the maximum chance that a non-degradable item is destroyed entirely."
}

page:createSlider{
	label = "Constant Chance for Stackaphiles",
	variable = mwse.mcm:createTableVariable{
		id = "ConstChance", 
		table = config
	},
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	description = "Potions, arrows, and ingredients have a constant chance to be destroyed. Said chance is a percent equal to this number divided by the stack count."
}

page:createSlider{
	label = "Maximum Item Loss",
	variable = mwse.mcm:createTableVariable{
		id = "MaxItems", 
		table = config
	},
	min = 1,
	max = 20,
	step = 1,
	jump = 5,
	description = "This is the maximum number of items which can entirely break in a container. "..
		"For potions ingredients, and arrows, any number of losses from one stack count as one item."
}


mwse.mcm.register(template)