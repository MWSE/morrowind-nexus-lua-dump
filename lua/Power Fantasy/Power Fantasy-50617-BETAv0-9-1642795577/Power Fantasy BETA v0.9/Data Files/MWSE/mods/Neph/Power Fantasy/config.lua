local common = require("Neph.Power Fantasy.common")

local function saveConfig()
	mwse.saveConfig("Power Fantasy", common.config)
end

local function registerModConfig()

	local template = mwse.mcm.createTemplate("Power Fantasy")
	template:saveOnClose("Power Fantasy", common.config)
	template:register()
	
	local var = mwse.mcm.createTableVariable
	local page = template:createSideBarPage()
	
	page.sidebar:createInfo{
		text = "by Neph"
			.. "\n\nExtensive gameplay overhaul. Extra modules come with lots of additions to races, birthsigns and skills."
			.. "\n\nHover over individual settings for more information."
	}
	
	page:createOnOffButton{
		label = "NPC Dashing",
		description = "Toggle On/Off.",
		variable = var{
			id = "NPCdash",
			table = common.config
		}
	}
	
	page:createOnOffButton{
		label = "Wiggly Spell Projectiles",
		description = "Toggle On/Off.\n\nMakes hitting with targeted spells from far away harder at low Willpower."
					.. " Tip: Use area spells to increase your odds to hit.\n\nRequires game restart.",
		variable = var{
			id = "spellProjWiggle",
			table = common.config
		},
		restartRequired = true
	}
	
	page:createOnOffButton{
		label = "Creature Perks",
		description = "Toggle On/Off."
					.. "\n\nIncludes creature pseudo armor and extra spells."
					.. "\n\nThese additions were originally meant as a measure to even out the combat performance of creatures"
					.. " against the various new NPC perks added by optional modules. Although it might not hurt"
					.. " to keep them On when playing without the optional modules, they can be deactivated here, if needed."
					.. "\n\nNote, that when toggling this setting Off, currently loaded creatures may still have access to formerly added spells."
					.. "\n\nRequires game restart.",
		variable = var{
			id = "creaPerks",
			table = common.config
		},
		restartRequired = true
	}
	
	page:createOnOffButton{
		label = "Critical Hit Sound",
		description = "Toggle On/Off.",
		variable = var{
			id = "critSound",
			table = common.config
		}
	}
	
	page:createOnOffButton{
		label = "Expert Perk Messages",
		description = "Toggle On/Off.\n\nOnly relevant, if the Skills module is active.",
		variable = var{
			id = "comboMsg",
			table = common.config
		}
	}
	
	page:createOnOffButton{
		label = "NPC Power Messages",
		description = "Toggle On/Off.\n\nOnly relevant, if the the Races & Birthsigns module is active.",
		variable = var{
			id = "NPCpowerMsg",
			table = common.config
		}
	}
	
	page:createSlider{
		label = "Knockdown GMSTs: %s",
		description = "Sets all knockdown-related GMSTs at once:\n\nfKnockDownMult\niKnockDownOddsBase\niKnockDownOddsMult"
					.. "\n\nThe higher this value, the lower the odds of staggering."
					.. "\n\nPower Fantasy's default value is 100 to adjust for extra knockdown effects of the skills module."
					.. "\n\nWhen playing without the skills module, this should be set to the vanilla default of 50."
					.. "\n\nRequires game restart.",
		min = 50,
		max = 100,
		step = 1,
		jump = 10,
		variable = var{
			id = "knockdownVars",
			table = common.config
		},
		restartRequired = true
	}
	
	page:createSlider{
		label = "Knockdown Limit: %s secs",
		description = "Time until an NPC (incl. player) can be knocked down again. Also, if an actor is knocked out due to fatigue loss,"
					.." their fatigue can't be damaged by external sources for the same duration. Default: 6 secs.",
		min = 3,
		max = 12,
		step = 1,
		jump = 2,
		variable = var{
			id = "knockDownLimit",
			table = common.config
		}
	}
	
	page:createKeyBinder{
		label = "Dash Key",
		description = "Keybind for dashing/dodging. Combinations allowed.",
		variable = var{
			id = "dashKey",
			table = common.config
		},
		allowCombinations = true
	}
end
event.register("modConfigReady", registerModConfig)