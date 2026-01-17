--[[
    Persuasion Modifiers Module
    Contains all modifier tables and lookup functions for persuasion calculations
]]

local unlocks = require("SmoothTalker.unlocks")
local modifiers = {}

-- ============================================================================
-- INITIAL PATIENCE CALCULATION
-- ============================================================================

modifiers.initialPatienceMultipliers = {
	base = 5,
	disposition = 0.1,
	speechcraft = 0.1,
	personality = 0.05,
	reputation = 0.4,
	sameFaction = 5,
	minPatience = 5
}

-- ============================================================================
-- PLAYER EFFECTIVENESS MULTIPLIERS
-- Multipliers applied to player stats to calculate total "skill" for an action
-- ============================================================================

modifiers.admirePlayerMultipliers = {
	speechcraft = 0.60,
	personality = 0.15,
	luck = 0.08,
	reputation = 0.15
}

modifiers.intimidatePlayerMultipliers = {
	speechcraft = 0.40,
	reputation = 0.30,
	strength = 0.12,
	personality = 0.12,
	level = 1.0,
	luck = 0.08
}

modifiers.tauntPlayerMultipliers = {
	speechcraft = 0.60,
	personality = 0.12,
	luck = 0.08
}

modifiers.placatePlayerMultipliers = {
	speechcraft = 0.60,
	personality = 0.15,
	luck = 0.08
}

modifiers.bribePlayerMultipliers = {
	mercantile = 0.35,
	speechcraft = 0.35,
	personality = 0.15,
	luck = 0.05
}

modifiers.bondPlayerMultipliers = {
	speechcraft = 0.50,
	personality = 0.25,
	reputation = 0.20,
	luck = 0.08
}

-- ============================================================================
-- NPC DIFFICULTY MULTIPLIERS
-- Multipliers applied to NPC stats to calculate difficulty of an action
-- ============================================================================

modifiers.admireNPCMultipliers = {
	baseDifficulty = 10,
	dispositionMod = 0.10, -- Calculated from (50 - disposition)
	speechcraft = 0.30,
	personality = 0.15,
	level = 1.0,
	hostility = 25,
	factionRank = -3
}

modifiers.intimidateNPCMultipliers = {
	baseDifficulty = 5,
	dispositionMod = 0.10,
	speechcraft = 0.25,
	personality = 0.15,
	level = 3.0,
	hostility = 25
}

modifiers.tauntNPCMultipliers = {
	baseDifficulty = 25,
	dispositionMod = -0.10,  -- INVERSE
	speechcraft = 0.30,
	willpower = 0.15,
	level = 2,
	hostility = -25
}

modifiers.placateNPCMultipliers = {
	baseDifficulty = 10,
	dispositionMod = 0.30,
	speechcraft = 0.20,
	willpower = 0.20,
	fight = 0.25,
	level = 1.0,
	hostility = 25
}

modifiers.bribeNPCMultipliers = {
	baseDifficulty = 5,
	dispositionMod = 0.40,
	personality = 0.10,
	level = 1.0,
	hostility = 25
}

modifiers.bondNPCMultipliers = {
	baseDifficulty = 30,
	dispositionMod = 0.10, -- Calculated from (50 - disposition)
	speechcraft = 0.40,
	personality = 0.20,
	level = 1.5,
	hostility = 60,
	factionRank = -6
}

-- Bribe: Amount effectiveness multiplier
modifiers.bribeAmountMultiplier = 1.6
modifiers.bribeLimitingFactor = 10
modifiers.bribeLimitingDiv = 6

-- Gift: Item value to persuasion modifier
modifiers.giftItemValueMultiplier = 0.8

-- Gift: Illegal items (contraband)
modifiers.illegalItems = {
	"potion_skooma_01",
	"ingred_moon_sugar_01"
}

-- Gift: Classes and factions exempt from illegal bribe mechanics
-- These NPCs don't care about contraband and won't report crimes
modifiers.bribeExemptions = {
	classes = {
		"acrobat",
		"agent",
		"bard",
		"dreamers",
		"mabrigash",
		"necromancer",
		"smuggler",
		"thief",
		"thief service",
		"rogue",
		-- Tamriel Data
		"T_Glb_Courtesan",
	},
	factions = {
		"Thieves Guild",
		"Camonna Tong",
		"Ashlanders",
		"Clan Aundae",
		"Clan Berne",
		"Clan Quarra",
		"Dark Brotherhood",
		"Sixth House",
		"Telvanni",
		-- Tamriel Data
		"T_Cyr_DarkBrotherhood",
		"T_Cyr_ThievesGuild",
		"T_Glb_CourtesansGuild",
		"T_Mw_Clan_Baluath",
		"T_Mw_Clan_Orlukh",
		"T_Mw_JaNattaSyndicate",
		"T_Mw_ThievesGuild",
		"T_Sky_DarkBrotherhood",
		"T_Sky_ThievesGuild",
	}
}

-- ============================================================================
-- EFFECT MULTIPLIERS
-- Multipliers for calculating the effects of successful/failed persuasion
-- All relevant effects will be applied for an action. Structure:
-- 1. Action - admire, intimidate etc. Which action are we performing
-- 2. Result - success, failure - has it succeeded? (patience depleted attempt doesn't count as fail)
-- 3. Effects - all of the effects will be checked and applied if filters match
-- 4. Effect fields:
--    stat - stat to modify
--    base - base value of the effect (range)
--    player - player stat multipliers - statistics to check in player's data to adjust the effect
--    npc - npc stat multipliers - statistics to check in npc's data to adjust the effect
--    lockFeature - if player has this unlock, don't apply the effect
--    unlockFeature - if player doesn't have this unlock, don't apply the effect
--    temporary - if true, effect uses decay system (only disposition and alarm)
-- ============================================================================

modifiers.admireEffects = {
	success = {
		{
			stat = "disposition",
			base = {min = 2, max = 7},
			player = {
				speechcraft = 0.10,
				personality = 0.06
			},
			temporary = true
		},
		{
			stat = "disposition",
			base = {min = 1, max = 3},
			player = {
				speechcraft = 0.02,
				personality = 0.01
			},
			temporary = false,
			unlockFeature = unlocks.FEATURE.PERMANENT_EFFECTS
		},
		{
			stat = "patience",
			base = {min = -1, max = -1},
			npc = {
				hostility = -2
			}
		}
	},
	failure = {
		{
			stat = "disposition",
			base = {min = -8, max = -4},
			player = {
				speechcraft = 0.02,
				personality = 0.02
			},
			clampMax = 0,
			temporary = true
		},
		{
			stat = "patience",
			base = {min = -3, max = -3},
			npc = {
				hostility = -2
			},
			lockFeature = unlocks.FEATURE.REDUCED_PATIENCE_COST
		},
		{
			stat = "patience",
			base = {min = -2, max = -2},
			npc = {
				hostility = -2
			},
			unlockFeature = unlocks.FEATURE.REDUCED_PATIENCE_COST
		}
	}
}

modifiers.intimidateEffects = {
	success = {
		{
			stat = "alarm",
			base = {min = -18, max = -12},
			player = {
				speechcraft = -0.10,
				strength = -0.08,
				personality = -0.06
			},
			temporary = true
		},
		{
			stat = "disposition",
			base = {min = 2, max = 6},
			player = {
				speechcraft = 0.01,
				personality = 0.03
			},
			temporary = true
		},		
		{
			stat = "disposition",
			base = {min = -4, max = -1},
			player = {
				speechcraft = 0.01,
				personality = 0.02
			},
			clampMax = 0
		},
		{
			stat = "fight",
			base = {min = -7, max = -4},
			player = {
				speechcraft = -0.04,
				strength = -0.03,
				personality = -0.02
			}
		},
		{
			stat = "flee",
			base = {min = 5, max = 10},
			player = {
				speechcraft = 0.05,
				strength = 0.04,
				personality = 0.03
			}
		},
		{
			stat = "patience",
			base = {min = -1, max = -1},
			npc = {
				hostility = -2
			}
		}
	},
	failure = {
		{
			stat = "disposition",
			base = {min = -6, max = -2},
			player = {
				speechcraft = 0.03,
				personality = 0.01
			},
			clampMax = 0
		},
		{
			stat = "alarm",
			base = {min = 5, max = 10},
			player = {
				speechcraft = -0.05,
			},
			temporary = true
		},
		{
			stat = "patience",
			base = {min = -3, max = -3},
			npc = {
				hostility = -2
			},
			lockFeature = unlocks.FEATURE.REDUCED_PATIENCE_COST
		},
		{
			stat = "patience",
			base = {min = -2, max = -2},
			npc = {
				hostility = -2
			},
			unlockFeature = unlocks.FEATURE.REDUCED_PATIENCE_COST
		}
	}
}

modifiers.tauntEffects = {
	success = {
		{
			stat = "fight",
			base = {min = 12, max = 18},
			player = {
				speechcraft = 0.10,
				personality = 0.06
			}
		},
		{
			stat = "flee",
			base = {min = -6, max = -3},
			player = {
				speechcraft = -0.04,
				personality = -0.03
			}
		},
		{
			stat = "patience",
			base = {min = -1, max = -1},
			npc = {
				hostility = -2
			}
		}
	},
	failure = {
		{
			stat = "disposition",
			base = {min = -12, max = -6},
			player = {
				speechcraft = 0.02,
				personality = 0.02
			},
			clampMax = 0,
			temporary = true
		},
		{
			stat = "disposition",
			base = {min = -5, max = -3},
			player = {
				speechcraft = 0.02,
				personality = 0.02
			},
			clampMax = 0,
		},
		{
			stat = "patience",
			base = {min = -4, max = -4},
			npc = {
				hostility = -2
			},
			lockFeature = unlocks.FEATURE.REDUCED_PATIENCE_COST
		},
		{
			stat = "patience",
			base = {min = -3, max = -3},
			npc = {
				hostility = -2
			},
			unlockFeature = unlocks.FEATURE.REDUCED_PATIENCE_COST
		}
	}
}

modifiers.placateEffects = {
	success = {
		{
			stat = "fight",
			base = {min = -18, max = -12},
			player = {
				speechcraft = -0.10,
				personality = -0.06
			}
		},
		{
			stat = "patience",
			base = {min = -1, max = -1},
			npc = {
				hostility = -2
			}
		}
	},
	failure = {
		{
			stat = "disposition",
			base = {min = -6, max = -3},
			player = {
				speechcraft = 0.02,
				personality = 0.02
			},
			clampMax = 0,
			temporary = true
		},
		{
			stat = "patience",
			base = {min = -4, max = -4},
			npc = {
				hostility = -2
			},
			lockFeature = unlocks.FEATURE.REDUCED_PATIENCE_COST
		},
		{
			stat = "patience",
			base = {min = -3, max = -3},
			npc = {
				hostility = -2
			},
			unlockFeature = unlocks.FEATURE.REDUCED_PATIENCE_COST
		}
	}
}

modifiers.bribeEffects = {
	success = {
		{
			stat = "disposition",
			amountMultiplier = 1.2,
			base = {min = 0, max = 4},
			player = {
				mercantile = 0.12,
				speechcraft = 0.06
			},
			temporary = true
		},
		{
			stat = "disposition",
			amountMultiplier = 0.3,
			base = {min = 0, max = 2},
			player = {
				mercantile = 0.03,
				speechcraft = 0.02
			},
			temporary = false,
			unlockFeature = unlocks.FEATURE.PERMANENT_EFFECTS
		},
		{
			stat = "alarm",
			base = {min = -5, max = -10},
			unlockFeature = unlocks.FEATURE.BRIBE_REDUCES_ALARM,
			temporary = true
		},
		{
			stat = "alarm",
			base = {min = -2, max = -5},
			unlockFeature = {unlocks.FEATURE.BRIBE_REDUCES_ALARM, unlocks.FEATURE.PERMANENT_EFFECTS},
		},
		{
			stat = "patience",
			base = {min = -1, max = -1},
			npc = {
				hostility = -2
			}
		}
	},
	failure = {
		{
			stat = "disposition",
			base = {min = -8, max = -3},
			amountMultiplier = 0.2,
			player = {
				mercantile = 0.04,
				speechcraft = 0.02
			},
			clampMax = 0,
			temporary = true
		},
		{
			stat = "patience",
			base = {min = -3, max = -3},
			npc = {
				hostility = -2
			},
			lockFeature = unlocks.FEATURE.REDUCED_PATIENCE_COST
		},
		{
			stat = "patience",
			base = {min = -2, max = -2},
			npc = {
				hostility = -2
			},
			unlockFeature = unlocks.FEATURE.REDUCED_PATIENCE_COST
		}
	}
}

modifiers.bondEffects = {
	success = {
		{
			stat = "disposition",
			base = {min = 3, max = 5},
			player = {
				speechcraft = 0.05,
				personality = 0.03
			},
			temporary = false
		},
		{
			stat = "patience",
			base = {min = -1, max = -1},
			npc = {
				hostility = -2
			}
		}
	},
	failure = {
		{
			stat = "disposition",
			base = {min = -10, max = -6},
			player = {
				speechcraft = 0.02,
				personality = 0.02
			},
			clampMax = 0,
			temporary = true
		},
		{
			stat = "disposition",
			base = {min = -3, max = -1},
			player = {
				speechcraft = 0.01,
				personality = 0.01
			},
			clampMax = 0,
			temporary = false
		},
		{
			stat = "patience",
			base = {min = -4, max = -4},
			npc = {
				hostility = -2
			},
			lockFeature = unlocks.FEATURE.REDUCED_PATIENCE_COST
		},
		{
			stat = "patience",
			base = {min = -3, max = -3},
			npc = {
				hostility = -2
			},
			unlockFeature = unlocks.FEATURE.REDUCED_PATIENCE_COST
		}
	}
}

-- ============================================================================
-- CLASS TIER MODIFIERS
-- ============================================================================

local classEasyModifier = -10
local classHardModifier = 10

modifiers.admireClassTiers = {
	easy = {
		"pauper", "slave", "commoner",
		"farmer", "herder", "miner", "laborer", "hunter",
		"barbarian"
	},

	hard = {
		"noble", "savant",
		"merchant", "trader", "pawnbroker",
		"publican", "bookseller", "apothecary", "alchemist", "enchanter",
		"priest",
		"bard", "agent",
		"mage", "sorcerer", "battlemage", "spellsword", "witchhunter",
		"guild guide", "dreamer"
	}
}

modifiers.intimidateClassTiers = {
	easy = {
		"pauper", "slave", "commoner",
		"farmer", "herder", "miner", "laborer",
		"bookseller", "alchemist", "enchanter", "apothecary",
		"publican", "merchant", "trader", "pawnbroker"
	},

	hard = {
		"warrior", "knight", "crusader", "barbarian",
		"guard", "ordinator", "buoyant armiger",
		"champion", "drillmaster", "master-at-arms",
		"enforcer", "sharpshooter",
		"assassin", "rogue", "thief", "nightblade"
	}
}

modifiers.tauntClassTiers = {
	easy = {
		"barbarian", "warrior", "enforcer",
		"assassin", "rogue", "thief"
	},

	hard = {
		"noble", "savant", "priest", "guard", "ordinator",
		"mage", "sorcerer", "battlemage", "witchhunter",
		"monk", "pilgrim",
		"healer", "wise woman"
	}
}

modifiers.bribeClassTiers = {
	easy = {
		"pauper", "slave", "commoner",
		"farmer", "herder", "miner", "laborer", "hunter",
		"publican", "pawnbroker",
		"thief", "rogue", "smuggler"
	},

	hard = {
		"noble", "savant",
		"priest", "monk", "pilgrim", "healer",
		"knight", "crusader", "champion",
		"ordinator", "buoyant armiger",
		"guild guide", "guard",
	}
}

modifiers.placateClassTiers = {
	easy = {
		"priest", "monk", "pilgrim", "healer", "wise woman",
		"mage", "sorcerer", "savant",
		"noble", "diplomat",
		"bard", "bookseller"
	},

	hard = {
		"barbarian", "warrior", "crusader",
		"enforcer", "guard", "ordinator",
		"assassin",
		"champion", "drillmaster"
	}
}

modifiers.bondClassTiers = {
	easy = {
		"commoner", "farmer", "herder", "miner", "laborer", "hunter",
		"pauper", "slave",
		"publican", "trader", "pawnbroker", "merchant",
		"smith", "clothier", "alchemist", "apothecary", "enchanter",
		"noble", "bard", "bookseller", "savant",
		"priest", "monk", "pilgrim", "healer", "wise woman"
	},

	hard = {
		"warrior", "barbarian", "crusader", "knight",
		"archer", "scout", "ranger",
		"guard", "ordinator", "buoyant armiger",
		"enforcer", "champion", "drillmaster", "master-at-arms", "sharpshooter",
		"assassin", "thief", "rogue", "acrobat", "nightblade",
		"agent", "smuggler",
		"battlemage", "spellsword", "witchhunter", "sorcerer"
	}
}

-- ============================================================================
-- FACTION MODIFIERS
-- Positive = harder, Negative = easier
-- ============================================================================

modifiers.admireFactionModifiers = {
	["Temple"] = -3,
	["Telvanni"] = 3
}

modifiers.intimidateFactionModifiers = {
	["Imperial Legion"] = 8,
	["Redoran"] = 5,
	["Fighters Guild"] = 5,
	["Morag Tong"] = 5,
	["Clan Aundae"] = 5,
	["Clan Berne"] = 5,
	["Clan Quarra"] = 5
}

modifiers.tauntFactionModifiers = {
	["Redoran"] = -3,
	["Fighters Guild"] = -5,
	["Imperial Legion"] = 8,
	["Temple"] = 5
}

modifiers.placateFactionModifiers = {
	["Temple"] = -5,
	["Mages Guild"] = -3
}

modifiers.bribeFactionModifiers = {
	["Hlaalu"] = -6,
	["Thieves Guild"] = -5,
	["Imperial Legion"] = 8,
	["Redoran"] = 5,
	["Temple"] = 5
}

modifiers.bondFactionModifiers = {
	["Temple"] = -5,
	["Mages Guild"] = -3,
	["Fighters Guild"] = 3,
	["Thieves Guild"] = 5,
	["Camonna Tong"] = 8,
	["Telvanni"] = 12
}

-- ============================================================================
-- LOOKUP FUNCTIONS
-- ============================================================================

--- Get class modifier for a given action
--- @param npcRef tes3reference
--- @param actionKey string The action key (e.g., "admire", "intimidate")
--- @return number The class modifier (-10, 0, or 10)
function modifiers.getClassModifier(npcRef, actionKey)
	if not npcRef or not npcRef.object or not npcRef.object.class then
		return 0
	end

	local className = npcRef.object.class.name
	local classLower = className:lower()
	local tiers = modifiers[actionKey .. "ClassTiers"]

	if not tiers then return 0 end

	for _, class in ipairs(tiers.easy or {}) do
		if classLower:find(class) then
			return classEasyModifier
		end
	end

	for _, class in ipairs(tiers.hard or {}) do
		if classLower:find(class) then
			return classHardModifier
		end
	end

	return 0
end

--- Get faction modifier for a given action
--- @param npcRef tes3reference
--- @param actionKey string The action key (e.g., "admire", "intimidate")
--- @return number The faction modifier
function modifiers.getFactionModifier(npcRef, actionKey)
	if not npcRef or not npcRef.object or not npcRef.object.faction then
		return 0
	end

	local factionName = npcRef.object.faction.name
	local factionTable = modifiers[actionKey .. "FactionModifiers"]

	if not factionTable then return 0 end

	return factionTable[factionName] or 0
end

--- Register a class as exempt from illegal bribe mechanics
--- @param className string The class name
function modifiers.registerBribeExemptClass(className)
	if not className then return end

	local classLower = className:lower()

	-- Check if already registered
	for _, class in ipairs(modifiers.bribeExemptions.classes) do
		if class == classLower then
			return -- Already registered
		end
	end

	table.insert(modifiers.bribeExemptions.classes, classLower)
end

--- Register a faction as exempt from illegal bribe mechanics
--- @param factionName string The faction name
function modifiers.registerBribeExemptFaction(factionName)
	if not factionName then return end

	-- Check if already registered
	for _, faction in ipairs(modifiers.bribeExemptions.factions) do
		if faction == factionName then
			return -- Already registered
		end
	end

	table.insert(modifiers.bribeExemptions.factions, factionName)
end

--- Check if an NPC is exempt from illegal bribe mechanics
--- @param npcRef tes3reference The NPC reference
--- @return boolean True if the NPC is exempt from illegal bribe mechanics
function modifiers.isBribeExempt(npcRef)
	if not npcRef or not npcRef.object then
		return false
	end

	-- Check class exemption
	if npcRef.object.class then
		local className = npcRef.object.class.name
		local classLower = className:lower()

		for _, exemptClass in ipairs(modifiers.bribeExemptions.classes) do
			if classLower == exemptClass then
				return true
			end
		end
	end

	-- Check faction exemption
	if npcRef.object.faction then
		local factionName = npcRef.object.faction.name

		for _, exemptFaction in ipairs(modifiers.bribeExemptions.factions) do
			if factionName == exemptFaction then
				return true
			end
		end
	end

	return false
end

return modifiers
