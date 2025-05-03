local common = require("tamrielData.common")

local defaultConfig = {
	summoningSpells = true,
	boundSpells = true,
	interventionSpells = true,
	miscSpells = true,
	passwallAlteration = false,
	overwriteMagickaExpanded = true,
	provincialReputation = true,
	provincialFactionUI = true,
	weatherChanges = true,
	hats = true,
	creatureBehaviors = true,
	fixPlayerRaceAnimations = true,
	restrictEquipment = true,
	fixVampireHeads = true,
	improveItemSounds = true,
	adjustTravelPrices = true,
	khajiitFormCharCreation = false, -- tes3.dataHandler.nonDynamicData:getGameFile("All Races and Classes Unlocked - Vanilla and Tamriel_Data.ESP") or tes3.dataHandler.nonDynamicData:getGameFile("TD Races.ESP"),	-- dataHandler is not available when it is needed here
	butterflyMothTooltip = common.gh_config and common.gh_config.showTooltips,
	limitIntervention = false
}

return mwse.loadConfig("tamrielData", defaultConfig)