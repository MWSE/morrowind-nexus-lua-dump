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
	max = 1000,
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

local page2 = template:createSideBarPage()
page2.label = i18n('mcmSetings2')
page2.description = (i18n('mcmAboutRate'))
page2.noScroll = false

local category2 = page2:createCategory('Skills')

local SkillBlockRate = category2:createSlider({
	label = tes3.findGMST('sSkillBlock').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillBlockRate', table = config },
})

local SkillArmorerRate = category2:createSlider({
	label = tes3.findGMST('sSkillArmorer').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillArmorerRate', table = config },
})

local SkillMediumarmorRate = category2:createSlider({
	label = tes3.findGMST('sSkillMediumarmor').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillMediumarmorRate', table = config },
})

local SkillHeavyarmorRate = category2:createSlider({
	label = tes3.findGMST('sSkillHeavyarmor').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillHeavyarmorRate', table = config },
})

local SkillBluntweaponRate = category2:createSlider({
	label = tes3.findGMST('sSkillBluntweapon').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillBluntweaponRate', table = config },
})

local SkillLongbladeRate = category2:createSlider({
	label = tes3.findGMST('sSkillLongblade').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillLongbladeRate', table = config },
})

local SkillAxeRate = category2:createSlider({
	label = tes3.findGMST('sSkillAxe').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillAxeRate', table = config },
})

local SkillSpearRate = category2:createSlider({
	label = tes3.findGMST('sSkillSpear').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillSpearRate', table = config },
})

local SkillAthleticsRate = category2:createSlider({
	label = tes3.findGMST('sSkillAthletics').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillAthleticsRate', table = config },
})

local SkillEnchantRate = category2:createSlider({
	label = tes3.findGMST('sSkillEnchant').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillEnchantRate', table = config },
})

local SkillDestructionRate = category2:createSlider({
	label = tes3.findGMST('sSkillDestruction').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillDestructionRate', table = config },
})

local SkillAlterationRate = category2:createSlider({
	label = tes3.findGMST('sSkillAlteration').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillAlterationRate', table = config },
})

local SkillIllusionRate = category2:createSlider({
	label = tes3.findGMST('sSkillIllusion').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillIllusionRate', table = config },
})

local SkillConjurationRate = category2:createSlider({
	label = tes3.findGMST('sSkillConjuration').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillConjurationRate', table = config },
})

local SkillMysticismRate = category2:createSlider({
	label = tes3.findGMST('sSkillMysticism').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillMysticismRate', table = config },
})

local SkillRestorationRate = category2:createSlider({
	label = tes3.findGMST('sSkillRestoration').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillRestorationRate', table = config },
})

local SkillAlchemyRate = category2:createSlider({
	label = tes3.findGMST('sSkillAlchemy').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillAlchemyRate', table = config },
})

local SkillUnarmoredRate = category2:createSlider({
	label = tes3.findGMST('sSkillUnarmored').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillUnarmoredRate', table = config },
})

local SkillSecurityRate = category2:createSlider({
	label = tes3.findGMST('sSkillSecurity').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillSecurityRate', table = config },
})

local SkillSneakRate = category2:createSlider({
	label = tes3.findGMST('sSkillSneak').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillSneakRate', table = config },
})

local SkillAcrobaticsRate = category2:createSlider({
	label = tes3.findGMST('sSkillAcrobatics').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillAcrobaticsRate', table = config },
})

local SkillLightarmorRate = category2:createSlider({
	label = tes3.findGMST('sSkillLightarmor').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillLightarmorRate', table = config },
})

local SkillShortbladeRate = category2:createSlider({
	label = tes3.findGMST('sSkillShortblade').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillShortbladeRate', table = config },
})

local SkillMarksmanRate = category2:createSlider({
	label = tes3.findGMST('sSkillMarksman').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillMarksmanRate', table = config },
})

local SkillMercantileRate = category2:createSlider({
	label = tes3.findGMST('sSkillMercantile').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillMercantileRate', table = config },
})

local SkillSpeechcraftRate = category2:createSlider({
	label = tes3.findGMST('sSkillSpeechcraft').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillSpeechcraftRate', table = config },
})

local SkillHandtohandRate = category2:createSlider({
	label = tes3.findGMST('sSkillHandtohand').value,
	min = 0.000,
	max = 10.000,
	step = 0.001,
	jump = 0.01,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable{id = 'SkillHandtohandRate', table = config },
})

mwse.mcm.register(template)