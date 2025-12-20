local config = require("SmoothTalker.config")

local function registerModConfig()
	local template = mwse.mcm.createTemplate("Smooth Talker")
	template:saveOnClose("SmoothTalker", config)
	template:register()

	-- Main page
	local page = template:createSideBarPage({
		label = "Settings",
	})

	-- ========================================================================
	-- DIFFICULTY
	-- ========================================================================
	local difficultySettings = page:createCategory("Difficulty")

	difficultySettings:createSlider{
		label = "Difficulty Modifier",
		description = "Adjusts the overall difficulty of persuasion attempts.\n\nNegative values make persuasion easier, positive values make it harder.",
		min = -10,
		max = 10,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable{
			id = "difficultyModifier",
			table = config
		}
	}

	-- ========================================================================
	-- PATIENCE SYSTEM
	-- ========================================================================
	local patienceSettings = page:createCategory("Patience System")

	patienceSettings:createSlider{
		label = "Patience Regeneration Time (Hours)",
		description = "Number of in-game hours required for NPC patience to fully regenerate",
		min = 1,
		max = 240,
		step = 1,
		jump = 24,
		variable = mwse.mcm.createTableVariable{
			id = "patienceRegenHours",
			table = config
		}
	}

	-- ========================================================================
	-- VANILLA BAR VISIBILITY
	-- ========================================================================
	local vanillaBarSettings = page:createCategory("Vanilla Dialogue Bars")

	vanillaBarSettings:createOnOffButton{
		label = "Show Patience Bar",
		description = "Display patience bar in vanilla dialogue window (when unlocked)",
		variable = mwse.mcm.createTableVariable{
			id = "showVanillaBarPatience",
			table = config
		}
	}

	vanillaBarSettings:createOnOffButton{
		label = "Show Fight Bar",
		description = "Display fight bar in vanilla dialogue window (when unlocked)",
		variable = mwse.mcm.createTableVariable{
			id = "showVanillaBarFight",
			table = config
		}
	}

	vanillaBarSettings:createOnOffButton{
		label = "Show Alarm Bar",
		description = "Display alarm bar in vanilla dialogue window (when unlocked)",
		variable = mwse.mcm.createTableVariable{
			id = "showVanillaBarAlarm",
			table = config
		}
	}

	vanillaBarSettings:createOnOffButton{
		label = "Show Flee Bar",
		description = "Display flee bar in vanilla dialogue window (when unlocked)",
		variable = mwse.mcm.createTableVariable{
			id = "showVanillaBarFlee",
			table = config
		}
	}

	-- ========================================================================
	-- XP GAIN SETTINGS
	-- ========================================================================
	local xpSettings = page:createCategory("Speechcraft XP Gain")

	xpSettings:createSlider{
		label = "Base XP (Success)",
		description = "Base XP awarded for successful persuasion attempts",
		min = 0,
		max = 5.0,
		step = 0.1,
		jump = 0.5,
		decimalPlaces = 1,
		variable = mwse.mcm.createTableVariable{
			id = "xpBase",
			table = config
		}
	}

	xpSettings:createSlider{
		label = "Difficulty Bonus XP",
		description = "XP bonus awarded per 10 difficulty points.\n\nHigher values reward succeeding at difficult persuasion attempts",
		min = 0,
		max = 5.0,
		step = 0.1,
		jump = 0.5,
		decimalPlaces = 1,
		variable = mwse.mcm.createTableVariable{
			id = "xpDifficultyBonus",
			table = config
		}
	}

	xpSettings:createSlider{
		label = "Failure XP",
		description = "XP awarded for failed persuasion attempts",
		min = 0,
		max = 5.0,
		step = 0.1,
		jump = 0.5,
		decimalPlaces = 1,
		variable = mwse.mcm.createTableVariable{
			id = "xpFailure",
			table = config
		}
	}

	-- ========================================================================
	-- SUCCESS CHANCE LIMITS
	-- ========================================================================
	local chanceSettings = page:createCategory("Success Chance Limits")

	chanceSettings:createSlider{
		label = "Minimum Success Chance (%)",
		description = "Minimum possible success chance for any persuasion attempt",
		min = 0,
		max = 10,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable{
			id = "minSuccessChance",
			table = config
		}
	}

	chanceSettings:createSlider{
		label = "Maximum Success Chance (%)",
		description = "Maximum possible success chance for any persuasion attempt",
		min = 80,
		max = 100,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable{
			id = "maxSuccessChance",
			table = config
		}
	}

	-- ========================================================================
	-- BRIBE SETTINGS
	-- ========================================================================
	local brideSettings = page:createCategory("Bribe Settings")

	brideSettings:createSlider{
		label = "Maximum Bribe Effectiveness Bonus",
		description = "Maximum effectiveness bonus from bribe amount",
		min = 20,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "bribeMaxBonus",
			table = config
		}
	}

	brideSettings:createSlider{
		label = "Bribe Disposition Cap (Gold)",
		description = "Maximum bribe amount used for calculating disposition gain.\n\nBribes larger than this still cost the full amount, but disposition gain is capped.",
		min = 500,
		max = 10000,
		step = 100,
		jump = 500,
		variable = mwse.mcm.createTableVariable{
			id = "bribeEffectivenessCap",
			table = config
		}
	}

	-- ========================================================================
	-- UNLOCK THRESHOLDS
	-- ========================================================================
	local unlockSettings = page:createCategory("Unlock Thresholds")

	unlockSettings:createSlider{
		label = "Patience Status Bar",
		description = "Speechcraft level required to see NPC Patience level.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockStatusPatience",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Disposition Status Bar",
		description = "Speechcraft level required to see NPC Disposition level.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockStatusDisposition",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Fight Status Bar",
		description = "Speechcraft level required to see NPC Fight level.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockStatusFight",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Alarm Status Bar",
		description = "Speechcraft level required to see NPC Alarm level.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockStatusAlarm",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Flee Status Bar",
		description = "Speechcraft level required to see NPC Flee level.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockStatusFlee",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Approximate Success Chance",
		description = "Speechcraft level required to see approximate success chance (Easy/Medium/Hard/Very Hard).",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockSuccessChanceApproximate",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Exact Success Chance",
		description = "Speechcraft level required to see exact success chance percentage.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockSuccessChanceExact",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Admire Action",
		description = "Speechcraft level required to unlock the Admire action.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockActionAdmire",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Placate Action",
		description = "Speechcraft level required to unlock the Placate action.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockActionPlacate",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Intimidate Action",
		description = "Speechcraft level required to unlock the Intimidate action.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockActionIntimidate",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Taunt Action",
		description = "Speechcraft level required to unlock the Taunt action.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockActionTaunt",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Bond Action",
		description = "Speechcraft level required to unlock the Bond action.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockActionBond",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Bribe Reduces Alarm",
		description = "Speechcraft level required for successful bribes to also reduce Alarm.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockBribeReducesAlarm",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Reduced Patience Cost",
		description = "Speechcraft level required to reduce failure patience cost by 1.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockReducedPatienceCost",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Combat Persuasion",
		description = "Speechcraft level required to talk to NPCs during combat.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockCombatPersuasion",
			table = config
		}
	}

	unlockSettings:createSlider{
		label = "Permanent Effects",
		description = "Speechcraft level required for persuasion actions to have small permanent effects that don't decay over time.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "unlockPermanentEffects",
			table = config
		}
	}
end

event.register("modConfigReady", registerModConfig)
