local strings = {}

strings.createdPotion = "Created Potion"
strings.effectFilter = "Effect Filter"
strings.effectLearned = "You learned a new effect"

strings.mcm = {
	modName = "Alchemical Knowledge",
	
	modEnabled = "Mod Status",
	modEnabledDesc = "Enabling and disabling the mod and all its functionality",
	
	gmstValue = "Skill Requirement",
	gmstValueDesc = "Alchemy Skill level that is required to see the next effect of the ingredient. The changes are applied on load, directly modifing the relevant GMST. Increase this value if you want to make the mechanic of finding out ingredient effects through experements more relevant",
	
	settings  = "Settings",
	nonEdible = "Inedible Ingredients",
	nonEdibleDesc = "Ingredients that can't be directly consumed via equipping. By default includes minerals and metals from vanilla and OAAB",
}

return strings
