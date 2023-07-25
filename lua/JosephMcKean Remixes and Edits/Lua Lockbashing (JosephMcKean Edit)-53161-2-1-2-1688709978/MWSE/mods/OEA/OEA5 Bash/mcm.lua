local config = require("OEA.OEA5 Bash.config")

local template = mwse.mcm.createTemplate({ name = "Lua Lockbashing" })
template:saveOnClose("Lua_Lockbashing", config)

local sidebarDefault = "Lua Lockbashing\n\n" .. "original by OEA\n\n" .. "edited by JosephMcKean\n\n" ..
                       "These options allow you to adjust aspects of the new item loss feature, and if you even want it at all, along with " ..
                       "some other settings, such as how you want lock tooltips to be handled."

local page = template:createSideBarPage{ description = sidebarDefault }

page:createTextField{
	label = "Strength Multiplier",
	variable = mwse.mcm:createTableVariable{ id = "OldMult", table = config },
	numbersOnly = true,
	description = "When lock bashing, your weapons degrade by an amount equal to your strength times this number. If you use fists, your hand-to-hand skill instead " ..
	"is damaged by an amount equal to your strength divided by 10, rounded down. In Greatness7's original mod, the value of this multiplier was 3, however " ..
	"you can change it to whatever you like.",
}

page:createYesNoButton{
	label = "Should you be able to bash with fists?",
	variable = mwse.mcm:createTableVariable{ id = "Hand", table = config },
	description = "With this, you are able to bash a lock even without a weapon, by using unarmed attacks. Your chances are much worse, " ..
	"and instead of weapon condition your Hand-to-Hand skill is indefinitely damaged. This feature was not a part " ..
	"of Greatness7's original mod, but it is on by default since it was a feature in Daggerfall.",
}

mwse.mcm.register(template)
