local defaultConfig = {
	enable = true,
	version = "v1.4",
	damagingEffectIDs = {
		tes3.effect.fireDamage,
		tes3.effect.shockDamage,
		tes3.effect.frostDamage,
		tes3.effect.drainHealth,
		tes3.effect.damageHealth,
		tes3.effect.poison,
		tes3.effect.paralize,
		tes3.effect.silence,
		tes3.effect.blind,
		tes3.effect.absorbHealth,
		tes3.effect.sunDamage
	},
	confirmation = true,
	saveBeforeDeath = true,
	itemDropProbability = 50,
	itemWorsenConditionProbability = 50,
	deathAnimation = false,
	recoveryTime = 1,
	reportLostItems = true,
	deathAnimations = {
		tes3.animationGroup.death1,
		tes3.animationGroup.death2,
		tes3.animationGroup.death3,
		tes3.animationGroup.death4,
		tes3.animationGroup.death5,
	},
	invisibilityDuration = 15,
	chameleonDuration = 0,
	chameleonMagnitude = 50
}

local config = mwse.loadConfig ("ZdoImmersiveDeath", defaultConfig)
return config