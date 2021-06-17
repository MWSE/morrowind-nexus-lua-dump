local EasyMCM = require("easyMCM.EasyMCM")
local config = mwse.loadConfig("diminishingSkillReturns")

local template = EasyMCM.createTemplate("Diminishing Skill Returns")
template:saveOnClose("diminishingSkillReturns", config)
template:register()

local page = template:createSideBarPage({
	label = "Settings",
})

local settings = page:createCategory{
	label = "Diminishing Skill Returns Settings",
	description = "Exercising a particular skill more than X times within [capture period] seconds will cause your skill XP gain rate in that skill to drop by half. If you keep exercising it, it will continue to halve every [capture period] seconds to a minimum of 1% normal skill XP gain rate. You can set values for each skill individually below.\n\nLower values are more strict, and \"seconds\" refer to real-life seconds, not in-game seconds.\n\nNote that Athletics and Sneak are excluded (zero value) by default, as they gain skill via continuous, second-by-second action such as running or evading detection."
}

settings:createSlider{
	label = "Capture period, in seconds",
	description = "By default the script will check for X uses of a particular skill within five seconds. You can make this more strict by increasing the time period. eg. It's easier to capture three uses of Acrobatics within ten seconds than it is to capture three uses within just five seconds. If you increase this, consider bumping up the values for each skill below to compensate.",
	min = 1,
	max = 30,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "fiveSeconds",
		table = config
	}
}

settings:createSlider{
	label = "Seconds for skill XP gains to double",
	description = "The rate at which your skill XP gains return to normal. Skill XP gain rate will double each time "..config.rateRecovery.." seconds go by during which you have NOT exercised a particular skill. To a maximum of 100%. This value should be as large or (preferably) greater than the capture period, or it's not really a tangible penalty.\n\nFor example if, after constantly jumping for some time, your Acrobatics skill XP gain rate is only 8% of normal, then if you allow "..config.rateRecovery.." seconds to go by WITHOUT jumping, your skill XP gain rate will recover to 16%. After "..config.rateRecovery.." more seconds pass without your character jumping, your Acrobatics skill XP gain rate will recover to 32%, then 64%, then back to 100%.\n\nWhen this value is larger than the capture period value, that means it takes more time for your skill XP gain rate to recover to 100% than it took to spam your way down to a low skill XP gain rate. With this mod there is no point in spamming skills to level, in fact it hurts to do so!",
	min = 1,
	max = 60,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "rateRecovery",
		table = config
	}
}

settings:createOnOffButton({
	label = "Display notifications",
	description = "Display a notification on screen when your skill XP gain rate has been reduced, just so you know the mod is working and when. If you're happy with it, probably turn this off later.",
	variable = EasyMCM.createTableVariable {
		id = "notifications",
		table = config
	}
})


local settings2 = page:createCategory{
	label = "Skill exercises per capture period",
  description = "Individual settings for each skill. Exercising a skill the set value of times within a capture period will cause your rate of skill XP gain to halve."
}

for i=0,26,1
do
	settings2:createSlider{
		label = tes3.getSkillName(i),
		description = "Exercising the "..tes3.getSkillName(i).." skill this many times within [capture period] seconds will immediately halve your skill XP gain rate in "..tes3.getSkillName(i)..". Continuing to exercise the "..tes3.getSkillName(i).." skill will continue to halve your skill XP gain rate every additional [capture period] seconds, to a minimum of 1%. Set to zero (0) to exclude this skill from the Diminishing Skill Returns effect.",
		min = 0,
		max = 60,
		step = 1,
		jump = 5,
		variable = EasyMCM.createTableVariable{
			id = tostring(i),
			table = config.fiveSecondRule
		}
	}
end
