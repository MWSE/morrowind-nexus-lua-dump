local defaultConfig = {
	-- Difficulty adjustment
	difficultyModifier = 0,

	-- Speechcraft XP gain settings
	xpBase = 0.4,
	xpDifficultyBonus = 0.3,
	xpFailure = 0.2,

	-- Success chance limits
	minSuccessChance = 0,
	maxSuccessChance = 100,

	-- Bribe settings
	bribeMaxBonus = 40,
	bribeEffectivenessCap = 2000,

	-- Patience system
	patienceRegenHours = 24,

	-- Decay system
	decayHours = 24,

	-- Vanilla bar visibility toggles
	showVanillaBarPatience = true,
	showVanillaBarFight = true,
	showVanillaBarAlarm = true,
	showVanillaBarFlee = true,

	-- Unlock thresholds (speechcraft skill levels)
	unlockStatusPatience = 10,
	unlockStatusDisposition = 15,
	unlockStatusFight = 30,
	unlockStatusAlarm = 40,
	unlockStatusFlee = 60,
	unlockSuccessChanceApproximate = 20,
	unlockSuccessChanceExact = 70,
	unlockActionAdmire = 10,
	unlockActionPlacate = 25,
	unlockActionIntimidate = 40,
	unlockActionTaunt = 50,
	unlockActionBond = 55,
	unlockBribeReducesAlarm = 60,
	unlockReducedPatienceCost = 70,
	unlockCombatPersuasion = 80,
	unlockPermanentEffects = 80
}

local mwseConfig = mwse.loadConfig("SmoothTalker", defaultConfig)

return mwseConfig
