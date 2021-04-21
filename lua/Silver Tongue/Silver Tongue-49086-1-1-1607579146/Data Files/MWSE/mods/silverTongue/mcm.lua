local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("silverTongue.config")

local strings = {}

strings.modName = "Silver Tongue"
strings.settings = "Settings"
strings.modEnabled = "Mod Enabled"
strings.modEnabledDesc = "Enabling and disabling the mod and all its functionality"
strings.pauperBonus = "Pauper Bonus"
strings.pauperBonusDesc = "Makes paupers more receptive to bribery. The higher the value the easier it is to bribe a pauper"
strings.guardPenalty = "Guard Penalty"
strings.guardPenaltyDesc = "Makes guards less receptive to bribery. The higher the value the harder it is to bribe a guard"
strings.showDisposition = "Show Disposition" 
strings.showDispositionDesc = "Speechcraft skill level from which the player will see the Disposition bar in the dialogue menu"
strings.showFight = "Show Fight" 
strings.showFightDesc = "Speechcraft skill level from which the player will see the Fight bar in the dialogue menu"
strings.showAlarm = "Show Alarm" 
strings.showAlarmDesc = "Speechcraft skill level from which the player will see the Alarm bar in the dialogue menu"
strings.allowAdmire = "Allow Admire" 
strings.showAlarmDesc = "Speechcraft skill level from which the player will be able to use Admire persuasion option"
strings.allowIntimidate = "Allow Intimidate" 
strings.showIntimidateDesc = "Speechcraft skill level from which the player will be able to use Intimidate persuasion option"
strings.allowTaunt = "Allow Taunt" 
strings.showTauntDesc = "Speechcraft skill level from which the player will be able to use Taunt persuasion option"
strings.bribeDecreasesAlarm = "Bribe Decreases Alarm"
strings.bribeDecreasesAlarmDesc = "Speechcraft skill level from which a successful bribe will decrease the Alarm of the npc"
strings.combatTalk = "Talk in Combat"
strings.combatTalkDesc = "Speechcraft skill level from which the player will be able to start conversations with hostile and fleeing npcs"

local template = EasyMCM.createTemplate(strings.modName)
template:saveOnClose(strings.modName, config)
template:register()

local page = template:createSideBarPage({
  label = strings.settings,
})
local settings = page:createCategory(strings.settings)

settings:createOnOffButton({
  label = strings.modEnabled,
  description = strings.modEnabledDesc,
  variable = EasyMCM.createTableVariable {
    id = "modEnabled",
    table = config
  }
})

settings:createSlider{
	label = strings.pauperBonus,
	description = strings.pauperBonusDesc,
	min = 0,
	max = 70,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "pauperBonus",
		table = config
	}
}

settings:createSlider{
	label = strings.guardPenalty,
	description = strings.guardPenaltyDesc,
	min = 0,
	max = 35,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "guardPenalty",
		table = config
	}
}

settings:createSlider{
	label = strings.showDisposition,
	description = strings.showDispositionDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "showDisposition",
		table = config
	}
}

settings:createSlider{
	label = strings.showFight,
	description = strings.showFightDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "showFight",
		table = config
	}
}

settings:createSlider{
	label = strings.showAlarm,
	description = strings.showAlarmDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "showAlarm",
		table = config
	}
}

settings:createSlider{
	label = strings.allowAdmire,
	description = strings.allowAdmireDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "allowAdmire",
		table = config
	}
}

settings:createSlider{
	label = strings.allowIntimidate,
	description = strings.allowIntimidateDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "allowIntimidate",
		table = config
	}
}

settings:createSlider{
	label = strings.allowTaunt,
	description = strings.allowTauntDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "allowTaunt",
		table = config
	}
}

settings:createSlider{
	label = strings.bribeDecreasesAlarm,
	description = strings.bribeDecreasesAlarmDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "bribeDecreasesAlarm",
		table = config
	}
}

settings:createSlider{
	label = strings.combatTalk,
	description = strings.combatTalkDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "combatTalk",
		table = config
	}
}
