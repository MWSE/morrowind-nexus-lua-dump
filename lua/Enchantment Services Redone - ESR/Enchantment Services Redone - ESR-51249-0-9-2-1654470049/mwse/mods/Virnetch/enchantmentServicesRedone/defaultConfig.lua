return {
	modEnabled = true,
	showTooltips = true,

	changePassiveRecharge = true,
	passiveRecharge = 0,

	itemAdditions = {
		blankScrolls = {
			enabled = true,
			frequency = 4,
			barterers = {},
			classPattern = {
				"enchant",
				"book"
			}
		}
	},
	dispositionFactor = 10,
	logLevel = "INFO",

	deciphering = {
		enableService = true,
		costMult = 100,
		enableChance = true,
		chanceRequired = 120,
		npcLearns = false,
		showSourceInTooltip = true,
		sourceTextToShowInTooltip = "oneLine",
		offerers = {}
	},
	transcription = {
		enable = true,
		requireScroll = true,
		requireSoulGem = true,
		enableService = true,
		costMult = 100,
		enableChance = true,
		chanceRequired = 60,
		enablePlayer = true,
		playerChanceMult = 100,
		experienceMult = 100,
		customName = false,
		showOriginalText = true,
		preventScripted = true,
		offerers = {}
	},
	recharge = {
		enableService = true,
		costMult = 100,
		enableChance = false,
		chanceRequired = 70,
		offerers = {}
	}
}