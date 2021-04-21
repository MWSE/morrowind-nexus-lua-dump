local defaultConfig = {
	enable = true,
	teleportOption = "almsivi",
	statPenalty = 1,
	messageBox = true,
	voice = true,
	damagingEffectIDs = {
		tes3.effect.fireDamage,
		tes3.effect.shockDamage,
		tes3.effect.frostDamage,
		tes3.effect.drainHealth,
		tes3.effect.damageHealth,
		tes3.effect.poison,
		tes3.effect.absorbHealth,
		tes3.effect.sunDamage
	},
	penaltyOptions = "skills",
	attributeDependentSurival = false,
	confirmation = true,
	deathAnimation = true,
	skill = true,
	randomPick = true,
	preventDoublePick = true,
	numberToPick = 5,
	natural = false,
	recoveryTime = 1,
	restoreHealth = true,
	deathAnimations = {
		tes3.animationGroup.death1,
		tes3.animationGroup.death2,
		tes3.animationGroup.death3,
		tes3.animationGroup.death4,
		tes3.animationGroup.death5,
	}
}

local config = mwse.loadConfig ("TimelyEscape", defaultConfig)
return config