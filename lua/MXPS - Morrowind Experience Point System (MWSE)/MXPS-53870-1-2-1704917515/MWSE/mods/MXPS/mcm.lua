local i18n = mwse.loadTranslations('MXPS')
local config = require('MXPS.config')

local template = mwse.mcm.createTemplate('MXPS')
template:saveOnClose('MXPS', config)

local page = template:createSideBarPage()
page.label = i18n('mcmSetings')
page.description = (i18n('mcmAbout'))
page.noScroll = false

local category = page:createCategory("Settings")

local key = category:createKeyBinder {
    label = i18n('mcmtypeBindLabel'),
    description = i18n('mcmtypeBindDes'),
    variable = mwse.mcm.createTableVariable {id = 'key', table = config},
    allowCombinations = false,
}

local BlockVanillaProgress = category:createOnOffButton({
	label = i18n('mcmBlockVanillaProgressLabel'),
	description = i18n('mcmBlockVanillaProgressDes'),
	variable = mwse.mcm:createTableVariable{id = 'BlockVanillaProgress', table = config}
})

local QuestXP = category:createOnOffButton({
	label = i18n('mcmQuestXPLabel'),
	description = i18n('mcmQuestXPDes'),
	variable = mwse.mcm:createTableVariable{id = 'QuestXP', table = config}
})

local QuestRate = category:createSlider({
	label = i18n('mcmQuestRateLabel'),
	description = i18n('mcmQuestRateDes'),
	min = 1,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = 'QuestRate', table = config },
})

local QuestMsg = category:createOnOffButton({
	label = i18n('mcmQuestMsgLabel'),
	description = i18n('mcmQuestMsgDes'),
	variable = mwse.mcm:createTableVariable{id = 'QuestMsg', table = config}
})

local KillXP = category:createOnOffButton({
	label = i18n('mcmKillXPLabel'),
	description = i18n('mcmKillXPDes'),
	variable = mwse.mcm:createTableVariable{id = 'KillXP', table = config}
})

local KillRate = category:createSlider({
	label = i18n('mcmKillRateLabel'),
	description = i18n('mcmKillRateDes'),
	min = 1,
	max = 10000,
	step = 1,
	jump = 100,
	variable = mwse.mcm.createTableVariable{id = 'KillRate', table = config },
})

local KillMsg = category:createOnOffButton({
	label = i18n('mcmKillMsgLabel'),
	description = i18n('mcmKillMsgDes'),
	variable = mwse.mcm:createTableVariable{id = 'KillMsg', table = config}
})

local ScrollMenu = category:createOnOffButton({
	label = i18n('mcmScrollMenuLabel'),
	description = i18n('mcmScrollMenuDes'),
	variable = mwse.mcm:createTableVariable{id = 'ScrollMenu', table = config}
})

mwse.mcm.register(template)