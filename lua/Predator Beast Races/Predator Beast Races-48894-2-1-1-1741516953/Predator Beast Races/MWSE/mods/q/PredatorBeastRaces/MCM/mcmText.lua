return {
	sideBarDefault =
	[[

	Welcome to Predator Beast Races!

	]],

	damageFormula = (
		"Claw Damage Formula:\n"..

		"Health damage per attack\n\n"..

		" =  clawBaseDmg + 0.01 x ( H2hMod x HandtoHand + StrMod x Strength )\n\n"..

		"In addition, the final damage is modified by clawRaceMod, which is specific for each of the beast races, "..
		"and can't be modified.\n"
	),

	clawBaseDamageDescription = (
		"\nThis is minimal amount of damage which will be done by attacking with claws, "..
		"on a theoretical character with Strength at 0 and Hand to hand skill at 0."
	),

	clawH2hModDescription = (
		"\nThis is a factor which determines how claws damage scales with Hand to hand skill."
	),

	clawStrengthModDescription = (
		"\nThis is a factor which determines how claws damage scales with Strength attribute."
	),

	clawApplyDifficultyDecription = (
		"\nHaving this setting on will make health damage done by beast claws "..
		"scale with currently selected difficulty. Just as any other weapon."
	),

	messagesDescription = (
		"\nThese messages give the player some feedback from the state of his/hers Scent and/or "..
		"Vision abilities. For example, Khajiiti can't use their Scent ability underwater."
	),

	scentHotkeyDescription = (
		"\nThis button can be used to toggle Argonan or Khajiiti Scent ability on or off."
	),

	visionHotkeyDescription = (
		"\nThis button can be used to toggle Khajiiti Vision ability on or off."
	),

	scentFatigueConsumption = (
		"\nHow much fatigue active Scent ability drains per second.\n\n"..

		"Note: your fatigue bar might apear static (as it isn't being used). That can happen with "..
		"certain attribute score since, your fatigue also regenerates (by itself)."
	),

	visionFatigueConsumption = (
		"\nHow much fatigue active Vision ability drains per second.\n\n"..

		"Note: your fatigue bar might apear static (as it isn't being used). That can happen with "..
		"certain attribute score since, your fatigue also regenerates (by itself)."
	),

	lowFatigue = (
		"\nThis is the lowest percentage of your maximum fatigue the active abilities will drain. "..
		"So, if your fatigue goes any lower then set treshold, any of your active abilities will "..
		"be stopped."
	),
}
