local defaultConfig = {

	advanceTimeEnchantSuccess = true,
	advanceTimeEnchantFail = true,
	advanceTimeNPCenchant = true,
	advanceTimeRecharge = true,
	advanceTimeRepairAttempt = true,
	advanceTimeNPCrepair = true,
	advanceTimePotionSuccess = true,
	advanceTimePotionFail = true,
	advanceTimeBarter = true,
	advanceTimeNPCspellmaker = true,
	advanceTimeNPCspell = true,
	enchantSuccess_Modifier = 50,
	enchantFail_Modifier = 25,
	enchantNPC_Modifier = 40,
	recharge_Modifier = 5,
	repairAttempt_Modifier = 3,
	repairNPC_Modifier = 3,
	potionSuccess_Modifier = 10,
	potionFail_Modifier = 10,
	npcSpellTime_Modifier = 60,
	spellNPC_Modifier = 10,
	debugMode = false

}

local mwseConfig = mwse.loadConfig("Time Consumer", defaultConfig)

return mwseConfig;
