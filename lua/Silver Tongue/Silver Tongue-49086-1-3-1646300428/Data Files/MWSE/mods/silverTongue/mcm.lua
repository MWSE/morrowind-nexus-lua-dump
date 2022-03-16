local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("silverTongue.config")

local function loadTranslation()
	-- Get the ISO language code.
	local language = tes3.getLanguage()

	-- Load the dictionaries, and start off with English.
	local dictionaries = dofile("silverTongue.translations")
	local dictionary = dictionaries[language]

	-- If we aren't doing English, copy over missing entries.
	if (language ~= "eng") then
		table.copymissing(dictionary, dictionaries["eng"])
	end
	-- Set the dictionary.
	return dictionary
end

local strings = loadTranslation()

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
