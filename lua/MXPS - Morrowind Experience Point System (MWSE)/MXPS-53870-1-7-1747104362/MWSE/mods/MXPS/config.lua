local defaultConfig = {
	ScrollMenu = false,
	BlockVanillaProgress = true,
	QuestXP = true,
	QuestRate = 10,
	QuestMsg = true,
	KillXP = true,
	KillXPSource = 3,
	KillRate = 1000,
	KillMsg = true,
	key = {keyCode = tes3.scanCode['.']},
	SkillBlockRate = 1.000,
	SkillArmorerRate = 1.000,
	SkillMediumarmorRate = 1.000,
	SkillHeavyarmorRate = 1.000,
	SkillBluntweaponRate = 1.000,
	SkillLongbladeRate = 1.000,
	SkillAxeRate = 1.000,
	SkillSpearRate = 1.000,
	SkillAthleticsRate = 1.000,
	SkillEnchantRate = 1.000,
	SkillDestructionRate = 1.000,
	SkillAlterationRate = 1.000,
	SkillIllusionRate = 1.000,
	SkillConjurationRate = 1.000,
	SkillMysticismRate = 1.000,
	SkillRestorationRate = 1.000,
	SkillAlchemyRate = 1.000,
	SkillUnarmoredRate = 1.000,
	SkillSecurityRate = 1.000,
	SkillSneakRate = 1.000,
	SkillAcrobaticsRate = 1.000,
	SkillLightarmorRate = 1.000,
	SkillShortbladeRate = 1.000,
	SkillMarksmanRate = 1.000,
	SkillMercantileRate = 1.000,
	SkillSpeechcraftRate = 1.000,
	SkillHandtohandRate = 1.000,
}

local config = mwse.loadConfig('MXPS', defaultConfig)
return config