local config = require("TimelyEscape.config")

local template = mwse.mcm.createTemplate("Timely Escape")
template.headerImagePath = "MWSE/mods/TimelyEscape/Timely Escape Small Header.tga"
template:saveOnClose("TimelyEscape", config)

local numPickMax
local function getNumPickMax()
	if (config.skill == true) then
		return table.size(tes3.skill)
	else
		return table.size(tes3.attribute)
	end
end

local page = template:createSideBarPage()
page.label = "General Settings"
page.description = "Timely Escape, v1.1.3\nby JaceyS"
page.noScroll = false

local category = page

local enableButton = category:createYesNoButton()
enableButton.label = "Enable"
enableButton.description = "Toggle to turn this mod on and off."
enableButton.variable = mwse.mcm:createTableVariable{id = "enable", table = config}

local teleportOptionDropdown = category:createDropdown()
teleportOptionDropdown.label = "Teleport Option"
teleportOptionDropdown.description = "Choose whether you would like Almsivi Intervention, Divine Intervention, or teleportation to the Shrine of Azura."
teleportOptionDropdown.options = {
	{label = "Almsivi Intervention", value = "almsivi"},
	{label = "Divine Intervention", value = "divine"},
	{label = "Shrine of Azura", value = "azura"}
}
teleportOptionDropdown.variable = mwse.mcm:createTableVariable{id = "teleportOption", table = config}

--[[
local azuraButton = category:createYesNoButton({
	label = "Azura",
	description = "Instead of casting Divine Intervention or Almsivi Intervention, teleport the player to the Shrine of Azura.",
	variable = mwse.mcm:createTableVariable{id = "azura", table = config}
})

local almsiviButton = category:createYesNoButton({
	label = "Almsivi Intervention",
	description = "Instead of casting Divine Intervention, cast Almsivi Intervention.",
	variable = mwse.mcm:createTableVariable{id = "almsivi", table = config}
})
]]
local restoreHealthButton = category:createYesNoButton({
	label = "Restore Health",
	description = "After intervention, you are fully healed. Helpful to avoid dying again right away, especially if using Naked and Alone.",
	variable = mwse.mcm:createTableVariable{id = "restoreHealth", table = config}
})

local messageBoxButton = category:createYesNoButton({
	label = "Message Box",
	description = "Show a message box with some flavor text and the notification that your stats have been lowered.",
	variable = mwse.mcm:createTableVariable{id = "messageBox", table = config}
})

local voiceButton = category:createYesNoButton({
	label = "Voice",
	description = "Plays a voice clip after your escape.",
	variable = mwse.mcm:createTableVariable{id = "voice", table = config}
})

local confirmationButton = category:createYesNoButton({
	label = "Confirmation",
	description = "Asks if you want to accept the Intervention before proceeding.",
	variable = mwse.mcm:createTableVariable{id = "confirmation", table = config}
})

local deathAnimationButton = category:createYesNoButton({
	label = "Death Animation",
	description = "Mimics the vanilla death behavior before intervening.",
	variable = mwse.mcm:createTableVariable{id = "deathAnimation", table = config}
})

local naturalButton = category:createYesNoButton({
	label = "Natural Intervention",
	description = "Blocks the spell sounds, adds a delay between escape and wake up, and changes the message to say you were found by a traveller.",
	variable = mwse.mcm:createTableVariable{id = "natural", table = config}
})

local recoveryTimeSlider = category:createSlider({
	label = "Recovery Time",
	description = "If using the Natural setting, how many days you wake up after being left for dead. Higher numbers incur a longer wait on the fadeout, to advance the time.",
	min = 1,
	max = 7,
	variable = mwse.mcm:createTableVariable{id = "recoveryTime", table = config}
})

local penaltyPage = template:createSideBarPage()
penaltyPage.label = "Penalty Settings"

--[[local skillButton = penaltyPage:createYesNoButton({
	label = "Penalize Skill",
	description = "Instead of penalizing attributes, penalizes skills.",
	variable = mwse.mcm:createTableVariable{id = "skill", table = config}
})]]

local penaltyOptionsDropdown = penaltyPage:createDropdown({
	label = "Penalty Options",
	description = "Apply the penalty to attributes, skills, or just to Endurance, or Luck",
	options = {
		{label = "Skills", value = "skills", description = "Apply penalty to skills."},
		{label = "Attributes", value = "attributes", description = "Apply penalty to attributes."},
		{label = "Endurance Only", value = "endurance", description = "Apply penalty to just Endurance."},
		{label = "Luck Only", value = "luck", description = "Apply penalty to just Luck."}
	},
	variable = mwse.mcm:createTableVariable{id = "penaltyOptions", table = config}
})

local attributeDependentSurvival = penaltyPage:createDropdown({
	label = "Attribute Dependent Survival",
	description = "Whether or not you survive past your death is dependent on one of your attributes.",
	options = {
		{label = "Disabled", value = false, description = "Attribute Dependent Surival is disabled. You always survive."},
		{label = "Endurance - Percentage", value = "endurancePercentage", description = "Your Endurance out of 100 is the percent liklihood that you will survive."},
		{label = "Endurance - Binary", value = "enduranceBinary", description = "You will surive, so long as your Endurance is greater than zero."},
		{label = "Luck - Percentage", value = "luckPercentage", description = "Your Luck out of 100 is the percent liklihood that you will survive."},
		{label = "Luck - Binary", value = "luckBinary", description = "You will surive, so long as your Luck is greater than zero."}
	},
	variable = mwse.mcm:createTableVariable{id = "attributeDependentSurival", table = config}
})
--[[local luckBinaryButton = penaltyPage:createYesNoButton({
	label = "Luck - Binary",
	description = "Check to see if the Luck attribute is zero, and if it is, block the escape.",
	variable = mwse.mcm:createTableVariable{id = "luckBinary", table = config}
})

local enduranceBinaryButton = penaltyPage:createYesNoButton({
	label = "Endurance - Binary",
	description = "Check to see if the Endurance attribute is zero, and if it is, block the escape.",
	variable = mwse.mcm:createTableVariable{id = "enduranceBinary", table = config}
})

local luckPercentageButton = penaltyPage:createYesNoButton({
	label = "Luck - Percentage",
	description = "Your luck attribute is the percent liklihood that you will be rescued. Overrides Luck - Binary.",
	variable = mwse.mcm:createTableVariable{id = "luckPercentage", table = config}
})

local endurancePercentageButton = penaltyPage:createYesNoButton({
	label = "Endurance - Percentage",
	description = "Your endurance attribute is the percent liklihood that you will be rescued. Overrides Endurance - Binary.",
	variable = mwse.mcm:createTableVariable{id = "endurancePercentage", table = config}
})

local luckPenaltyButton = penaltyPage:createYesNoButton({
	label = "Penalize Luck Only",
	description = "Instead of decrementing all of your attributes, only reduce the luck attribute by the Attribute Penalty value. Works well with Luck - Binary or Luck - Percentage.",
	variable = mwse.mcm:createTableVariable{id = "luckPenalty", table = config}
})

local endurancePenaltyButton = penaltyPage:createYesNoButton({
	label = "Penalize Endurance Only",
	description = "Instead of decrementing all of your attributes, only reduce the Endurance attribute by the Attribute Penalty value. Works well with Endurance - Binary or Endurance - Percentage.",
	variable = mwse.mcm:createTableVariable{id = "endurancePenalty", table = config}
})
]]

local statPenaltySlider = penaltyPage:createSlider({
	label = "Stat Penalty",
	description = "How much each of your stats is lowered by after your escape. Set to 0 for no penalty.",
	variable = mwse.mcm:createTableVariable{id = "statPenalty", table = config}
})

local randomCategory = penaltyPage:createCategory()
randomCategory.label = "Randomization Settings"
local randomPickButton = randomCategory:createYesNoButton({
	label = "Random Pick",
	description = "Randomly chooses a number of stats (skill or attribute, depending on other options) to decrease by the desired amount.",
	variable = mwse.mcm:createTableVariable{id = "randomPick", table = config}
})

local preventDoublePickButton = randomCategory:createYesNoButton({
	label = "Prevent Double Pick",
	description = "Prevents the random pick option from choosing the same stat to be reduced multiple times in a single escape. Can cause slowdown if numberToPick is high relative to the number of attributes/skills.",
	variable = mwse.mcm:createTableVariable{id = "preventDoublePick", table = config}
})

local numberToPickTextField = randomCategory:createTextField({
	numbersOnly = true,
	label = "Number To Pick",
	description = "Number of random stats to reduce. In the default game, there are 8 attributes, and 27 skills. Please put in only positive integers!",
	variable = mwse.mcm:createTableVariable{id = "numberToPick", table = config}
})

mwse.mcm.register(template)